import 'package:flutter/material.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Monochrome bottom sheet for filtering feed by date range, sport type,
/// and activity source (PRD M3-02).
class FeedFilterSheet extends StatefulWidget {
  const FeedFilterSheet({
    super.key,
    required this.initialFilter,
  });

  final ActivityFeedFilter initialFilter;

  @override
  State<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<FeedFilterSheet> {
  late int? _sportCode = widget.initialFilter.sportTypeCode;
  late String? _sourceKey = widget.initialFilter.sourceKey;
  late DateTime? _startUtc = widget.initialFilter.startDateUtc;
  late DateTime? _endUtc = widget.initialFilter.endDateUtc;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'FILTER AKTIVITAS',
                  style: AppTypography.metricLabel(colors.textSecondary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _sportCode = null;
                      _sourceKey = null;
                      _startUtc = null;
                      _endUtc = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Rentang Tanggal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _startUtc == null && _endUtc == null,
                  onSelected: (_) => setState(() {
                    _startUtc = null;
                    _endUtc = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('7 Hari'),
                  selected: _isPresetDays(7),
                  onSelected: (_) => _applyPresetDays(7),
                ),
                ChoiceChip(
                  label: const Text('30 Hari'),
                  selected: _isPresetDays(30),
                  onSelected: (_) => _applyPresetDays(30),
                ),
                ActionChip(
                  label: Text(
                    (_startUtc != null && _endUtc != null && !_isPresetDays(7) && !_isPresetDays(30))
                        ? '${_fmtShort(_startUtc!)} – ${_fmtShort(_endUtc!)}'
                        : 'Pilih Tanggal',
                  ),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (range != null) {
                      setState(() {
                        _startUtc = DateTime(
                          range.start.year,
                          range.start.month,
                          range.start.day,
                        ).toUtc();
                        _endUtc = DateTime(
                          range.end.year,
                          range.end.month,
                          range.end.day,
                          23,
                          59,
                          59,
                        ).toUtc();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Jenis Aktivitas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _sportCode == null,
                  onSelected: (_) => setState(() => _sportCode = null),
                ),
                for (final sport in SportType.values)
                  ChoiceChip(
                    label: Text(sport.label),
                    selected: _sportCode == sport.code,
                    onSelected: (_) => setState(() => _sportCode = sport.code),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sumber Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _sourceKey == null,
                  onSelected: (_) => setState(() => _sourceKey = null),
                ),
                ChoiceChip(
                  label: const Text('Garmin Sync'),
                  selected: _sourceKey == ActivitySource.garminSync.storageKey,
                  onSelected: (_) => setState(
                    () => _sourceKey = ActivitySource.garminSync.storageKey,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Import Manual'),
                  selected:
                      _sourceKey == ActivitySource.manualImport.storageKey,
                  onSelected: (_) => setState(
                    () => _sourceKey = ActivitySource.manualImport.storageKey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  ActivityFeedFilter(
                    startDateUtc: _startUtc,
                    endDateUtc: _endUtc,
                    sportTypeCode: _sportCode,
                    sourceKey: _sourceKey,
                  ),
                );
              },
              child: const Text('Terapkan Filter'),
            ),
          ],
        ),
        ),
      ),
    );
  }

  bool _isPresetDays(int days) {
    if (_startUtc == null || _endUtc != null) return false;
    final expected = DateTime.now().toUtc().subtract(Duration(days: days));
    return (_startUtc!.difference(expected).inHours).abs() <= 24;
  }

  void _applyPresetDays(int days) {
    setState(() {
      _startUtc = DateTime.now().toUtc().subtract(Duration(days: days));
      _endUtc = null;
    });
  }

  String _fmtShort(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day}/${l.month}';
  }
}

