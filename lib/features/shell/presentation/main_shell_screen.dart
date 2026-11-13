import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/presentation/feed_screen.dart';
import '../../garmin_sync/application/garmin_sync_providers.dart';
import '../../import/application/import_providers.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../story_share/application/story_share_providers.dart';

class _ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final shellTabIndexProvider = NotifierProvider<_ShellTabNotifier, int>(
  _ShellTabNotifier.new,
);

/// Main 3-tab monochrome navigation shell defined in PRD §6.3.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({
    super.key,
    this.triggerInitialSync = false,
  });

  final bool triggerInitialSync;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with WidgetsBindingObserver {
  StreamSubscription<List<String>>? _shareSubscription;

  static const List<Widget> _tabs = <Widget>[
    FeedScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initShareIntentHandling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(storyImageCacheServiceProvider).cleanupExpiredFiles());
      final syncController = ref.read(garminSyncControllerProvider.notifier);
      if (widget.triggerInitialSync) {
        syncController.syncNow();
      } else {
        syncController.maybeAutoSyncOnResume();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(garminSyncControllerProvider.notifier).maybeAutoSyncOnResume();
    }
  }

  Future<void> _initShareIntentHandling() async {
    final bridge = ref.read(androidShareIntentBridgeProvider);
    _shareSubscription = bridge.watchSharedFiles().listen(_handleSharedPaths);
    final initial = await bridge.getInitialSharedFiles();
    if (initial.isNotEmpty) {
      await _handleSharedPaths(initial);
    }
  }

  Future<void> _handleSharedPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    ref.read(shellTabIndexProvider.notifier).select(0);
    final summary = await ref
        .read(importControllerProvider.notifier)
        .importSharedFilePaths(paths);
    if (!mounted || summary == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Impor Share: ${summary.importedCount} baru • '
            '${summary.skippedCount} dilewati',
          ),
        ),
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) =>
            ref.read(shellTabIndexProvider.notifier).select(index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
