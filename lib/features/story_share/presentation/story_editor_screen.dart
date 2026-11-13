import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../activity_detail/application/activity_detail_providers.dart';
import '../application/story_share_providers.dart';
import '../data/story_share_service.dart';
import '../domain/story_template_config.dart';
import 'widgets/story_card_canvas.dart';

/// Interactive 9:16 (`1080×1920`) Instagram Story card editor (`PRD M4-01`..`M4-07`).
class StoryEditorScreen extends ConsumerStatefulWidget {
  const StoryEditorScreen({
    super.key,
    required this.bundle,
    this.initialConfig,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig? initialConfig;

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  final GlobalKey _fullCardKey = GlobalKey();
  final GlobalKey _backgroundOnlyKey = GlobalKey();
  final GlobalKey _stickerOnlyKey = GlobalKey();

  late StoryEditorConfig _config;
  int _activeToolbarTab = 0; // 0 = Template, 1 = Metrik, 2 = Gaya
  bool _isExporting = false;
  bool _initializedFromPrefs = false;
  File? _lastDraftFile;
  bool _sharedCompleted = false;

  Offset _gestureBaseOffset = Offset.zero;
  double _gestureBaseScale = 1.0;
  double _gestureBaseRotation = 0.0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialConfig ?? const StoryEditorConfig();
    _config = widget.bundle.activity.avgHeartRate == null
        ? initial.copyWith(showAvgHr: false)
        : initial;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromPrefs && widget.initialConfig == null) {
      _initializedFromPrefs = true;
      final prefs = ref.read(userPreferencesProvider).value;
      if (prefs != null) {
        _config = _config.copyWith(
          templateId: StoryTemplateId.fromStorageKey(prefs.defaultTemplateId),
          showWatermark: prefs.watermarkEnabled,
        );
      }
    }
  }

  Future<void> _pickGalleryPhoto() async {
    try {
      final picker = ref.read(galleryPhotoPickerProvider);
      final bytes = await picker();
      if (bytes == null || !mounted) return;
      setState(() {
        _config = _config.copyWith(
          templateId: StoryTemplateId.photoOverlay,
          photoBytes: () => bytes,
        );
      });
    } on Object catch (error) {
      AppLogger.warn('StoryEditor', 'Gallery photo pick failed', error);
      if (!mounted) return;
      _showToast('Gagal memuat foto galeri: $error');
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _gestureBaseOffset = _config.stickerOffset;
    _gestureBaseScale = _config.stickerScale;
    _gestureBaseRotation = _config.stickerRotationRad;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final nextOffset = _gestureBaseOffset + details.focalPointDelta;
    _gestureBaseOffset = nextOffset;

    final nextScale = (_gestureBaseScale * details.scale).clamp(0.55, 2.2);
    var nextRotation = _config.rotationEnabled
        ? _gestureBaseRotation + details.rotation
        : _config.stickerRotationRad;

    // Gentle magnetic snap near 0 radians so straight cards stay level.
    if (_config.rotationEnabled && nextRotation.abs() < (3 * math.pi / 180)) {
      nextRotation = 0.0;
    }

    setState(() {
      _config = _config.copyWith(
        stickerOffset: nextOffset,
        stickerScale: nextScale,
        stickerRotationRad: nextRotation,
      );
    });
  }

  void _resetTransform() {
    setState(() {
      _config = _config.copyWith(
        stickerOffset: Offset.zero,
        stickerScale: 1.0,
        stickerRotationRad: 0.0,
      );
    });
  }

  Future<void> _saveCurrentPreset() async {
    final res = await showDialog<TextInputDialogResult>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'Simpan Preset Layout Story',
        initialValue: '${_config.templateId.label} Custom',
        labelText: 'Nama Preset',
        hintText: 'Contoh: Race Day Pojok Bawah',
      ),
    );
    if (res == null || res.action != 'save' || !mounted) return;
    final trimmed = res.text.trim();
    if (trimmed.isEmpty) return;

