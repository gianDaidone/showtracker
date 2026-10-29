import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/features/update/data/app_version.dart';
import 'package:showtracker/features/update/data/github_release_service.dart';
import 'package:showtracker/features/update/data/update_exception.dart';

Map<String, dynamic> _release({
  String tag = 'v1.0.1',
  String? body = 'Correzioni varie',
  List<Map<String, dynamic>>? assets,
}) =>
    {
      'tag_name': tag,
      'body': body,
      'assets': assets ??
          [
            {
              'name': 'checksums.txt',
              'browser_download_url': 'https://example.com/checksums.txt',
            },
            {
              'name': 'app-release.APK',
              'browser_download_url': 'https://example.com/app-release.apk',
            },
          ],
    };

GithubReleaseService _service(MockClientHandler handler) {
  final client = MockClient(handler);
  addTearDown(client.close);
  return GithubReleaseService(client, repo: 'owner/repo');
}

void main() {
  test('timeout a 15 secondi simulati diventa UpdateNoConnection', () {
    fakeAsync((async) {
      final pending = Completer<http.Response>();
      final client = MockClient((_) => pending.future);
      addTearDown(client.close);
      Object? error;
      var completed = false;
      GithubReleaseService(client).fetchLatest().then<void>(
        (_) => completed = true,
        onError: (Object e, StackTrace _) {
          error = e;
          completed = true;
        },
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 14));
      expect(completed, isFalse);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(completed, isTrue);
      expect(error, isA<UpdateNoConnection>());
      pending.complete(http.Response(jsonEncode(_release()), 200));
      async.flushMicrotasks();
      expect(error, isA<UpdateNoConnection>());
    });
  });

  test('429 con reset valido mantiene il timestamp; reset anomalo resta null',
      () async {
    for (final reset in ['1790856000', 'not-a-date']) {
      final service = _service((_) async =>
          http.Response('{}', 429, headers: {'x-ratelimit-reset': reset}));
      await expectLater(
          service.fetchLatest(),
          throwsA(isA<UpdateRateLimited>().having(
            (e) => e.resetAt,
            'resetAt',
            reset == '1790856000'
                ? DateTime.fromMillisecondsSinceEpoch(1790856000000)
                : isNull,
          )));
    }
  });

  test('risposte JSON non oggetto sono UpdateInvalidResponse', () async {
    for (final body in ['[]', 'null', '42', '"release"']) {
      final service = _service((_) async => http.Response(body, 200));
      await expectLater(
          service.fetchLatest(), throwsA(isA<UpdateInvalidResponse>()));
    }
  });

  test(
      'asset anomali ignorati, primo APK valido selezionato e note normalizzate',
      () {
    final release = GithubReleaseService.parseRelease(jsonEncode({
      'tag_name': 'v1.2.3',
      'body': '  Note aggiornamento  ',
      'assets': [
        null,
        4,
        {'name': 'bad.apk', 'browser_download_url': null},
        {'name': 'empty.apk', 'browser_download_url': ''},
        {
          'name': 'first.APK',
          'browser_download_url': 'https://example.com/first.apk'
        },
        {
          'name': 'second.apk',
          'browser_download_url': 'https://example.com/second.apk'
        },
      ],
    }));
    expect(release.apkName, 'first.APK');
    expect(release.apkUrl, 'https://example.com/first.apk');
    expect(release.notes, 'Note aggiornamento');
  });

  test('assets null o di tipo inatteso producono UpdateNoApk', () {
    for (final assets in [null, 'not-a-list', <Object>[]]) {
      expect(
          () => GithubReleaseService.parseRelease(
              jsonEncode({'tag_name': 'v1.0.0', 'assets': assets})),
          throwsA(isA<UpdateNoApk>()));
    }
  });

  test('legge versione, note e URL dell\'APK', () async {
    late http.Request captured;
    final service = _service((request) async {
      captured = request;
      return http.Response(jsonEncode(_release()), 200);
    });

    final release = await service.fetchLatest();

    expect(captured.url.toString(),
        'https://api.github.com/repos/owner/repo/releases/latest');
    expect(captured.headers['Accept'], 'application/vnd.github+json');
    expect(captured.headers['X-GitHub-Api-Version'], '2022-11-28');
    expect(captured.headers['User-Agent'], 'ShowTracker');
    expect(captured.headers.containsKey('authorization'), isFalse);
    expect(captured.url.queryParameters, isEmpty);
    expect(release.version, const AppVersion(1, 0, 1));
    expect(release.tagName, 'v1.0.1');
    expect(release.apkUrl, 'https://example.com/app-release.apk');
    expect(release.apkName, 'app-release.APK');
    expect(release.notes, 'Correzioni varie');
  });

  test('note vuote → null', () async {
    final service = _service(
        (_) async => http.Response(jsonEncode(_release(body: '  \n')), 200));
    expect((await service.fetchLatest()).notes, isNull);
  });

  test('nessun asset .apk → UpdateNoApk', () async {
    final service = _service((_) async => http.Response(
          jsonEncode(_release(assets: [
            {
              'name': 'source.zip',
              'browser_download_url': 'https://example.com/s.zip'
            },
          ])),
          200,
        ));
    await expectLater(
      service.fetchLatest(),
      throwsA(isA<UpdateNoApk>()
          .having((e) => e.message, 'message', contains('v1.0.1'))),
    );
  });

  test('403 con rate limit esaurito → UpdateRateLimited', () async {
    final reset = DateTime.now().add(const Duration(minutes: 12));
    final service = _service((_) async => http.Response(
          '{"message":"API rate limit exceeded"}',
          403,
          headers: {
            'x-ratelimit-remaining': '0',
            'x-ratelimit-reset': '${reset.millisecondsSinceEpoch ~/ 1000}',
          },
        ));
    await expectLater(
      service.fetchLatest(),
      throwsA(isA<UpdateRateLimited>()
          .having((e) => e.resetAt, 'resetAt', isNotNull)),
    );
  });

  test('messaggio del rate limit in minuti', () {
    final now = DateTime(2026, 10, 1, 12);
    expect(
      UpdateRateLimited(
              resetAt: now.add(const Duration(minutes: 11, seconds: 30)),
              now: now)
          .message,
      'Troppe richieste a GitHub. Riprova tra 12 minuti.',
    );
    expect(const UpdateRateLimited().message,
        'Troppe richieste a GitHub. Riprova più tardi.');
  });

  test('403 non dovuto al rate limit → UpdateInvalidResponse', () async {
    final service = _service((_) async => http.Response(
          '{"message":"Forbidden"}',
          403,
          headers: {'x-ratelimit-remaining': '42'},
        ));
    await expectLater(
        service.fetchLatest(), throwsA(isA<UpdateInvalidResponse>()));
  });

  test('404 → UpdateNoReleases', () async {
    final service =
        _service((_) async => http.Response('{"message":"Not Found"}', 404));
    await expectLater(service.fetchLatest(), throwsA(isA<UpdateNoReleases>()));
  });

  test('500 → UpdateInvalidResponse con il codice HTTP', () async {
    final service = _service((_) async => http.Response('oops', 500));
    await expectLater(
      service.fetchLatest(),
      throwsA(isA<UpdateInvalidResponse>()
          .having((e) => e.message, 'message', contains('HTTP 500'))),
    );
  });

  test('JSON non valido → UpdateInvalidResponse', () async {
    final service = _service((_) async => http.Response('<html>', 200));
    await expectLater(
        service.fetchLatest(), throwsA(isA<UpdateInvalidResponse>()));
  });

  test('tag_name mancante o non semantico → UpdateInvalidResponse', () async {
    for (final json in [
      <String, dynamic>{'assets': []},
      _release(tag: 'latest'),
      <String, dynamic>{'tag_name': 3},
    ]) {
      final service =
          _service((_) async => http.Response(jsonEncode(json), 200));
      await expectLater(
          service.fetchLatest(), throwsA(isA<UpdateInvalidResponse>()));
    }
  });

  test('errori di rete → UpdateNoConnection', () async {
    for (final error in <Object>[
      const SocketException('Failed host lookup'),
      http.ClientException('Connection closed'),
      const HandshakeException('bad cert'),
    ]) {
      final service = _service((_) async => throw error);
      await expectLater(
          service.fetchLatest(), throwsA(isA<UpdateNoConnection>()));
    }
  });
}
