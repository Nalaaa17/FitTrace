import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fit_trace/app.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/features/activity_detail/application/activity_detail_providers.dart';
import 'package:fit_trace/features/story_share/application/story_share_providers.dart';
import 'package:fit_trace/features/story_share/data/story_image_cache_service.dart';
import 'package:fit_trace/features/story_share/data/story_share_service.dart';
import 'package:fit_trace/features/story_share/presentation/story_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

ActivityDetailBundle _sampleBundle() {
  final now = DateTime.utc(2026, 11, 12, 6, 30);
  final activity = ActivityRecord(
    id: 77,
    garminActivityId: null,
    title: 'Jakarta Dawn 10K',
    sportType: 1,
    startTimeUtc: now,
    utcOffsetSeconds: 25200,
    durationTotalSec: 3120,
    durationMovingSec: 3060,
    distanceMeters: 10040,
    avgPaceSecPerKm: 304.8,
    avgHeartRate: 158,
    maxHeartRate: 179,
    avgCadence: 89,
    totalElevationGainM: 64,
    totalElevationLossM: 61,
    caloriesKcal: 680,
    isIndoor: false,
    hasGpsTrack: true,
    gpsQuality: 'good',
    source: 'manualImport',
    syncStatus: 'localOnly',
    originalFitPath: null,
    fitFileHash: 'abc123storyhash',
    splitPacesSecPerKm: const <int>[308, 302, 299],
    zoneDurationsSec: const <int>[120, 420, 1100, 1200, 220],
    hasCustomTitle: false,
    createdAt: now,
    updatedAt: now,
  );

  const p0 = LatLng(-6.2000, 106.8000);
  const p1 = LatLng(-6.1960, 106.8030);
  const p2 = LatLng(-6.1920, 106.8010);

  return ActivityDetailBundle(
    activity: activity,
    lapSplits: const <LapSplitRecord>[],
    chartPoints: const <ChartSamplePoint>[],
    mapSegments: const <MapRouteSegment>[
      MapRouteSegment(points: <LatLng>[p0, p1], paceIntensity: 0.35),
      MapRouteSegment(points: <LatLng>[p1, p2], paceIntensity: 0.85),
    ],
    startPoint: p0,
    endPoint: p2,
    boundsPoints: const <LatLng>[p0, p1, p2],
  );
}

