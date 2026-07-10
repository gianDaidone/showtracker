import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/constants.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleAuthRedirect(uri);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLoginFlow() async {
    setState(() => _isLoading = true);
    try {
      final requestToken = await _createRequestToken();
      final authUrl = Uri.parse('https://www.themoviedb.org/authenticate/$requestToken?redirect_to=showtracker://auth');
      
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch browser');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore di connessione: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _createRequestToken() async {
    final url = Uri.parse('https://api.themoviedb.org/3/authentication/token/new?api_key=$kTmdbApiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['request_token'];
    } else {
      if (response.statusCode == 401) {
        throw Exception('Non autorizzato. Hai inserito la tua API Key TMDB in constants.dart?');
      }
      throw Exception('Failed to create request token: ${response.statusCode}');
    }
  }

  Future<void> _handleAuthRedirect(Uri uri) async {
    if (uri.scheme == 'showtracker' && uri.host == 'auth') {
      final requestToken = uri.queryParameters['request_token'];
      final approved = uri.queryParameters['approved'];

      if (approved == 'true' && requestToken != null) {
        setState(() => _isLoading = true);
        try {
          final sessionUrl = Uri.parse('https://api.themoviedb.org/3/authentication/session/new?api_key=$kTmdbApiKey');
          final response = await http.post(
            sessionUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'request_token': requestToken}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final sessionId = data['session_id'];
            await ref.read(authControllerProvider.notifier).loginWithSession(sessionId);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Autenticazione fallita.')),
              );
            }
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    }
  }

  void _showCustomKeyDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Inserisci API Key v3'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'La tua TMDB API Key',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final key = controller.text.trim();
                if (key.isNotEmpty) {
                  ref.read(authControllerProvider.notifier).loginWithManualKey(key);
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva e Inizia'),
            ),
          ],
        );
      },
    );
  }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            ],
          ),
        ),
      ),
    );
  }
}
