import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/auth/rawg_auth_state.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/auth/tmdb_login_attempt.dart';
import '../../../core/network/api_request.dart';
import '../../../core/widgets/secret_key_dialog.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isLoading = false;
  final _loginAttempt = TmdbLoginAttempt();
  final _authClient = http.Client();
  int _loginGeneration = 0;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleAuthRedirect(uri);
    }, onError: (Object _) {
      /* Callback non interpretabile: ignorare senza log dell'URI. */
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _loginGeneration++;
    _loginAttempt.cancel();
    _authClient.close();
    super.dispose();
  }

  Future<void> _startLoginFlow() async {
    if (_isLoading) return;
    final generation = ++_loginGeneration;
    _loginAttempt.cancel();
    setState(() => _isLoading = true);
    try {
      final requestToken = await _createRequestToken();
      if (!mounted || generation != _loginGeneration) return;
      _loginAttempt.begin(requestToken);
      final authUrl = Uri.parse(
          'https://www.themoviedb.org/authenticate/$requestToken?redirect_to=showtracker://auth');

      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch browser');
      }
    } catch (_) {
      _loginAttempt.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Accesso non riuscito. Controlla la connessione e la configurazione TMDB.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _createRequestToken() async {
    final url = Uri.parse(
        'https://api.themoviedb.org/3/authentication/token/new?api_key=${ApiKeys.tmdb}');
    final response = await apiRequest(_authClient, 'GET', url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['request_token'];
      if (token is! String || token.isEmpty) {
        throw const FormatException('Token non valido.');
      }
      return token;
    } else {
      if (response.statusCode == 401) {
        throw Exception(
            'Chiave TMDB mancante o non valida. Compila con --dart-define=TMDB_KEY=la_tua_chiave');
      }
      throw Exception('Failed to create request token: ${response.statusCode}');
    }
  }

  Future<void> _handleAuthRedirect(Uri uri) async {
    final requestToken = _loginAttempt.consume(uri);
    if (!mounted || requestToken == null) return;
    final generation = _loginGeneration;
    setState(() => _isLoading = true);
    try {
      final sessionUrl = Uri.parse(
          'https://api.themoviedb.org/3/authentication/session/new?api_key=${ApiKeys.tmdb}');
      final response = await apiRequest(
        _authClient,
        'POST',
        sessionUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'request_token': requestToken}),
      );

      if (!mounted || generation != _loginGeneration) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['session_id'];
        if (sessionId is! String || sessionId.isEmpty) {
          throw const FormatException('Sessione non valida.');
        }
        await ref
            .read(authControllerProvider.notifier)
            .loginWithSession(sessionId);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autenticazione fallita.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Autenticazione non riuscita. Riprova.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCustomKeyDialog() => showDialog<void>(
        context: context,
        builder: (_) => SecretKeyDialog(
          title: 'Inserisci API Key v3',
          onSave: (key) {
            _loginGeneration++;
            _loginAttempt.cancel();
            return ref
                .read(authControllerProvider.notifier)
                .loginWithManualKey(key);
          },
        ),
      );

  Future<void> _showRawgKeyDialog() => showDialog<void>(
        context: context,
        builder: (_) => SecretKeyDialog(
          title: 'Inserisci RAWG API Key',
          description:
              'La chiave RAWG è facoltativa e abilita il catalogo videogiochi.',
          onSave: (key) =>
              ref.read(rawgAuthControllerProvider.notifier).loginWithKey(key),
          help: TextButton.icon(
            onPressed: () => launchUrl(Uri.parse('https://rawg.io/apidocs'),
                mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Documentazione RAWG'),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(48),
                          child: Image.asset(
                            'assets/images/logo.webp',
                            width: 240,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'ShowTracker',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'La tua libreria offline, senza limiti.\nI tuoi progressi restano solo sul tuo dispositivo.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withAlpha(40),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed: _startLoginFlow,
                          icon: const Icon(Icons.login),
                          label: const Text(
                            'Connetti account TMDB',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _showCustomKeyDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Opzioni avanzate (API Key manuale)'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.divider, width: 1.5),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: _showRawgKeyDialog,
                          icon: const Icon(Icons.videogame_asset,
                              color: AppColors.textPrimary),
                          label: const Text(
                            'Attiva Modulo Videogiochi',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
