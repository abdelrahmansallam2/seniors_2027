import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/core/navigation/retro_overlay.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_api_service.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_image_cache.dart';
import 'package:seniors_27/features/memoryboard/memory_model.dart';
import 'package:seniors_27/features/memoryboard/widgets/memoryboard_collage.dart';
import 'package:seniors_27/shared/widgets/add_memory_sheet.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_image_reveal.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class MemoryboardScreen extends StatefulWidget {
  const MemoryboardScreen({
    this.registerRefresh,
    this.onRefreshSuccess,
    this.apiService,
    this.imageCache,
    super.key,
  });

  final void Function(Future<void> Function({bool force}) refresh)?
  registerRefresh;
  final VoidCallback? onRefreshSuccess;
  final MemoryboardApiService? apiService;
  final MemoryboardImageCache? imageCache;

  @override
  State<MemoryboardScreen> createState() => _MemoryboardScreenState();
}

class _MemoryboardScreenState extends State<MemoryboardScreen> {
  late final MemoryboardApiService _api =
      widget.apiService ?? MemoryboardApiService(ApiClient());
  int _currentPage = 0;
  int _settledPage = 0;
  static const int _pageSize = 12;
  final PageController _pageController = PageController(keepPage: false);
  late final MemoryboardImageCache _images =
      widget.imageCache ?? MemoryboardImageCache();

  List<Memory> _memories = [];
  bool _isLoading = true;
  bool _isFetching = false;
  String? _error;
  VoidCallback? _notifyRefreshSuccess;

  @override
  void initState() {
    super.initState();
    widget.registerRefresh?.call(refresh);
    _notifyRefreshSuccess = widget.onRefreshSuccess;
    _loadData();
  }

  Future<void> refresh({bool force = true}) {
    return _loadData(forceRefresh: force);
  }

  @override
  void dispose() {
    _images.cancelPrefetch();
    _pageController.dispose();
    super.dispose();
  }

  void _prefetchNextBoard(int page) {
    if (!mounted || page != _settledPage) return;
    final start = (page + 1) * _pageSize;
    if (start >= _memories.length) return;
    final end = math.min(start + _pageSize, _memories.length);
    unawaited(_images.prefetch(_memories.sublist(start, end)));
  }

