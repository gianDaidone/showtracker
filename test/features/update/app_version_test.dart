import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/update/data/app_version.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('accetta prefisso v, build e pre-release', () {
      expect(AppVersion.tryParse('v1.0.1'), const AppVersion(1, 0, 1));
      expect(AppVersion.tryParse('V2.0.0-beta'), const AppVersion(2, 0, 0));
      expect(AppVersion.tryParse('1.0.0+5'), const AppVersion(1, 0, 0));
      expect(AppVersion.tryParse(' v3.4.5+12 '), const AppVersion(3, 4, 5));
    });

    test('completa le parti mancanti con 0', () {
      expect(AppVersion.tryParse('1.2'), const AppVersion(1, 2, 0));
      expect(AppVersion.tryParse('v7'), const AppVersion(7, 0, 0));
    });

    test('rifiuta stringhe non numeriche', () {
      expect(AppVersion.tryParse('abc'), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('v'), isNull);
      expect(AppVersion.tryParse('1.x.0'), isNull);
      expect(AppVersion.tryParse('1.0.0.1'), isNull);
      expect(AppVersion.tryParse('release-1'), isNull);
    });
  });

  group('confronto', () {
    AppVersion v(String s) => AppVersion.tryParse(s)!;

    test('numerico, non lessicografico', () {
      expect(v('1.0.10') > v('1.0.9'), isTrue);
      expect(v('1.10.0') > v('1.9.9'), isTrue);
      expect(v('v1.1.0') > v('1.0.9'), isTrue);
      expect(v('2.0.0') > v('1.99.99'), isTrue);
    });

    test('il numero di build non conta', () {
      expect(v('1.0.0') == v('1.0.0+7'), isTrue);
      expect(v('1.0.0+7') > v('1.0.0+1'), isFalse);
    });

    test('versione più vecchia', () {
      expect(v('1.0.0') > v('1.0.1'), isFalse);
      expect(v('1.0.0') < v('1.0.1'), isTrue);
    });

    test('toString senza prefisso né build', () {
      expect(v('v1.2.3+4').toString(), '1.2.3');
    });
  });
}
