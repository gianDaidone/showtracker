import 'dart:async';
import 'dart:io';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/sync/services/local_sync_server.dart';

class _Server implements HttpServer {
  bool closed = false;
  @override
  int get port => 8080;
  @override
  Duration? idleTimeout;
  @override
  Future<void> close({bool force = false}) async {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('stop durante risoluzione IP non apre un socket tardivo', () async {
    final ip = Completer<String?>();
    var bindings = 0;
    final server = LocalSyncServer(
        resolveAddress: () => ip.future,
        bind: (_, __, ___) async {
          bindings++;
          return _Server();
        });
    final pending = server.start('eJw=');
    await Future<void>.value();
    await server.stop();
    ip.complete('192.168.1.2');
    expect(await pending, isNull);
    expect(bindings, 0);
    expect(server.isRunning, isFalse);
  });
  test('stop durante bind chiude il server che si completa in ritardo',
      () async {
    final bound = Completer<HttpServer>();
    final binding = Completer<void>();
    final socket = _Server();
    final server = LocalSyncServer(
        resolveAddress: () async => '192.168.1.2',
        bind: (_, address, port) {
          expect(address.address, '192.168.1.2');
          expect(port, 8080);
          binding.complete();
          return bound.future;
        });
    final pending = server.start('eJw=');
    await binding.future;
    await server.stop();
    bound.complete(socket);
    expect(await pending, isNull);
    expect(socket.closed, isTrue);
  });
  test('sessione chiusa automaticamente dopo cinque minuti', () {
    fakeAsync((clock) {
      final socket = _Server();
      var expired = 0;
      final server = LocalSyncServer(
          resolveAddress: () async => '192.168.1.2',
          bind: (_, __, ___) async => socket,
          onExpired: () => expired++);
      server.start('eJw=');
      clock.flushMicrotasks();
      expect(server.isRunning, isTrue);
      clock.elapse(const Duration(minutes: 5));
      clock.flushMicrotasks();
      expect(socket.closed, isTrue);
      expect(server.isRunning, isFalse);
      expect(expired, 1);
    });
  });
}
