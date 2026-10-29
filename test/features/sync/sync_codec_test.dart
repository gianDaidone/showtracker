import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/sync/domain/models/sync_payload.dart';
import 'package:showtracker/features/sync/utils/sync_compressor.dart';

void main() {
  group('RangeUtils', () {
    test('compatta una copia ordinata senza modificare la lista originale', () {
      final episodes = [8, 2, 1, 3, 6, 7, 10];
      expect(RangeUtils.compactListToRange(episodes), '1-3,6-8,10');
      expect(episodes, [8, 2, 1, 3, 6, 7, 10]);
      expect(RangeUtils.compactListToRange([]), '');
      expect(RangeUtils.compactListToRange([1]), '1');
    });

    test('espande estremi inclusivi e ignora frammenti non validi', () {
      expect(RangeUtils.expandRangeToList('1-3,5,8-9'), [1, 2, 3, 5, 8, 9]);
      expect(RangeUtils.expandRangeToList('  '), isEmpty);
      expect(RangeUtils.expandRangeToList('x,4-2,1-2-3,7,9-a'), [7]);
    });

    test('round-trip di insiemi di episodi sparsi e consecutivi', () {
      for (final episodes in [
        <int>[],
        [1],
        [1, 2, 3, 4, 5],
        [1, 3, 5, 7, 9],
        [99, 100, 101, 104],
      ]) {
        expect(
          RangeUtils.expandRangeToList(RangeUtils.compactListToRange(episodes)),
          episodes,
        );
      }
    });
  });

  group('SyncPayload e SyncCompressor', () {
    test('round-trip JSON compresso con tutti i domini e caratteri Unicode',
        () {
      final payload = SyncPayload(
        shows: {
          '101': ShowSyncData(
            status: 'watching',
            updatedAt: 1790000000,
            eps: {'1': '1-3,5', '2': '1'},
          ),
        },
        games: {
          '202': GameSyncData(status: 'completed', updatedAt: 1790000001)
        },
        movies: {
          '303': MovieSyncData(status: 'planToWatch', updatedAt: 1790000002)
        },
      );
      final json = payload.toJson();
      final compressed = SyncCompressor.compressPayload(json);
      final restored =
          SyncPayload.fromJson(SyncCompressor.decompressPayload(compressed));
      expect(restored.toJson(), json);
      expect(restored.shows['101']!.eps, {'1': '1-3,5', '2': '1'});
      expect(restored.games['202']!.updatedAt, 1790000001);
      expect(restored.movies['303']!.status, 'planToWatch');
      final unicode = {'note': 'Perché già visto 日本語'};
      expect(
          SyncCompressor.decompressPayload(
              SyncCompressor.compressPayload(unicode)),
          unicode);
    });

    test('payload vecchi senza domini o episodi opzionali restano leggibili',
        () {
      expect(SyncPayload.fromJson({}).toJson(), isEmpty);
      final payload = SyncPayload.fromJson({
        's': {
          '1': {'st': 'watching', 'u': 100}
        },
        'g': {
          '2': {'st': 'completed', 'u': 200}
        },
      });
      expect(payload.movies, isEmpty);
      expect(payload.shows['1']!.eps, isEmpty);
      expect(payload.toJson(), {
        's': {
          '1': {'st': 'watching', 'u': 100}
        },
        'g': {
          '2': {'st': 'completed', 'u': 200}
        },
      });
    });

    test('tipi o campi obbligatori corrotti non diventano payload vuoti', () {
      for (final json in <Map<String, dynamic>>[
        {'s': []},
        {
          's': {
            '1': {'u': 1}
          }
        },
        {
          'g': {
            '1': {'st': 'watching', 'u': 'ieri'}
          }
        },
        {
          'm': {
            '1': {'st': 1, 'u': 1}
          }
        },
        {
          's': {
            '1': {
              'st': 'watching',
              'u': 1,
              'e': {'1': 12}
            }
          }
        },
      ]) {
        expect(() => SyncPayload.fromJson(json), throwsA(isA<TypeError>()));
      }
    });

    test('base64, zlib, UTF-8 e JSON corrotti danno FormatException', () {
      final corrupt = [
        '%%%not-base64',
        base64Encode([1, 2, 3]),
        base64Encode(zlib.encode([0xff])),
        base64Encode(zlib.encode(utf8.encode('{broken'))),
        base64Encode(zlib.encode(utf8.encode('[]'))),
        base64Encode(zlib.encode(utf8.encode('null'))),
      ];
      for (final value in corrupt) {
        expect(() => SyncCompressor.decompressPayload(value),
            throwsFormatException);
      }
    });
  });
}
