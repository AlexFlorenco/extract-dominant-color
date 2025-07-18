import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class ExtractDominantColor {
  static Future<Color?> fromImage(ImageProvider provider) async {
    try {
      final quantizerResult = await _extractColorsFromImageProvider(provider);
      final Map<int, int> colorToCount = quantizerResult.colorToCount.map(
        (key, value) => MapEntry<int, int>(_getArgbFromAbgr(key), value),
      );

      final List<int> filteredResults = Score.score(
        colorToCount,
        desired: 1,
        filter: true,
      );

      if (filteredResults.isNotEmpty) return Color(filteredResults.first);
      return null;
    } catch (e) {
      debugPrint('Error getting colors from image: $e');
      return null;
    }
  }

  static Future<QuantizerResult> _extractColorsFromImageProvider(
    ImageProvider imageProvider,
  ) async {
    final ui.Image scaledImage = await _imageProviderToScaled(imageProvider);
    final ByteData? imageBytes = await scaledImage.toByteData();

    final QuantizerResult quantizerResult = await QuantizerCelebi().quantize(
      imageBytes!.buffer.asUint32List(),
      128,
      returnInputPixelToClusterPixel: true,
    );
    return quantizerResult;
  }

  static Future<ui.Image> _imageProviderToScaled(ImageProvider imageProvider) async {
    const double maxDimension = 112.0;
    final ImageStream stream = imageProvider.resolve(
      const ImageConfiguration(size: Size(maxDimension, maxDimension)),
    );
    final Completer<ui.Image> imageCompleter = Completer<ui.Image>();
    late ImageStreamListener listener;
    late ui.Image scaledImage;
    Timer? loadFailureTimeout;

    listener = ImageStreamListener((ImageInfo info, bool sync) async {
      loadFailureTimeout?.cancel();
      stream.removeListener(listener);
      final ui.Image image = info.image;
      final int width = image.width;
      final int height = image.height;
      double paintWidth = width.toDouble();
      double paintHeight = height.toDouble();
      assert(width > 0 && height > 0);

      final bool rescale = width > maxDimension || height > maxDimension;
      if (rescale) {
        paintWidth =
            (width > height) ? maxDimension : (maxDimension / height) * width;
        paintHeight =
            (height > width) ? maxDimension : (maxDimension / width) * height;
      }
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTRB(0, 0, paintWidth, paintHeight),
        image: image,
        filterQuality: FilterQuality.none,
      );

      final ui.Picture picture = pictureRecorder.endRecording();
      scaledImage = await picture.toImage(
        paintWidth.toInt(),
        paintHeight.toInt(),
      );
      imageCompleter.complete(info.image);
    }, onError: (Object exception, StackTrace? stackTrace) {
      stream.removeListener(listener);
      throw Exception('Failed to render image: $exception');
    });

    loadFailureTimeout = Timer(const Duration(seconds: 5), () {
      stream.removeListener(listener);
      imageCompleter.completeError(
        TimeoutException('Timeout occurred trying to load image'),
      );
    });

    stream.addListener(listener);
    await imageCompleter.future;
    return scaledImage;
  }

  static int _getArgbFromAbgr(int abgr) {
    const int exceptRMask = 0xFF00FFFF;
    const int onlyRMask = ~exceptRMask;
    const int exceptBMask = 0xFFFFFF00;
    const int onlyBMask = ~exceptBMask;
    final int r = (abgr & onlyRMask) >> 16;
    final int b = abgr & onlyBMask;
    return (abgr & exceptRMask & exceptBMask) | (b << 16) | r;
  }
}
