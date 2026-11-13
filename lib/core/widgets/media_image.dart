import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

/// Only TMDB has documented size variants. Generic URLs (including RAWG) are
/// never rewritten; their decode budget uses the actual encoded dimensions.
enum MediaImageSource {
  generic(null, []),
  tmdbPoster(2 / 3, [92, 154, 185, 342, 500, 780]),
  tmdbStill(16 / 9, [92, 185, 300]),
  tmdbBackdrop(16 / 9, [300, 780, 1280]);

  const MediaImageSource(this.aspectRatio, this.widths);

  final double? aspectRatio;
  final List<int> widths;
}

/// Stable physical-pixel buckets keep nearby layouts from creating separate
/// decoded cache entries. No global ImageCache or disk-cache limit is changed.
@immutable
class MediaImageBudget {
  const MediaImageBudget(this.width, this.height);

  factory MediaImageBudget.fromSize(Size logicalSize, double devicePixelRatio) {
    assert(logicalSize.isFinite && !logicalSize.isEmpty);
    assert(devicePixelRatio.isFinite && devicePixelRatio > 0);
    int bucket(double value) => (value / 32).ceil() * 32;
    return MediaImageBudget(
      bucket(logicalSize.width * devicePixelRatio),
      bucket(logicalSize.height * devicePixelRatio),
    );
  }

  final int width;
  final int height;

  /// Pick one axis only: the codec derives the other from the intrinsic ratio.
  /// Cover must retain enough pixels on BOTH axes, rather than fit inside a box.
  ui.TargetImageSize targetSize(
    int intrinsicWidth,
    int intrinsicHeight,
    BoxFit fit,
  ) {
    final widthScale = width / intrinsicWidth;
    final heightScale = height / intrinsicHeight;
    final scale = math.min(
        1.0,
        switch (fit) {
          BoxFit.cover || BoxFit.fill => math.max(widthScale, heightScale),
          BoxFit.contain ||
          BoxFit.scaleDown =>
            math.min(widthScale, heightScale),
          BoxFit.fitWidth => widthScale,
          BoxFit.fitHeight => heightScale,
          BoxFit.none => 1.0,
        });
    if (scale >= 1) return const ui.TargetImageSize();
    // The larger intrinsic axis minimises integer-rounding error. The other
    // dimension stays null, so even unusual RAWG/poster ratios are not distorted.
    return intrinsicWidth >= intrinsicHeight
        ? ui.TargetImageSize(width: (intrinsicWidth * scale).ceil())
        : ui.TargetImageSize(height: (intrinsicHeight * scale).ceil());
  }

  String imageUrl(String url, MediaImageSource source, BoxFit fit) {
    final ratio = source.aspectRatio;
    if (ratio == null || fit == BoxFit.none) return url;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'image.tmdb.org' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        !RegExp(r'^/t/p/(w\d+|original)/[^/]+$').hasMatch(uri.path)) {
      return url;
    }
    final coverWidth = math.max(width.toDouble(), height * ratio);
    final containWidth = math.min(width.toDouble(), height * ratio);
    final requiredWidth = switch (fit) {
      BoxFit.cover || BoxFit.fill => coverWidth,
      BoxFit.contain || BoxFit.scaleDown => containWidth,
      BoxFit.fitWidth => width.toDouble(),
      BoxFit.fitHeight => height * ratio,
      BoxFit.none => coverWidth,
    };
    var variant = 'original';
    for (final candidate in source.widths) {
      if (candidate >= requiredWidth) {
        variant = 'w$candidate';
        break;
      }
    }
    final segments = uri.pathSegments.toList()..[2] = variant;
    return uri.replace(pathSegments: segments).toString();
  }

  @override
  bool operator ==(Object other) =>
      other is MediaImageBudget &&
      width == other.width &&
      height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Adds a decode-time size callback while retaining the source provider's
/// fetching, progress, disk cache and codec/animation handling.
class MediaImageProvider extends ImageProvider<MediaImageKey> {
  const MediaImageProvider(this.image,
      {required this.budget, required this.fit});

  final ImageProvider image;
  final MediaImageBudget budget;
  final BoxFit fit;

  @override
  Future<MediaImageKey> obtainKey(ImageConfiguration configuration) {
    // Preserve synchronous cache hits. An async/await wrapper would make an
    // already-decoded image briefly look like a fresh asynchronous load.
    final source = image.obtainKey(configuration);
    if (source is SynchronousFuture) {
      late MediaImageKey key;
      source.then((value) => key = MediaImageKey(value, budget, fit));
      return SynchronousFuture(key);
    }
    return source.then((value) => MediaImageKey(value, budget, fit));
  }

  @override
  bool operator ==(Object other) =>
      other is MediaImageProvider &&
      other.image == image &&
      other.budget == budget &&
      other.fit == fit;

  @override
  int get hashCode => Object.hash(image, budget, fit);

  @override
  ImageStreamCompleter loadImage(
      MediaImageKey key, ImageDecoderCallback decode) {
    // Like Flutter's ResizeImage, this adapter delegates decoding to its source.
    // ignore: invalid_use_of_protected_member
    final completer = image.loadImage(
      key.sourceKey,
      (buffer, {getTargetSize}) => decode(
        buffer,
        getTargetSize: (width, height) => budget.targetSize(width, height, fit),
      ),
    );
    completer.addEphemeralErrorListener((error, stackTrace) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    });
    return completer;
  }
}

@immutable
class MediaImageKey {
  const MediaImageKey(this.sourceKey, this.budget, this.fit);

  final Object sourceKey;
  final MediaImageBudget budget;
  final BoxFit fit;

  @override
  bool operator ==(Object other) =>
      other is MediaImageKey &&
      sourceKey == other.sourceKey &&
      budget == other.budget &&
      fit == other.fit;

  @override
  int get hashCode => Object.hash(sourceKey, budget, fit);
}

/// CachedNetworkImage's presentation contract, with a layout/DPR-aware provider.
/// In particular imageBuilder receives the bounded provider too: using only
/// CachedNetworkImage.memCacheWidth would leave DecorationImage headers unbound.
/// Do not use this for the fullscreen, zoomable screenshot viewer.
class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.imageUrl,
    this.source = MediaImageSource.generic,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
  });

  final String imageUrl;
  final MediaImageSource source;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ImageWidgetBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.constrain(Size(
        width ?? constraints.maxWidth,
        height ?? constraints.maxHeight,
      ));
      final budget = size.isFinite && !size.isEmpty
          ? MediaImageBudget.fromSize(
              size, MediaQuery.devicePixelRatioOf(context))
          : null;
      final effectiveFit = fit ?? BoxFit.scaleDown;
      final url = budget?.imageUrl(imageUrl, source, effectiveFit) ?? imageUrl;
      final ImageProvider original = CachedNetworkImageProvider(url);
      final ImageProvider provider = budget == null
          ? original
          : MediaImageProvider(original, budget: budget, fit: effectiveFit);
      // OctoImage is also CachedNetworkImage's presentation layer, so fades,
      // loading/error widgets and imageBuilder behaviour stay unchanged.
      return OctoImage(
        image: provider,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) =>
            placeholder?.call(context, imageUrl) ?? Container(),
        errorBuilder: errorWidget == null
            ? null
            : (context, error, stackTrace) =>
                errorWidget!(context, imageUrl, error),
        imageBuilder: imageBuilder == null
            ? null
            : (context, child) => imageBuilder!(context, provider),
      );
    });
  }
}
