import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/seniors_directory/data/mock_seniors.dart';
import 'package:seniors_27/features/seniors_directory/models/senior_student.dart';
import 'package:seniors_27/features/seniors_directory/widgets/senior_card.dart';
import 'package:seniors_27/features/seniors_directory/widgets/seniors_empty_state.dart';
import 'package:seniors_27/features/seniors_directory/widgets/seniors_search_bar.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class SeniorsDirectoryScreen extends StatefulWidget {
  const SeniorsDirectoryScreen({super.key});

  @override
  State<SeniorsDirectoryScreen> createState() => _SeniorsDirectoryScreenState();
}

class _SeniorsDirectoryScreenState extends State<SeniorsDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 9; // 3x3 grid
  List<SeniorStudent> _filteredSeniors = mockSeniors;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _currentPage = 0;
      final query = _searchController.text.toLowerCase();
      _filteredSeniors = mockSeniors.where((senior) {
        return senior.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredSeniors.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredSeniors.length);
    final pageSeniors = _filteredSeniors.sublist(start, end);

    return RetroGridBackground(
      child: SingleChildScrollView(
        key: const PageStorageKey('directory_scroll'),
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Stack(
              clipBehavior: Clip.none,
              children: [
                MainPageHeader(
                  title: 'Seniors',
                  subtitle: 'Find your classmates.',
                ),
                Positioned(
                  top: 2,
                  right: 4,
                  child: RetroSticker(
                    color: AppColors.magenta,
                    width: 58,
                    height: 20,
                    angle: 0.12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Search Bar
            SeniorsSearchBar(controller: _searchController),
            const SizedBox(height: 32),

            // Seniors Grid (3 columns)
            if (_filteredSeniors.isEmpty)
              const SeniorsEmptyState()
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageSeniors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  return SeniorCard(senior: pageSeniors[index]);
                },
              ),
              const SizedBox(height: 32),

              // Pagination
              if (totalPages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      child: RetroButton(
                        label: 'PREV',
                        height: 36,
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'PAGE ${_currentPage + 1} / $totalPages',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: RetroButton(
                        label: 'NEXT',
                        height: 36,
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
