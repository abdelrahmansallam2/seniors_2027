import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/seniors_directory/data/seniors_api_service.dart';
import 'package:seniors_27/features/seniors_directory/models/senior_student.dart';
import 'package:seniors_27/features/seniors_directory/widgets/senior_card.dart';
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

  List<SeniorStudent> _allSeniors = [];
  bool _isLoading = true;
  String? _error;
  int _requestId = 0;
  String? _activeRequestKey;

  int _pageNumber = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  static const int _pageSize = 9;

  Timer? _debounce;
  String _currentSearchQuery = '';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSeniors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSeniors({int? page, String? search}) async {
    final targetPage = page ?? 1;
    final normalizedSearch = search?.trim() ?? '';
    final requestKey = '$targetPage|$normalizedSearch';

    if (_activeRequestKey == requestKey) return;
    _activeRequestKey = requestKey;

    setState(() {
      _isLoading = true;
      _error = null;
      if (normalizedSearch != _currentSearchQuery) {
        _isSearchMode = normalizedSearch.isNotEmpty;
        _currentSearchQuery = normalizedSearch;
      }
    });

    final requestId = ++_requestId;

    try {
      final response = await _api.getUsers(
        pageNumber: targetPage,
        pageSize: _pageSize,
        search: normalizedSearch.isNotEmpty ? normalizedSearch : null,
      );

      if (!mounted || requestId != _requestId) return;

      final data = response.data;
      final seniors = _parseSeniors(data);
      _parsePaginationMeta(data);

      setState(() {
        _allSeniors = seniors;
        _pageNumber = targetPage;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.statusCode == 429
            ? 'Too many requests. Please wait a moment and try again.'
            : e.message;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
        _activeRequestKey = null;
      }
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

  void _parsePaginationMeta(dynamic data) {
    if (data is Map) {
      _totalPages = (data['totalPages'] as num?)?.toInt() ?? _totalPages;
      _hasNextPage = data['hasNextPage'] as bool? ?? false;
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text;
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final trimmed = query.trim();
      if (trimmed == _currentSearchQuery) return;
      _loadSeniors(search: trimmed);
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
    if (_isLoading && _allSeniors.isEmpty && _error == null) {
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

    if (_error != null && _allSeniors.isEmpty) {
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
                  onPressed: _isLoading ? null : () => _loadSeniors(),
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
      if (_isSearchMode) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Column(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 48,
                  color: AppColors.muted,
                ),
                SizedBox(height: 16),
                Text(
                  'No seniors found.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Try another search or filter.',
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
    final showPagination = _totalPages > 1;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allSeniors.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            return SeniorCard(senior: _allSeniors[index]);
          },
        ),
        const SizedBox(height: 32),
        if (showPagination)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                child: RetroButton(
                  label: 'PREV',
                  height: 36,
                  onPressed: _pageNumber > 1
                      ? () => _loadSeniors(
                          page: _pageNumber - 1,
                          search: _isSearchMode ? _currentSearchQuery : null,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'PAGE $_pageNumber / $_totalPages',
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
                  onPressed: _hasNextPage
                      ? () => _loadSeniors(
                          page: _pageNumber + 1,
                          search: _isSearchMode ? _currentSearchQuery : null,
                        )
                      : null,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
