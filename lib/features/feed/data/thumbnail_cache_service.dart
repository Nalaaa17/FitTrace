import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:metrics_engine/metrics_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/logging/app_logger.dart';

/// Renders and disk-caches 200x120px monochrome route thumbnails (PRD M3-01).
class ThumbnailCacheService {
  ThumbnailCacheService({
    Future<Directory> Function()? cacheDirectoryResolver,
  }) : _cacheDirectoryResolver =
            cacheDirectoryResolver ?? getApplicationCacheDirectory;

  static const int widthPx = 200;
  static const int heightPx = 120;

  final Future<Directory> Function() _cacheDirectoryResolver;

  Future<File> thumbnailFileFor(int activityId) async {
    final cacheDir = await _cacheDirectoryResolver();
    final thumbDir = Directory(p.join(cacheDir.path, 'thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return File(p.join(thumbDir.path, 'act_$activityId.png'));
  }

  Future<File?> getExistingThumbnail(int activityId) async {
    try {
      final file = await thumbnailFileFor(activityId);
      if (await file.exists()) return file;
      return null;
    } on Object {
      return null;
    }
  }

  Future<void> deleteThumbnail(int activityId) async {
    try {
      final file = await thumbnailFileFor(activityId);
      if (await file.exists()) {
        await file.delete();
      }
    } on Object catch (e) {
      AppLogger.warn('ThumbnailCache', 'Failed deleting thumbnail $activityId', e);
    }
  }

  Future<File?> renderAndCache(
    int activityId,
    List<ParsedTrackPoint> trackPoints,
  ) async {
    if (trackPoints.length < 2) return null;

    final pngBytes = await renderMonochromePng(trackPoints);
    if (pngBytes == null) return null;

    final target = await thumbnailFileFor(activityId);
    final temp = File('${target.path}.tmp');
    await temp.writeAsBytes(pngBytes, flush: true);
    await temp.rename(target.path);
    return target;
  }

  /// Renders a 200x120 RGBA PNG polyline from trackpoints using `dart:ui`.
  Future<Uint8List?> renderMonochromePng(
    List<ParsedTrackPoint> trackPoints,
  ) async {
    if (trackPoints.length < 2) return null;

    final sampled = _downsampleUniform(trackPoints, maxPoints: 120);

    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLng = double.infinity;
    var maxLng = -double.infinity;

    for (final pt in sampled) {
      if (pt.latitudeDeg < minLat) minLat = pt.latitudeDeg;
      if (pt.latitudeDeg > maxLat) maxLat = pt.latitudeDeg;
      if (pt.longitudeDeg < minLng) minLng = pt.longitudeDeg;
      if (pt.longitudeDeg > maxLng) maxLng = pt.longitudeDeg;
    }

    const pad = 14.0;
    const drawW = widthPx - pad * 2;
    const drawH = heightPx - pad * 2;

    final latSpan = math.max(1e-6, maxLat - minLat);
    // Approximate longitude compression by cosine of mid-latitude.
    final midLatRad = ((minLat + maxLat) * 0.5) * (math.pi / 180.0);
    final cosLat = math.max(0.1, math.cos(midLatRad));
    final lngSpan = math.max(1e-6, (maxLng - minLng) * cosLat);

    final scale = math.min(drawW / lngSpan, drawH / latSpan);
    final actualW = lngSpan * scale;
    final actualH = latSpan * scale;
    final offsetX = pad + (drawW - actualW) * 0.5;
    final offsetY = pad + (drawH - actualH) * 0.5;

    ui.Offset project(ParsedTrackPoint pt) {
      final x = offsetX + ((pt.longitudeDeg - minLng) * cosLat) * scale;
      final y = offsetY + (maxLat - pt.latitudeDeg) * scale;
      return ui.Offset(x, y);
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
    );

    // Subtle elevated dark tile background.
    final bgPaint = ui.Paint()..color = const ui.Color(0xFF161616);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
      bgPaint,
    );

    final path = ui.Path();
    final firstOffset = project(sampled.first);
    path.moveTo(firstOffset.dx, firstOffset.dy);
    for (var i = 1; i < sampled.length; i++) {
      final pt = project(sampled[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    // Soft monochrome glow + crisp foreground polyline.
    final glowPaint = ui.Paint()
      ..color = const ui.Color(0x40FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    final strokePaint = ui.Paint()
      ..color = const ui.Color(0xFFF5F5F5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Start (white circle) and Finish (bordered dot) markers.
    final startFill = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(firstOffset, 3.2, startFill);

    final lastOffset = project(sampled.last);
    final finishRing = ui.Paint()
      ..color = const ui.Color(0xFF0A0A0A)
      ..style = ui.PaintingStyle.fill;
    final finishBorder = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(lastOffset, 3.4, finishRing);
    canvas.drawCircle(lastOffset, 3.4, finishBorder);

    final picture = recorder.endRecording();
    final image = await picture.toImage(widthPx, heightPx);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return byteData?.buffer.asUint8List();
  }

  List<ParsedTrackPoint> _downsampleUniform(
    List<ParsedTrackPoint> points, {
    required int maxPoints,
  }) {
    if (points.length <= maxPoints) return points;
    final step = (points.length - 1) / (maxPoints - 1);
    return List<ParsedTrackPoint>.generate(
      maxPoints,
      (i) => points[(i * step).round().clamp(0, points.length - 1)],
      growable: false,
    );
  }
}
