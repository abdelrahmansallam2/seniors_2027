import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/seniors_directory/data/seniors_api_service.dart';
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
  final _api = SeniorsApiService(ApiClient());
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 9;

  List<SeniorStudent> _allSeniors = [];
  List<SeniorStudent> _filteredSeniors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getUsers();
      final data = response.data;
      if (!mounted) return;
      final seniors = _parseSeniors(data);
      setState(() {
        _allSeniors = seniors;
        _applyFilter();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<SeniorStudent> _parseSeniors(dynamic data) {
    if (data is List) {
      return data
          .map((item) => SeniorStudent.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map((item) => SeniorStudent.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _currentPage = 0;
      if (query.isEmpty) {
        _filteredSeniors = List.of(_allSeniors);
      } else {
        _filteredSeniors = _allSeniors.where((senior) {
          return senior.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RetroGridBackground(
      child: SingleChildScrollView(
        key: const PageStorageKey('directory_scroll'),
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SeniorsSearchBar(controller: _searchController),
            const SizedBox(height: 32),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Text(
            'Loading...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const Text(
                'Could not load seniors.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 100,
                child: RetroButton(
                  label: 'Retry',
                  height: 36,
                  onPressed: _loadData,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_allSeniors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: AppColors.muted),
              SizedBox(height: 16),
              Text(
                'No seniors yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'The directory will populate once users are added.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildGrid();
  }

  Widget _buildGrid() {
    final totalPages = (_filteredSeniors.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredSeniors.length);
    final pageSeniors = _filteredSeniors.sublist(start, end);

    if (_filteredSeniors.isEmpty) {
      return const SeniorsEmptyState();
    }

    return Column(
      children: [
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
    );
  }
}