  void _goToPage(int page) {
    final totalPages = (_memories.length / _pageSize).ceil();
    if (!_pageController.hasClients || page < 0 || page >= totalPages) return;
    if (RetroMotion.reduceMotion(context)) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: RetroMotion.pageForward,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (_isFetching) {
      appDebugLog('[Memoryboard] request blocked because already loading');
      return;
    }
    _isFetching = true;
    setState(() {
      if (!forceRefresh || _memories.isEmpty) {
        _isLoading = true;
      }
      _error = null;
    });
    appDebugLog('[Memoryboard] request started');
    final watch = Stopwatch()..start();
    try {
      final response = await _api.getPhotos();
      final data = response.data;
      if (!mounted) return;
      final parsed = _parseMemories(data);
      memoryboardTiming(
        'photoList count=${parsed.length} elapsedMs=${watch.elapsedMilliseconds}',
      );
      appDebugLog('[Memoryboard] response count=${parsed.length}');
      final totalPages = (parsed.length / _pageSize).ceil();
      setState(() {
        _memories = parsed;
        if (_currentPage >= totalPages) {
          _currentPage = math.max(0, totalPages - 1);
        }
        _settledPage = _currentPage;
        _isLoading = false;
        _isFetching = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        if ((_pageController.page ?? 0).round() != _currentPage) {
          _pageController.jumpToPage(_currentPage);
        }
      });
      _notifyRefreshSuccess?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      appDebugLog('[Memoryboard] request failed status=${e.statusCode}');
      setState(() {
        if (_memories.isEmpty) {
          _error = e.message;
        }
        _isLoading = false;
        _isFetching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_memories.isEmpty) {
          _error = 'Something went wrong. Please try again.';
        }
        _isLoading = false;
        _isFetching = false;
      });
    }
  }

  List<Memory> _parseMemories(dynamic data) {
    if (data is List) {
      return data
          .map((item) => Memory.fromJson(item as Map<String, dynamic>))
          .where((m) => m.status.trim().toLowerCase() == 'approved')
          .toList();
    }
    return [];
  }

  Future<void> _handleAddMemory(String filePath, String? description) async {
    final memory = await _api.uploadPhoto(filePath: filePath);
    if (!mounted) return;

    final status = memory.status.trim().toLowerCase();

    if (status == 'pending') {
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory submitted for admin approval.'),
          backgroundColor: AppColors.ink,
        ),
      );
    } else if (status == 'approved') {
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory added successfully.'),
          backgroundColor: AppColors.ink,
        ),
      );
      _loadData();
    } else if (status == 'rejected') {
      throw ApiException(message: 'Memory was rejected.');
    } else {
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory uploaded successfully.'),
          backgroundColor: AppColors.ink,
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_memories.length / _pageSize).ceil();

    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        key: const PageStorageKey('memoryboard_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Stack(
              clipBehavior: Clip.none,
              children: [
                MainPageHeader(
                  title: 'Memoryboard',
                  subtitle: 'Find your funniest shots and cozy moments.',
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
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: RetroButton(
                label: 'ADD MEMORY',
                height: 38,
                backgroundColor: AppColors.green,
                onPressed: () => AddMemorySheet.show(
                  context,
                  onMemorySubmitted: _handleAddMemory,
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildBoard(),
            const SizedBox(height: 28),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 85,
                    child: RetroButton(
                      label: 'PREV.',
                      height: 34,
                      shadowOffset: const Offset(3, 4),
                      onPressed: _currentPage > 0
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentPage + 1} / $totalPages',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 85,
                    child: RetroButton(
                      label: 'NEXT',
                      height: 34,
                      shadowOffset: const Offset(3, 4),
                      onPressed: _currentPage < totalPages - 1
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    if (_isLoading) {
      return _buildBoardContainer(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Text(
              'Loading memories...',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildBoardContainer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load memories.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
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
        ),
      );
    }

    if (_memories.isEmpty) {
      return _buildBoardContainer(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: Colors.white70,
                ),
                SizedBox(height: 16),
                Text(
                  'No memories yet.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Be the first to add a memory!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildBoardContainer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: MemoryboardCollage.heightForWidth(constraints.maxWidth),
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 && _settledPage != _currentPage) {
                  _images.cancelPrefetch();
                  setState(() => _settledPage = _currentPage);
                }
                return false;
              },
              child: PageView.builder(
                key: const ValueKey('memoryboard_pages'),
                controller: _pageController,
                itemCount: (_memories.length / _pageSize).ceil(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, page) {
                  final start = page * _pageSize;
                  final end = math.min(start + _pageSize, _memories.length);
                  return MemoryboardCollage(
                    key: ValueKey('memoryboard_page_$page'),
                    memories: _memories.sublist(start, end),
                    isActive: page == _settledPage,
                    onPhotoTap: _showImagePreview,
                    imageProviderFor: _images.imageFor,
                    onPhotosReady: () => _prefetchNextBoard(page),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEB5E3D),
        image: const DecorationImage(
          image: AssetImage(AppAssets.memoryboardBoardTexture),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(5, 5), blurRadius: 0),
        ],
      ),
      child: child,
    );
  }

  void _showImagePreview(Memory memory) {
    if (memory.imageUrl == null || memory.imageUrl!.isEmpty) return;

    showRetroOverlay(
      context: context,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      border: Border.all(color: AppColors.ink, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(6, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 420),
                            child: RetroImageReveal(
                              image: _images.imageFor(memory)!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              placeholder: const SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              errorBuilder: (_, _, _) => Container(
                                height: 200,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Failed to load image.',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (memory.name.isNotEmpty ||
                            memory.date.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          if (memory.name.isNotEmpty)
                            Text(
                              memory.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                          if (memory.name.isNotEmpty && memory.date.isNotEmpty)
                            const SizedBox(height: 2),
                          if (memory.date.isNotEmpty)
                            Text(
                              memory.date,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -12,
                    right: -12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.ink, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.ink,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'X',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
