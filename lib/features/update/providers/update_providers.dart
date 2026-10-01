import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/github_release_service.dart';

part 'update_providers.g.dart';

// ── GitHub Releases ───────────────────────────────────────────────────────────

// keepAlive: viene solo letto (`ref.read`) al tocco del pulsante. Da
// autoDispose verrebbe distrutto subito dopo la lettura e `client.close`
// interromperebbe la richiesta appena partita ("Connection attempt cancelled").
@Riverpod(keepAlive: true)
GithubReleaseService githubReleaseService(GithubReleaseServiceRef ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GithubReleaseService(client);
}

// ── Versione installata ───────────────────────────────────────────────────────

@riverpod
Future<PackageInfo> packageInfo(PackageInfoRef ref) => PackageInfo.fromPlatform();