Future<Uint8List> _createSamplePhotoPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 120, 120),
    Paint()..color = const Color(0xFF444444),
  );
  final picture = recorder.endRecording();
  final img = await picture.toImage(120, 120);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decodePngDimensions(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxSteps = 50,
}) async {
  for (var i = 0; i < maxSteps && !condition(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();
  }
}

class _FakeStoryShareService implements StoryShareService {
  bool installed = true;
  InstagramShareOutcome nextShareOutcome = InstagramShareOutcome.launched;
  final List<Map<String, Object?>> shareCalls = <Map<String, Object?>>[];
  final List<({String filePath, String displayName})> galleryCalls =
      <({String filePath, String displayName})>[];

  @override
  Future<bool> isInstagramInstalled() async => installed;

  @override
  Future<InstagramShareOutcome> shareToInstagramStory({
    String? backgroundPath,
    String? stickerPath,
    String topColorHex = '#0A0A0A',
    String bottomColorHex = '#0A0A0A',
    String appId = 'com.fittrace.app',
  }) async {
    shareCalls.add(<String, Object?>{
      'backgroundPath': backgroundPath,
      'stickerPath': stickerPath,
      'topColorHex': topColorHex,
      'bottomColorHex': bottomColorHex,
      'appId': appId,
    });
    return nextShareOutcome;
  }

  @override
  Future<String> saveToGallery({
    required String filePath,
    required String displayName,
  }) async {
    galleryCalls.add((filePath: filePath, displayName: displayName));
    return 'content://media/external/images/media/999';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoryImageCacheService', () {
    test('prunes cached PNG files older than 24 hours while retaining recent files', () async {
      final tempDir = await Directory.systemTemp.createTemp('fittrace_story_cache_');
      try {
        final cache = StoryImageCacheService(
          cacheDirectoryResolver: () async => tempDir,
        );
        final oldFile = await cache.savePng(
          pngBytes: Uint8List.fromList(<int>[1, 2, 3]),
          activityId: 1,
          tag: 'old',
        );
        final freshFile = await cache.savePng(
          pngBytes: Uint8List.fromList(<int>[4, 5, 6]),
          activityId: 2,
          tag: 'fresh',
        );

        final nowUtc = DateTime.now().toUtc();
        await oldFile.setLastModified(nowUtc.subtract(const Duration(hours: 25)));
        await freshFile.setLastModified(nowUtc.subtract(const Duration(hours: 2)));

        final removed = await cache.cleanupExpiredFiles(nowUtc: nowUtc);
        expect(removed, 1);
        expect(await oldFile.exists(), isFalse);
        expect(await freshFile.exists(), isTrue);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('MethodChannelStoryShareService', () {
    const channel = MethodChannel('com.fittrace.app/story_share');
    final recordedCalls = <MethodCall>[];

    setUp(() {
      recordedCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        switch (call.method) {
          case 'isInstagramInstalled':
            return true;
          case 'shareToInstagramStory':
            return 'launched';
          case 'saveToGallery':
            return 'content://gallery/123';
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('invokes native story_share methods with expected arguments', () async {
      const service = MethodChannelStoryShareService();

      expect(await service.isInstagramInstalled(), isTrue);
      final outcome = await service.shareToInstagramStory(
        backgroundPath: '/cache/bg.png',
        stickerPath: '/cache/sticker.png',
      );
      expect(outcome, InstagramShareOutcome.launched);

      final galleryUri = await service.saveToGallery(
        filePath: '/cache/full.png',
        displayName: 'fittrace_story.png',
      );
      expect(galleryUri, 'content://gallery/123');
      expect(recordedCalls.length, 3);
      expect(
        (recordedCalls[1].arguments as Map<Object?, Object?>)['stickerPath'],
        '/cache/sticker.png',
      );
    });
  });

  testWidgets(
    'StoryEditorScreen switches templates/styles, exports exact 1080x1920 PNG assets, and handles IG fallback + draft toast',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final fakeShare = _FakeStoryShareService();
      late Directory tempDir;
      late Uint8List samplePhotoBytes;

      try {
        await tester.runAsync(() async {
          tempDir = await Directory.systemTemp.createTemp('fittrace_story_widget_');
          await db.getPreferences();
          samplePhotoBytes = await _createSamplePhotoPng();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              storyImageCacheServiceProvider.overrideWithValue(
                StoryImageCacheService(cacheDirectoryResolver: () async => tempDir),
              ),
              storyShareServiceProvider.overrideWithValue(fakeShare),
              galleryPhotoPickerProvider.overrideWithValue(
                () async => samplePhotoBytes,
              ),
            ],
            child: FitTraceApp(
              home: StoryEditorScreen(bundle: _sampleBundle()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Template A hero metric visible on initial canvas.
        expect(find.text('10.04'), findsOneWidget);
        expect(find.text('FITTRACE'), findsOneWidget);

        // Drag gesture moves sticker safely and double-tap resets.
        await tester.drag(
          find.byKey(const ValueKey<String>('story_sticker_gesture_area')),
          const Offset(18, -24),
        );
        await tester.pump();
        await tester.tap(find.byTooltip('Reset Posisi'));
        await tester.pump();

        // Switch metrics tab and toggle Watermark off & back on.
        await tester.tap(find.text('Metrik'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Watermark'));
        await tester.pump();
        expect(find.text('FITTRACE'), findsNothing);
        await tester.tap(find.text('Watermark'));
        await tester.pump();
        expect(find.text('FITTRACE'), findsOneWidget);

        // Switch style tab -> change alignment & font weight.
        await tester.tap(find.text('Gaya'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tengah'));
        await tester.tap(find.text('SemiBold'));
        await tester.pump();

        // Switch to Minimalist template & toggle light background.
        await tester.tap(find.text('Template'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Minimalist'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Putih Bersih'));
        await tester.pump();

        // Switch to Pastel Aesthetic template.
        await tester.tap(find.text('Pastel Aesthetic'));
        await tester.pumpAndSettle();
        expect(find.text('✦ RUN DIARY ✦'), findsOneWidget);
        expect(find.text('✿ FITTRACE RUN CLUB'), findsOneWidget);

        // Switch to Run Receipt template.
        await tester.tap(find.text('Run Receipt'));
        await tester.pumpAndSettle();
        expect(find.text('*** FITTRACE OFFICIAL RECEIPT ***'), findsOneWidget);
        expect(find.text('THANK YOU FOR RUNNING!'), findsOneWidget);

        // Switch to Cyber Neon template.
        await tester.tap(find.text('Cyber Neon'));
        await tester.pumpAndSettle();
        expect(find.text('TELEMETRY // RUN_LOG'), findsOneWidget);
        expect(find.text('[ FITTRACE // NIGHT OPS ]'), findsOneWidget);

        // Switch to Cute Scrapbook template.
        await tester.tap(find.text('Cute Scrapbook'));
        await tester.pumpAndSettle();
        expect(find.text('✿ GOOD RUN ✿'), findsOneWidget);
        expect(find.text('happy running adventures ☀️👟'), findsOneWidget);

        // Switch to Photo Overlay -> pick gallery photo -> share dual assets to IG.
        await tester.tap(find.text('Photo Overlay'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pilih Foto Galeri').first);
        await _pumpUntil(
          tester,
          () => find.text('Ganti Foto Galeri').evaluate().isNotEmpty,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bagikan IG'));
        await tester.pump();
        await _pumpUntil(tester, () => fakeShare.shareCalls.isNotEmpty);

        expect(fakeShare.shareCalls.length, 1);
        final sharedArgs = fakeShare.shareCalls.single;
        final bgPath = sharedArgs['backgroundPath'] as String?;
        final stickerPath = sharedArgs['stickerPath'] as String?;
        expect(bgPath, isNotNull);
        expect(stickerPath, isNotNull);

        await tester.runAsync(() async {
          final bgBytes = await File(bgPath!).readAsBytes();
          final stickerBytes = await File(stickerPath!).readAsBytes();
          final bgImg = await _decodePngDimensions(bgBytes);
          final stickerImg = await _decodePngDimensions(stickerBytes);
          try {
            expect(bgImg.width, 1080);
            expect(bgImg.height, 1920);
            expect(stickerImg.width, 1080);
            expect(stickerImg.height, 1920);
          } finally {
            bgImg.dispose();
            stickerImg.dispose();
          }
        });

        // When Instagram is not installed -> fallback dialog -> Batal shows draft toast;
        // triggering again and choosing Simpan ke Galeri saves 1080x1920 PNG.
        fakeShare.installed = false;
        await tester.tap(find.text('Bagikan IG'));
        await tester.pump();
        await _pumpUntil(
          tester,
          () => find.text('Instagram Tidak Ditemukan').evaluate().isNotEmpty,
        );

        expect(find.text('Instagram Tidak Ditemukan'), findsOneWidget);
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Draft Story tersimpan di cache sementara'),
          findsOneWidget,
        );

        await tester.tap(find.text('Bagikan IG'));
        await tester.pump();
        await _pumpUntil(
          tester,
          () => find.text('Instagram Tidak Ditemukan').evaluate().isNotEmpty,
        );

        await tester.tap(find.text('Simpan ke Galeri').last);
        await tester.pump();
        await _pumpUntil(tester, () => fakeShare.galleryCalls.isNotEmpty);

        expect(fakeShare.galleryCalls.length, 1);
        expect(File(fakeShare.galleryCalls.single.filePath).existsSync(), isTrue);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(Duration.zero);
        await tester.runAsync(() async {
          await db.close();
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
      }
    },
  );
}
