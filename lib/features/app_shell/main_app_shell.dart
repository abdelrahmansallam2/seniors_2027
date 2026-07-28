import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seniors_27/features/dashboard/dashboard_screen.dart';
import 'package:seniors_27/features/leaderboard/leaderboard_screen.dart';
import 'package:seniors_27/features/memoryboard/memoryboard_screen.dart';
import 'package:seniors_27/features/notes/notes_open_book_screen.dart';
import 'package:seniors_27/features/profile/profile_screen.dart';
import 'package:seniors_27/features/seniors_directory/seniors_directory_screen.dart';
import 'package:seniors_27/shared/widgets/retro_bottom_nav.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  late int _currentIndex;
  bool _notesOpen = false;
  final List<int> _tabHistory = [];
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  void _selectTab(int index) {
    if (index == _currentIndex && !_notesOpen) return;
    setState(() {
      if (_currentIndex != index) {
        _tabHistory.add(_currentIndex);
      }
      _currentIndex = index;
      _notesOpen = false;
    });
  }

  void _openNotes() {
    setState(() {
      _tabHistory.add(_currentIndex);
      _currentIndex = 4;
      _notesOpen = true;
    });
  }

  void _closeNotes() {
    setState(() {
      _notesOpen = false;
    });
  }

  bool _handleBack() {
    if (_notesOpen) {
      _closeNotes();
      return false;
    }

    if (_tabHistory.isNotEmpty) {
      final previous = _tabHistory.removeLast();
      setState(() {
        _currentIndex = previous;
      });
      return false;
    }

    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
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

  Widget _selectedScreen() {
    if (_notesOpen) {
      return NotesOpenBookScreen(
        key: const ValueKey('notes'),
        onBackToProfile: _closeNotes,
        openedFromProfile: true,
      );
    }

    return switch (_currentIndex) {
      0 => DashboardScreen(
        key: const ValueKey('dashboard'),
        onOpenNotes: _openNotes,
      ),
      1 => const SeniorsDirectoryScreen(key: ValueKey('seniors')),
      2 => const MemoryboardScreen(key: ValueKey('memory')),
      3 => const LeaderboardScreen(key: ValueKey('board')),
      _ => ProfileScreen(
        key: const ValueKey('profile'),
        onOpenNotes: _openNotes,
      ),
    };
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 290),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.025, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _selectedScreen(),
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
