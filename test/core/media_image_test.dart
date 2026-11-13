import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_image/octo_image.dart';
import 'package:showtracker/core/widgets/media_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaImageBudget', () {
    for (final dpr in [1.0, 2.0, 3.0]) {
      for (final source in [
        (name: 'poster', width: 800, height: 1200),
        (name: 'still', width: 1920, height: 1080),
        (name: 'RAWG non standard', width: 1600, height: 400),
      ]) {
        test('${source.name}: cover DPR$dpr preserves ratio and crop pixels',
            () {
          // A landscape image in a narrow card needs considerably more width
          // than the visible box; a bounding-box resize would underdecode it.
          final budget = MediaImageBudget.fromSize(const Size(96, 80), dpr);
          final target = budget.targetSize(
            source.width,
            source.height,
            BoxFit.cover,
          );
          expect(target.width == null || target.height == null, isTrue);
          final decoded = _decodedSize(target, source.width, source.height);
          expect(decoded.width, greaterThanOrEqualTo(96 * dpr));
          expect(decoded.height, greaterThanOrEqualTo(80 * dpr));
          expect(decoded.width, lessThanOrEqualTo(source.width));
          expect(decoded.height, lessThanOrEqualTo(source.height));
          expect(decoded.aspectRatio,
              closeTo(source.width / source.height, 0.001));
        });
      }

      test('contain DPR$dpr does not pay for cropped pixels', () {
        final budget = MediaImageBudget.fromSize(const Size(200, 120), dpr);
        final target = budget.targetSize(1600, 400, BoxFit.contain);
        final size = _decodedSize(target, 1600, 400);
        expect(size.width, lessThanOrEqualTo(budget.width + 1));
        expect(size.height, lessThanOrEqualTo(budget.height + 1));
      });
    }

    test('nearby layouts reuse physical-pixel buckets', () {
      final first = MediaImageBudget.fromSize(const Size(46, 68), 3);
      final nearby = MediaImageBudget.fromSize(const Size(47, 69), 3);
      expect(first, nearby);
      expect(first.hashCode, nearby.hashCode);
      expect(first.width, 160);
      expect(first.height, 224);
      expect(MediaImageBudget.fromSize(const Size(60, 90), 3), isNot(first));
    });

    test('never upscales intrinsically small images', () {
      const budget = MediaImageBudget(900, 600);
      final target = budget.targetSize(90, 60, BoxFit.cover);
      expect(target.width, isNull);
      expect(target.height, isNull);
    });

    test('TMDB variants cover both axes, including poster fallbacks', () {
      const budget = MediaImageBudget(96, 320);
      expect(
        budget.imageUrl('https://image.tmdb.org/t/p/w500/poster.jpg',
            MediaImageSource.tmdbPoster, BoxFit.cover),
        'https://image.tmdb.org/t/p/w342/poster.jpg',
      );
      expect(
        budget.imageUrl('https://image.tmdb.org/t/p/w185/still.jpg',
            MediaImageSource.tmdbStill, BoxFit.cover),
        'https://image.tmdb.org/t/p/original/still.jpg',
      );
      expect(
        budget.imageUrl('https://image.tmdb.org/t/p/w780/backdrop.jpg',
            MediaImageSource.tmdbBackdrop, BoxFit.cover),
        'https://image.tmdb.org/t/p/w780/backdrop.jpg',
      );
    });

    test(
        'equal decode configurations preserve provider and synchronous key identity',
        () {
      const url = 'https://image.tmdb.org/t/p/w185/equal.jpg';
      const first = MediaImageProvider(CachedNetworkImageProvider(url),
          budget: MediaImageBudget(160, 240), fit: BoxFit.cover);
      const second = MediaImageProvider(CachedNetworkImageProvider(url),
          budget: MediaImageBudget(160, 240), fit: BoxFit.cover);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      var completed = false;
      first.obtainKey(ImageConfiguration.empty).then((_) {
        completed = true;
      });
      expect(completed, isTrue,
          reason: 'A synchronous source key must not become asynchronous');
      expect(
          const MediaImageProvider(CachedNetworkImageProvider(url),
              budget: MediaImageBudget(192, 240), fit: BoxFit.cover),
          isNot(first));
      expect(
          const MediaImageProvider(CachedNetworkImageProvider(url),
              budget: MediaImageBudget(160, 240), fit: BoxFit.contain),
          isNot(first));
    });

    test('variant URLs share cache keys across nearby layouts', () async {
      const original = 'https://image.tmdb.org/t/p/w342/poster.jpg';
      final first = MediaImageBudget.fromSize(const Size(46, 68), 3);
      final nearby = MediaImageBudget.fromSize(const Size(47, 69), 3);
      MediaImageProvider provider(MediaImageBudget budget) =>
          MediaImageProvider(
            CachedNetworkImageProvider(budget.imageUrl(
                original, MediaImageSource.tmdbPoster, BoxFit.cover)),
            budget: budget,
            fit: BoxFit.cover,
          );
      final firstKey =
          await provider(first).obtainKey(ImageConfiguration.empty);
      final nearbyKey =
          await provider(nearby).obtainKey(ImageConfiguration.empty);
      expect(firstKey, nearbyKey);
      expect(firstKey.hashCode, nearbyKey.hashCode);
      expect(
        await MediaImageProvider(
          CachedNetworkImageProvider(first.imageUrl(
              original, MediaImageSource.tmdbPoster, BoxFit.cover)),
          budget: first,
          fit: BoxFit.contain,
        ).obtainKey(ImageConfiguration.empty),
        isNot(firstKey),
      );
    });

    test('only known TMDB host/path variants are rewritten', () {
      const budget = MediaImageBudget(160, 240);
      for (final url in [
        'https://media.rawg.io/media/games/cover.jpg?width=1920',
        'https://example.com/t/p/w342/poster.jpg',
        'https://image.tmdb.org.evil.test/t/p/w342/poster.jpg',
        'https://image.tmdb.org/other/w342/poster.jpg',
        'https://image.tmdb.org/t/p/w342/folder/poster.jpg',
        'https://image.tmdb.org/t/p/not-a-variant/poster.jpg',
      ]) {
        expect(budget.imageUrl(url, MediaImageSource.tmdbPoster, BoxFit.cover),
            url);
      }
      const generic = 'https://image.tmdb.org/t/p/w342/poster.jpg';
      expect(budget.imageUrl(generic, MediaImageSource.generic, BoxFit.cover),
          generic);
      expect(
        budget.imageUrl('https://image.tmdb.org/t/p/w342/poster.jpg?x=1#image',
            MediaImageSource.tmdbPoster, BoxFit.cover),
        'https://image.tmdb.org/t/p/w185/poster.jpg?x=1#image',
      );
    });
  });

  testWidgets('real codec preserves intrinsic aspect and bounds decoded pixels',
      (tester) async {
    await tester.runAsync(() async {
      // Local generated PNG fixtures: no HTTP, credentials, plugins or assets.
      for (final size in [const Size(600, 900), const Size(1200, 300)]) {
        final bytes = await _png(size.width.toInt(), size.height.toInt());
        for (final dpr in [1.0, 2.0, 3.0]) {
          final budget = MediaImageBudget.fromSize(const Size(96, 80), dpr);
          final provider = MediaImageProvider(
            MemoryImage(bytes),
            budget: budget,
            fit: BoxFit.cover,
          );
          final info = await _load(provider);
          try {
            expect(info.image.width, greaterThanOrEqualTo(96 * dpr));
            expect(info.image.height, greaterThanOrEqualTo(80 * dpr));
            expect(info.image.width / info.image.height,
                closeTo(size.aspectRatio, 0.02));
            expect(info.image.width * info.image.height,
                lessThan(size.width * size.height));
          } finally {
            info.dispose();
            await provider.evict();
          }
        }
      }
    });
  });

  testWidgets('responsive header passes bounded provider to imageBuilder',
      (tester) async {
    final fixture = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(await _png(16, 9));
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });
    final image = fixture!;
    addTearDown(image.dispose);
    const url = 'https://image.tmdb.org/t/p/w780/backdrop.jpg';
    ImageProvider? delivered;
    Future<void> render(Size size, double dpr) async {
      final budget = MediaImageBudget.fromSize(size, dpr);
      final provider = MediaImageProvider(
        CachedNetworkImageProvider(
            budget.imageUrl(url, MediaImageSource.tmdbBackdrop, BoxFit.cover)),
        budget: budget,
        fit: BoxFit.cover,
      );
      final key = await provider.obtainKey(ImageConfiguration.empty);
      PaintingBinding.instance.imageCache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: image.clone()))),
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(devicePixelRatio: dpr),
          child: Center(
            child: SizedBox.fromSize(
              size: size,
              child: MediaImage(
                imageUrl: url,
                source: MediaImageSource.tmdbBackdrop,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Colors.black),
                imageBuilder: (_, bounded) {
                  delivered = bounded;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: bounded, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final octo = tester.widget<OctoImage>(find.byType(OctoImage));
      expect(octo.fit, BoxFit.cover);
      expect(octo.placeholderBuilder, isNotNull);
      expect(delivered, same(octo.image));
      expect((delivered! as MediaImageProvider).budget, budget);
      expect(tester.getSize(find.byType(MediaImage)), size);
      await tester.pumpWidget(const SizedBox.shrink());
      await provider.evict();
    }

    await render(const Size(300, 210), 1);
    await render(const Size(500, 210), 3);
  });

  testWidgets(
      'same cached image preserves its Image state across parent rebuilds',
      (tester) async {
    final fixture = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(await _png(160, 240));
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });
    final image = fixture!;
    addTearDown(image.dispose);
    const url = 'https://image.tmdb.org/t/p/w185/stable.jpg';
    final budget = MediaImageBudget.fromSize(const Size(60, 90), 1);
    final provider = MediaImageProvider(
      CachedNetworkImageProvider(
          budget.imageUrl(url, MediaImageSource.tmdbPoster, BoxFit.cover)),
      budget: budget,
      fit: BoxFit.cover,
    );
    final key = await provider.obtainKey(ImageConfiguration.empty);
    PaintingBinding.instance.imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
          Future.value(ImageInfo(image: image.clone()))),
    );
    var placeholders = 0;
    Widget render() => Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 1),
            child: Center(
                child: SizedBox(
              width: 60,
              height: 90,
              child: MediaImage(
                imageUrl: url,
                source: MediaImageSource.tmdbPoster,
                fit: BoxFit.cover,
                placeholder: (_, __) {
                  placeholders++;
                  return const Text('Placeholder stable image');
                },
              ),
            )),
          ),
        );
    await tester.pumpWidget(render());
    await tester.pumpAndSettle();
    final before = tester.state(find.byType(Image));
    final placeholderCount = placeholders;
    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(render());
      expect(tester.state(find.byType(Image)), same(before),
          reason: 'Unchanged image must not remount after a parent rebuild');
      expect(placeholders, placeholderCount,
          reason: 'Unchanged cached image must not flash its placeholder');
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await provider.evict();
  });

  testWidgets('placeholder and error builders retain original URL',
      (tester) async {
    const url = 'https://image.tmdb.org/t/p/w342/poster.jpg';
    const budget = MediaImageBudget(64, 96);
    final provider = MediaImageProvider(
      CachedNetworkImageProvider(
          budget.imageUrl(url, MediaImageSource.tmdbPoster, BoxFit.cover)),
      budget: budget,
      fit: BoxFit.cover,
    );
    final key = await provider.obtainKey(ImageConfiguration.empty);
    final pending = Completer<ImageInfo>();
    PaintingBinding.instance.imageCache
        .putIfAbsent(key, () => OneFrameImageStreamCompleter(pending.future));
    String? placeholderUrl;
    String? errorUrl;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1),
        child: Center(
          child: SizedBox(
            width: 60,
            height: 90,
            child: MediaImage(
              imageUrl: url,
              source: MediaImageSource.tmdbPoster,
              fit: BoxFit.cover,
              placeholder: (_, requested) {
                placeholderUrl = requested;
                return const Text('Caricamento');
              },
              errorWidget: (_, requested, error) {
                errorUrl = requested;
                return const Text('Non disponibile');
              },
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Caricamento'), findsOneWidget);
    expect(placeholderUrl, url);
    pending.completeError(StateError('local fixture failure'));
    await tester.pumpAndSettle();
    expect(find.text('Non disponibile'), findsOneWidget);
    expect(errorUrl, url);
    await tester.pumpWidget(const SizedBox.shrink());
    await provider.evict();
  });
}

Size _decodedSize(ui.TargetImageSize target, int width, int height) {
  if (target.width != null) {
    return Size(target.width!.toDouble(), target.width! * height / width);
  }
  if (target.height != null) {
    return Size(target.height! * width / height, target.height!.toDouble());
  }
  return Size(width.toDouble(), height.toDouble());
}

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = Colors.orange);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<ImageInfo> _load(ImageProvider provider) async {
  final completer = Completer<ImageInfo>();
  final stream = provider.resolve(ImageConfiguration.empty);
  final listener = ImageStreamListener((image, synchronous) {
    completer.complete(image);
  }, onError: (Object error, StackTrace? trace) {
    completer.completeError(error, trace);
  });
  stream.addListener(listener);
  try {
    return await completer.future;
  } finally {
    stream.removeListener(listener);
  }
}