    await ref.read(appDatabaseProvider).saveStoryPreset(
          name: trimmed,
          configJson: _config.toLayoutJsonString(),
        );
    if (mounted) {
      _showToast('Preset "$trimmed" tersimpan.');
    }
  }

  void _applyPreset(StoryPresetRecord preset) {
    try {
      final loaded = StoryEditorConfig.fromLayoutJsonString(
        preset.configJson,
        preservePhotoBytes: _config.photoBytes,
      );
      setState(() {
        _config = widget.bundle.activity.avgHeartRate == null
            ? loaded.copyWith(showAvgHr: false)
            : loaded;
      });
      _showToast('Preset "${preset.name}" diterapkan.');
    } on Object catch (error) {
      AppLogger.warn('StoryEditor', 'Failed loading preset', error);
      _showToast('Gagal memuat preset.');
    }
  }

  Future<File> _renderAndCacheComposite() async {
    final capture = await captureBoundaryToPngBytes(_fullCardKey);
    final file = await ref.read(storyImageCacheServiceProvider).savePng(
          pngBytes: capture.bytes,
          activityId: widget.bundle.activity.id,
          tag: '${_config.templateId.storageKey}_full',
        );
    _lastDraftFile = file;
    return file;
  }

  Future<({File backgroundFile, File? stickerFile})>
      _renderAssetsForInstagram() async {
    final cache = ref.read(storyImageCacheServiceProvider);
    final actId = widget.bundle.activity.id;

    if (_config.templateId == StoryTemplateId.photoOverlay) {
      // ADR-005: Template B exports 1080x1920 photo background + transparent RGBA sticker.
      final bgCapture = await captureBoundaryToPngBytes(_backgroundOnlyKey);
      final stickerCapture = await captureBoundaryToPngBytes(_stickerOnlyKey);
      final bgFile = await cache.savePng(
        pngBytes: bgCapture.bytes,
        activityId: actId,
        tag: 'photo_bg',
      );
      final stickerFile = await cache.savePng(
        pngBytes: stickerCapture.bytes,
        activityId: actId,
        tag: 'photo_sticker',
      );
      _lastDraftFile = bgFile;
      return (backgroundFile: bgFile, stickerFile: stickerFile);
    }

    // ADR-005: Template A & C export full 1080x1920 background asset.
    final fullFile = await _renderAndCacheComposite();
    return (backgroundFile: fullFile, stickerFile: null);
  }

  Future<void> _shareToInstagram() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      await WidgetsBinding.instance.endOfFrame;
      final shareService = ref.read(storyShareServiceProvider);
      final installed = await shareService.isInstagramInstalled();

      if (!installed) {
        final draftFile = await _renderAndCacheComposite();
        if (!mounted) return;
        setState(() => _isExporting = false);
        await _showInstagramNotFoundDialog(draftFile);
        return;
      }

      final assets = await _renderAssetsForInstagram();
      final bgHex = _config.templateId == StoryTemplateId.minimalist &&
              !_config.minimalistDark
          ? '#FFFFFF'
          : '#0A0A0A';

      final outcome = await shareService.shareToInstagramStory(
        backgroundPath: assets.backgroundFile.path,
        stickerPath: assets.stickerFile?.path,
        topColorHex: bgHex,
        bottomColorHex: bgHex,
      );

      if (!mounted) return;
      switch (outcome) {
        case InstagramShareOutcome.launched:
          _sharedCompleted = true;
          _showToast('Membuka Instagram Stories (1080×1920 PNG)...');
        case InstagramShareOutcome.notInstalled:
          final draftFile = await _renderAndCacheComposite();
          if (!mounted) return;
          await _showInstagramNotFoundDialog(draftFile);
        case InstagramShareOutcome.cancelled:
          _showToast(
            'Share dibatalkan • draft PNG tersimpan di cache sementara (24 jam).',
          );
        case InstagramShareOutcome.failed:
          _showToast('Gagal membuka Instagram. Coba Simpan ke Galeri.');
      }
    } on Object catch (error) {
      AppLogger.warn('StoryEditor', 'Share to Instagram failed', error);
      if (mounted) {
        _showToast('Gagal mengekspor kartu Story: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveCompositeToGallery({File? preRenderedFile}) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      await WidgetsBinding.instance.endOfFrame;
      final file = preRenderedFile ?? await _renderAndCacheComposite();
      final name =
          'fittrace_${widget.bundle.activity.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      await ref.read(storyShareServiceProvider).saveToGallery(
            filePath: file.path,
            displayName: name,
          );
      _sharedCompleted = true;
      if (!mounted) return;
      _showToast('Tersimpan ke Galeri (Pictures/FitTrace • 1080×1920 PNG)');
    } on Object catch (error) {
      AppLogger.warn('StoryEditor', 'Save to gallery failed', error);
      if (mounted) {
        _showToast('Gagal menyimpan ke Galeri: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showInstagramNotFoundDialog(File draftFile) async {
    final saveChosen = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Instagram Tidak Ditemukan'),
        content: const Text(
          'Aplikasi Instagram tidak terpasang di perangkat ini. Simpan kartu 1080×1920 ke Galeri, lalu unggah manual ke Instagram Stories.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: const Text('Simpan ke Galeri'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (saveChosen == true) {
      await _saveCompositeToGallery(preRenderedFile: draftFile);
    } else {
      _showToast(
        'Draft Story tersimpan di cache sementara (hapus otomatis 24 jam).',
      );
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;
    final unitSystem = ref.watch(userPreferencesProvider).value?.unitSystem ?? 'metric';

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _lastDraftFile != null && !_sharedCompleted && mounted) {
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Draft PNG tersimpan di cache sementara (24 jam).',
                ),
              ),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Story Card 9:16'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Reset Posisi',
              icon: const Icon(Icons.center_focus_strong_outlined),
              onPressed: _resetTransform,
            ),
            IconButton(
              tooltip: 'Simpan ke Galeri',
              icon: const Icon(Icons.download_outlined),
              onPressed: _isExporting ? null : () => _saveCompositeToGallery(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isExporting ? null : _shareToInstagram,
                child: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bagikan IG'),
              ),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.hairlineBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: StoryCardCanvas(
                            bundle: widget.bundle,
                            config: _config,
                            fullCardKey: _fullCardKey,
                            backgroundOnlyKey: _backgroundOnlyKey,
                            stickerOnlyKey: _stickerOnlyKey,
                            unitSystem: unitSystem,
                            onStickerScaleStart: _handleScaleStart,
                            onStickerScaleUpdate: _handleScaleUpdate,
                            onStickerDoubleTap: _resetTransform,
                          ),
                        ),
                      ),
                      if (_config.templateId == StoryTemplateId.photoOverlay &&
                          _config.photoBytes == null)
                        OutlinedButton.icon(
                          onPressed: _pickGalleryPhoto,
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Pilih Foto Galeri'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _EditorControlDeck(
              activeTab: _activeToolbarTab,
              config: _config,
              hasHeartRate: widget.bundle.activity.avgHeartRate != null,
              presets: ref.watch(storyPresetsProvider).value ??
                  const <StoryPresetRecord>[],
              colors: colors,
              onTabSelected: (idx) => setState(() => _activeToolbarTab = idx),
              onConfigChanged: (next) => setState(() => _config = next),
              onPickPhoto: _pickGalleryPhoto,
              onResetTransform: _resetTransform,
              onSavePreset: _saveCurrentPreset,
              onApplyPreset: _applyPreset,
              onDeletePreset: (id) =>
                  ref.read(appDatabaseProvider).deleteStoryPreset(id),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorControlDeck extends StatelessWidget {
  const _EditorControlDeck({
    required this.activeTab,
    required this.config,
    required this.hasHeartRate,
    required this.presets,
    required this.colors,
    required this.onTabSelected,
    required this.onConfigChanged,
    required this.onPickPhoto,
    required this.onResetTransform,
    required this.onSavePreset,
    required this.onApplyPreset,
    required this.onDeletePreset,
  });

  final int activeTab;
  final StoryEditorConfig config;
  final bool hasHeartRate;
  final List<StoryPresetRecord> presets;
  final FitTraceColors colors;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<StoryEditorConfig> onConfigChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onResetTransform;
  final VoidCallback onSavePreset;
  final ValueChanged<StoryPresetRecord> onApplyPreset;
  final ValueChanged<int> onDeletePreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.hairlineBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<int>>[
                  ButtonSegment(value: 0, label: Text('Template')),
                  ButtonSegment(value: 1, label: Text('Metrik')),
                  ButtonSegment(value: 2, label: Text('Gaya')),
                ],
                selected: <int>{activeTab},
                onSelectionChanged: (sel) => onTabSelected(sel.first),
              ),
              const SizedBox(height: 12),
              if (activeTab == 0) _buildTemplatePanel(),
              if (activeTab == 1) _buildMetricsPanel(),
              if (activeTab == 2) _buildStylePanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StoryTemplateId.values.map((template) {
            return ChoiceChip(
              label: Text(template.label),
              selected: config.templateId == template,
              onSelected: (_) => onConfigChanged(
                config.copyWith(templateId: template),
              ),
            );
          }).toList(growable: false),
        ),
        if (config.templateId == StoryTemplateId.photoOverlay) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPickPhoto,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(
              config.photoBytes == null
                  ? 'Pilih Foto Galeri'
                  : 'Ganti Foto Galeri',
            ),
          ),
        ],
        if (config.templateId == StoryTemplateId.minimalist) ...<Widget>[
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<bool>>[
              ButtonSegment(value: true, label: Text('Hitam Pekat')),
              ButtonSegment(value: false, label: Text('Putih Bersih')),
            ],
            selected: <bool>{config.minimalistDark},
            onSelectionChanged: (sel) => onConfigChanged(
              config.copyWith(minimalistDark: sel.first),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Text(
              'PRESET KUSTOM (M4-09)',
              style: AppTypography.metricLabel(colors.textSecondary),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onSavePreset,
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: const Text('Simpan Preset'),
            ),
          ],
        ),
        if (presets.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: presets
                .map(
                  (preset) => InputChip(
                    label: Text(preset.name),
                    onPressed: () => onApplyPreset(preset),
                    onDeleted: () => onDeletePreset(preset.id),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsPanel() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilterChip(
          label: const Text('Jarak'),
          selected: config.showDistance,
          onSelected: (v) => onConfigChanged(config.copyWith(showDistance: v)),
        ),
        FilterChip(
          label: const Text('Pace'),
          selected: config.showPace,
          onSelected: (v) => onConfigChanged(config.copyWith(showPace: v)),
        ),
        FilterChip(
          label: const Text('Moving Time'),
          selected: config.showMovingTime,
          onSelected: (v) =>
              onConfigChanged(config.copyWith(showMovingTime: v)),
        ),
        FilterChip(
          label: Text(hasHeartRate ? 'Avg HR' : 'Avg HR (—)'),
          selected: config.showAvgHr && hasHeartRate,
          onSelected: hasHeartRate
              ? (v) => onConfigChanged(config.copyWith(showAvgHr: v))
              : null,
        ),
        FilterChip(
          label: const Text('Elevasi'),
          selected: config.showElevation,
          onSelected: (v) =>
              onConfigChanged(config.copyWith(showElevation: v)),
        ),
        FilterChip(
          label: const Text('Tanggal'),
          selected: config.showDate,
          onSelected: (v) => onConfigChanged(config.copyWith(showDate: v)),
        ),
        FilterChip(
          label: const Text('Judul'),
          selected: config.showTitle,
          onSelected: (v) => onConfigChanged(config.copyWith(showTitle: v)),
        ),
        FilterChip(
          label: const Text('Watermark'),
          selected: config.showWatermark,
          onSelected: (v) =>
              onConfigChanged(config.copyWith(showWatermark: v)),
        ),
      ],
    );
  }

  Widget _buildStylePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'BOBOT FONT & PERATAAN',
          style: AppTypography.metricLabel(colors.textSecondary),
        ),
        const SizedBox(height: 8),
        SegmentedButton<StoryFontWeightOption>(
          showSelectedIcon: false,
          segments: StoryFontWeightOption.values
              .map(
                (w) => ButtonSegment<StoryFontWeightOption>(
                  value: w,
                  label: Text(w.label),
                ),
              )
              .toList(growable: false),
          selected: <StoryFontWeightOption>{config.fontWeight},
          onSelectionChanged: (sel) => onConfigChanged(
            config.copyWith(fontWeight: sel.first),
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<StoryTextAlignment>(
          showSelectedIcon: false,
          segments: StoryTextAlignment.values
              .map(
                (a) => ButtonSegment<StoryTextAlignment>(
                  value: a,
                  label: Text(a.label),
                ),
              )
              .toList(growable: false),
          selected: <StoryTextAlignment>{config.alignment},
          onSelectionChanged: (sel) => onConfigChanged(
            config.copyWith(alignment: sel.first),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            FilterChip(
              label: const Text('Rotasi Bebas'),
              selected: config.rotationEnabled,
              onSelected: (v) => onConfigChanged(
                config.copyWith(
                  rotationEnabled: v,
                  stickerRotationRad: v ? config.stickerRotationRad : 0.0,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onResetTransform,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Transform'),
            ),
          ],
        ),
      ],
    );
  }
}

