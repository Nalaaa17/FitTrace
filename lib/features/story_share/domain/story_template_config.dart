import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show FontWeight, Offset, TextAlign;

/// Supported Instagram Story card templates (`PRD M4-02`..`M4-04`, `ADR-005`).
enum StoryTemplateId {
  routeGlow('routeGlow', 'Route Glow'),
  photoOverlay('photoOverlay', 'Photo Overlay'),
  minimalist('minimalist', 'Minimalist'),
  pastelAesthetic('pastelAesthetic', 'Pastel Aesthetic'),
  receiptRunner('receiptRunner', 'Run Receipt'),
  cyberNeon('cyberNeon', 'Cyber Neon'),
  cuteJournal('cuteJournal', 'Cute Scrapbook');

  const StoryTemplateId(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static StoryTemplateId fromStorageKey(String key) {
    return StoryTemplateId.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => StoryTemplateId.routeGlow,
    );
  }
}

enum StoryTextAlignment {
  left(TextAlign.left, 'Kiri'),
  center(TextAlign.center, 'Tengah'),
  right(TextAlign.right, 'Kanan');

  const StoryTextAlignment(this.textAlign, this.label);

  final TextAlign textAlign;
  final String label;
}

enum StoryFontWeightOption {
  regular(FontWeight.w400, 'Regular'),
  semiBold(FontWeight.w600, 'SemiBold'),
  bold(FontWeight.w700, 'Bold');

  const StoryFontWeightOption(this.weight, this.label);

  final FontWeight weight;
  final String label;
}

/// Interactive editor state for the 9:16 Story Card canvas (`PRD M4-05`).
class StoryEditorConfig {
  const StoryEditorConfig({
    this.templateId = StoryTemplateId.routeGlow,
    this.minimalistDark = true,
    this.photoBytes,
    this.stickerOffset = Offset.zero,
    this.stickerScale = 1.0,
    this.stickerRotationRad = 0.0,
    this.rotationEnabled = true,
    this.alignment = StoryTextAlignment.left,
    this.fontWeight = StoryFontWeightOption.bold,
    this.showDistance = true,
    this.showPace = true,
    this.showMovingTime = true,
    this.showAvgHr = true,
    this.showElevation = true,
    this.showDate = true,
    this.showTitle = true,
    this.showWatermark = true,
  });

  final StoryTemplateId templateId;
  final bool minimalistDark;
  final Uint8List? photoBytes;
  final Offset stickerOffset;
  final double stickerScale;
  final double stickerRotationRad;
  final bool rotationEnabled;
  final StoryTextAlignment alignment;
  final StoryFontWeightOption fontWeight;
  final bool showDistance;
  final bool showPace;
  final bool showMovingTime;
  final bool showAvgHr;
  final bool showElevation;
  final bool showDate;
  final bool showTitle;
  final bool showWatermark;

  StoryEditorConfig copyWith({
    StoryTemplateId? templateId,
    bool? minimalistDark,
    Uint8List? Function()? photoBytes,
    Offset? stickerOffset,
    double? stickerScale,
    double? stickerRotationRad,
    bool? rotationEnabled,
    StoryTextAlignment? alignment,
    StoryFontWeightOption? fontWeight,
    bool? showDistance,
    bool? showPace,
    bool? showMovingTime,
    bool? showAvgHr,
    bool? showElevation,
    bool? showDate,
    bool? showTitle,
    bool? showWatermark,
  }) {
    return StoryEditorConfig(
      templateId: templateId ?? this.templateId,
      minimalistDark: minimalistDark ?? this.minimalistDark,
      photoBytes: photoBytes != null ? photoBytes() : this.photoBytes,
      stickerOffset: stickerOffset ?? this.stickerOffset,
      stickerScale: stickerScale ?? this.stickerScale,
      stickerRotationRad: stickerRotationRad ?? this.stickerRotationRad,
      rotationEnabled: rotationEnabled ?? this.rotationEnabled,
      alignment: alignment ?? this.alignment,
      fontWeight: fontWeight ?? this.fontWeight,
      showDistance: showDistance ?? this.showDistance,
      showPace: showPace ?? this.showPace,
      showMovingTime: showMovingTime ?? this.showMovingTime,
      showAvgHr: showAvgHr ?? this.showAvgHr,
      showElevation: showElevation ?? this.showElevation,
      showDate: showDate ?? this.showDate,
      showTitle: showTitle ?? this.showTitle,
      showWatermark: showWatermark ?? this.showWatermark,
    );
  }

  /// Serializes user layout configuration (`PRD M4-09`) excluding transient photo bytes.
  String toLayoutJsonString() {
    return jsonEncode(<String, dynamic>{
      'templateId': templateId.storageKey,
      'minimalistDark': minimalistDark,
      'stickerOffsetDx': stickerOffset.dx,
      'stickerOffsetDy': stickerOffset.dy,
      'stickerScale': stickerScale,
      'stickerRotationRad': stickerRotationRad,
      'rotationEnabled': rotationEnabled,
      'alignment': alignment.name,
      'fontWeight': fontWeight.name,
      'showDistance': showDistance,
      'showPace': showPace,
      'showMovingTime': showMovingTime,
      'showAvgHr': showAvgHr,
      'showElevation': showElevation,
      'showDate': showDate,
      'showTitle': showTitle,
      'showWatermark': showWatermark,
    });
  }

  static StoryEditorConfig fromLayoutJsonString(
    String rawJson, {
    Uint8List? preservePhotoBytes,
  }) {
    final map = jsonDecode(rawJson) as Map<String, dynamic>;
    final alignName = map['alignment'] as String?;
    final weightName = map['fontWeight'] as String?;

    return StoryEditorConfig(
      templateId: StoryTemplateId.fromStorageKey(
        (map['templateId'] as String?) ?? 'routeGlow',
      ),
      minimalistDark: (map['minimalistDark'] as bool?) ?? true,
      photoBytes: preservePhotoBytes,
      stickerOffset: Offset(
        ((map['stickerOffsetDx'] as num?) ?? 0).toDouble(),
        ((map['stickerOffsetDy'] as num?) ?? 0).toDouble(),
      ),
      stickerScale: ((map['stickerScale'] as num?) ?? 1.0).toDouble(),
      stickerRotationRad:
          ((map['stickerRotationRad'] as num?) ?? 0.0).toDouble(),
      rotationEnabled: (map['rotationEnabled'] as bool?) ?? true,
      alignment: StoryTextAlignment.values.firstWhere(
        (e) => e.name == alignName,
        orElse: () => StoryTextAlignment.left,
      ),
      fontWeight: StoryFontWeightOption.values.firstWhere(
        (e) => e.name == weightName,
        orElse: () => StoryFontWeightOption.bold,
      ),
      showDistance: (map['showDistance'] as bool?) ?? true,
      showPace: (map['showPace'] as bool?) ?? true,
      showMovingTime: (map['showMovingTime'] as bool?) ?? true,
      showAvgHr: (map['showAvgHr'] as bool?) ?? true,
      showElevation: (map['showElevation'] as bool?) ?? true,
      showDate: (map['showDate'] as bool?) ?? true,
      showTitle: (map['showTitle'] as bool?) ?? true,
      showWatermark: (map['showWatermark'] as bool?) ?? true,
    );
  }
}

