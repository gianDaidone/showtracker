import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/auth/tmdb_login_attempt.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);
  Uri callback(String query) => Uri.parse('showtracker://auth?$query');
  test(
      'callback non sollecitati, token estranei e duplicati non creano sessioni',
      () {
    final attempt = TmdbLoginAttempt();
    expect(
        attempt.consume(callback('request_token=mine&approved=true'), now: now),
        isNull);
    attempt.begin('mine', now: now);
    for (final uri in [
      callback('request_token=other&approved=true'),
      callback('request_token=mine&request_token=other&approved=true'),
      callback('request_token=mine&approved=true&extra=1'),
      callback('request_token=mine&approved=%FF'),
      Uri.parse('https://auth?request_token=mine&approved=true'),
      Uri.parse('showtracker://user@auth?request_token=mine&approved=true'),
      Uri.parse('showtracker://auth/path?request_token=mine&approved=true'),
    ]) {
      expect(attempt.consume(uri, now: now), isNull);
    }
    final valid = callback('request_token=mine&approved=true');
    expect(attempt.consume(valid, now: now), 'mine');
    expect(attempt.consume(valid, now: now), isNull);
  });
  test(
      'scadenza, diniego, annullamento e nuovo tentativo invalidano il precedente',
      () {
    final attempt = TmdbLoginAttempt()..begin('one', now: now);
    expect(
        attempt.consume(callback('request_token=one&approved=true'),
            now: now.add(const Duration(minutes: 10))),
        isNull);
    attempt.begin('two', now: now);
    expect(
        attempt.consume(callback('request_token=one&approved=true'), now: now),
        isNull);
    expect(
        attempt.consume(callback('request_token=two&approved=false'), now: now),
        isNull);
    expect(
        attempt.consume(callback('request_token=two&approved=true'), now: now),
        isNull);
    attempt.begin('three', now: now);
    attempt.cancel();
    expect(
        attempt.consume(callback('request_token=three&approved=true'),
            now: now),
        isNull);
  });
}
