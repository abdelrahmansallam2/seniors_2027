import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/features/dashboard/dashboard_screen.dart';
import 'package:seniors_27/features/leaderboard/leaderboard_screen.dart';
import 'package:seniors_27/features/memoryboard/memoryboard_screen.dart';
import 'package:seniors_27/features/notes/notes_open_book_screen.dart';
import 'package:seniors_27/features/profile/profile_screen.dart';
import 'package:seniors_27/features/seniors_directory/seniors_directory_screen.dart';
import 'package:seniors_27/shared/widgets/retro_bottom_nav.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({this.initialIndex = 0, this.screenBuilders, super.key});

  final int initialIndex;

  @visibleForTesting
  final List<Widget Function()>? screenBuilders;

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const Duration _resumeRefreshThreshold = Duration(seconds: 30);

  late int _currentIndex;
  late final List<Widget?> _screens;
  late final List<Widget Function()> _screenBuilders;
  late final AnimationController _tabTransition;
  double _tabDirection = 1;
  bool _notesOpen = false;
  final List<int> _tabHistory = [];
  DateTime? _lastBackPress;

  final Map<int, Future<void> Function({bool force})> _tabRefresh = {};
  final Map<int, DateTime> _lastSuccessfulRefresh = {};
  final Set<int> _refreshingTabs = {};

  @override
  void initState() {
    super.initState();
    assert(
      widget.screenBuilders == null || widget.screenBuilders!.length == 5,
      'MainAppShell requires exactly five screen builders.',
    );
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _tabTransition = AnimationController(
      vsync: this,
      duration: RetroMotion.tab,
      value: 1,
    );
    _screenBuilders =
        widget.screenBuilders ??
        [
          () => DashboardScreen(
            onOpenNotes: _openNotes,
            registerRefresh: (refresh) => _tabRefresh[0] = refresh,
            onRefreshSuccess: () => _recordRefreshSuccess(0),
          ),
          () => SeniorsDirectoryScreen(
            registerRefresh: (refresh) => _tabRefresh[1] = refresh,
            onRefreshSuccess: () => _recordRefreshSuccess(1),
          ),
          () => MemoryboardScreen(
            registerRefresh: (refresh) => _tabRefresh[2] = refresh,
            onRefreshSuccess: () => _recordRefreshSuccess(2),
          ),
          () => LeaderboardScreen(
            registerRefresh: (refresh) => _tabRefresh[3] = refresh,
            onRefreshSuccess: () => _recordRefreshSuccess(3),
          ),
          () => ProfileScreen(
            onOpenNotes: _openNotes,
            registerRefresh: (refresh) => _tabRefresh[4] = refresh,
            onRefreshSuccess: () => _recordRefreshSuccess(4),
          ),
        ];
    _screens = List<Widget?>.filled(5, null);
    _screens[0] = _screenBuilders[0]();
    if (_currentIndex != 0) _ensureScreenCreated(_currentIndex);
    if (kDebugMode) debugPrint('[MainAppShell] created tab index=0');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabTransition.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (RetroMotion.reduceMotion(context) && _tabTransition.isAnimating) {
      _tabTransition.value = 1;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshVisibleTabOnResume();
    }
  }

  void _recordRefreshSuccess(int index) {
    _lastSuccessfulRefresh[index] = DateTime.now();
  }

  void _refreshVisibleTabOnResume() {
    if (_notesOpen) return;
    final last = _lastSuccessfulRefresh[_currentIndex];
    final now = DateTime.now();
    if (last != null && now.difference(last) < _resumeRefreshThreshold) {
      return;
    }
    unawaited(_refreshTab(_currentIndex));
  }

  Future<void> _refreshTab(int index) async {
    final refresh = _tabRefresh[index];
    if (refresh == null || _refreshingTabs.contains(index)) return;
    _refreshingTabs.add(index);
    try {
      await refresh(force: true);
    } finally {
      _refreshingTabs.remove(index);
    }
  }

  void _ensureScreenCreated(int index) {
    if (_screens[index] != null) {
      if (kDebugMode) debugPrint('[MainAppShell] reused tab index=$index');
      return;
    }
    if (kDebugMode) debugPrint('[MainAppShell] created tab index=$index');
    _screens[index] = _screenBuilders[index]();
  }

  void _animateTabChange(int from, int to, {bool force = false}) {
    if (from == to && !force) return;
    _tabDirection = to > from ? 1 : -1;
    if (RetroMotion.reduceMotion(context)) {
      _tabTransition.value = 1;
      return;
    }
    _tabTransition.forward(from: 0);
  }

  void _selectTab(int index) {
    if (index == _currentIndex && !_notesOpen) {
      if (kDebugMode) {
        debugPrint(
          '[MainAppShell] re-tapped active tab, refreshing index=$index',
        );
      }
      unawaited(_refreshTab(index));
      return;
    }
    final previous = _currentIndex;
    final wasNotesOpen = _notesOpen;
    _ensureScreenCreated(index);
    setState(() {
      if (_currentIndex != index) {
        _tabHistory.add(_currentIndex);
      }
      _currentIndex = index;
      _notesOpen = false;
    });
    _animateTabChange(previous, index, force: wasNotesOpen);
  }

  void _openNotes() {
    final previous = _currentIndex;
    setState(() {
      _tabHistory.add(_currentIndex);
      _currentIndex = 4;
      _notesOpen = true;
    });
    _animateTabChange(previous, 4, force: true);
  }

  void _closeNotes() {
    _ensureScreenCreated(_currentIndex);
    setState(() {
      _notesOpen = false;
    });
    _animateTabChange(_currentIndex, _currentIndex, force: true);
  }

  bool _handleBack() {
    if (_notesOpen) {
      _closeNotes();
      return false;
    }

    if (_tabHistory.isNotEmpty) {
      final previous = _tabHistory.removeLast();
      final from = _currentIndex;
      setState(() {
        _currentIndex = previous;
      });
      _animateTabChange(from, previous);
      return false;
    }

    if (_currentIndex != 0) {
      final from = _currentIndex;
      setState(() {
        _currentIndex = 0;
      });
      _animateTabChange(from, 0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return false;
    }

    _lastBackPress = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Press back again to exit',
          style: TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  Widget _buildTabStack() {
    return IndexedStack(
      index: _currentIndex,
      children: List.generate(
        _screens.length,
        (i) => TickerMode(
          key: ValueKey<String>('tab_ticker_$i'),
          enabled: !_notesOpen && i == _currentIndex,
          child: _screens[i] ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        body: RetroGridBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabTransition,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Offstage(offstage: _notesOpen, child: _buildTabStack()),
                        if (_notesOpen)
                          NotesOpenBookScreen(
                            onBackToProfile: _closeNotes,
                            openedFromProfile: true,
                          ),
                      ],
                    ),
                    builder: (context, child) {
                      final eased = Curves.easeOutCubic.transform(
                        _tabTransition.value,
                      );
                      final opacity =
                          RetroMotion.tabMinOpacity +
                          (1 - RetroMotion.tabMinOpacity) * eased;
                      final offset =
                          RetroMotion.tabOffset * _tabDirection * (1 - eased);
                      return Opacity(
                        key: const ValueKey<String>('tab_transition_opacity'),
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: RetroBottomNav(
                    currentIndex: _currentIndex,
                    onTap: _selectTab,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
