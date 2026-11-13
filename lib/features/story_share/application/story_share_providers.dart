import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/story_image_cache_service.dart';
import '../data/story_share_service.dart';

final storyPresetsProvider = StreamProvider<List<StoryPresetRecord>>((ref) {
  return ref.watch(appDatabaseProvider).watchStoryPresets();
});

/// Standard 9:16 Instagram Story export dimensions (`PRD M4-01`: `1080×1920`).
const double storyLogicalWidth = 360.0;
const double storyLogicalHeight = 640.0;
const double storyExportPixelRatio = 3.0;
const int storyTargetWidthPx = 1080;
const int storyTargetHeightPx = 1920;

typedef GalleryPhotoPicker = Future<Uint8List?> Function();

final storyImageCacheServiceProvider = Provider<StoryImageCacheService>((ref) {
  return StoryImageCacheService();
});

final storyShareServiceProvider = Provider<StoryShareService>((ref) {
  return const MethodChannelStoryShareService();
});

final galleryPhotoPickerProvider = Provider<GalleryPhotoPicker>((ref) {
  final picker = ImagePicker();
  return () async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return null;
    return picked.readAsBytes();
  };
});

class CapturedStoryPng {
  const CapturedStoryPng({
    required this.bytes,
    required this.widthPx,
    required this.heightPx,
  });

  final Uint8List bytes;
  final int widthPx;
  final int heightPx;
}

/// Captures a `RepaintBoundary` (`360×640` logical) at `3.0x` pixel ratio ->
/// exact `1080×1920` RGBA PNG bytes (`PRD M4-01`).
Future<CapturedStoryPng> captureBoundaryToPngBytes(
  GlobalKey boundaryKey, {
  double pixelRatio = storyExportPixelRatio,
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('Kanvas Story belum siap dirender.');
  }

  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Gagal mengonversi gambar Story ke PNG.');
    }
    return CapturedStoryPng(
      bytes: byteData.buffer.asUint8List(),
      widthPx: image.width,
      heightPx: image.height,
    );
  } finally {
    image.dispose();
  }
}

