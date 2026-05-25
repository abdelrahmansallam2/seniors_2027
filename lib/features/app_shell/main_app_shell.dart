import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _notesOpen = false;
    });
  }

  void _openNotes() {
    setState(() {
      _currentIndex = 4;
      _notesOpen = true;
    });
  }

  Widget _selectedScreen() {
    if (_notesOpen) {
      return const NotesOpenBookScreen(key: ValueKey('notes'));
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
    return Scaffold(
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
    );
  }
}
