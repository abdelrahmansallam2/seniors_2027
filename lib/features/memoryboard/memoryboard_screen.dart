import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_api_service.dart';
import 'package:seniors_27/features/memoryboard/memory_model.dart';
import 'package:seniors_27/shared/widgets/add_memory_sheet.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class MemoryboardScreen extends StatefulWidget {
  const MemoryboardScreen({
    this.registerRefresh,
    this.onRefreshSuccess,
    super.key,
  });

  final void Function(Future<void> Function({bool force}) refresh)?
  registerRefresh;
  final VoidCallback? onRefreshSuccess;

  @override
  State<MemoryboardScreen> createState() => _MemoryboardScreenState();
}

class _MemoryboardScreenState extends State<MemoryboardScreen> {
  final _api = MemoryboardApiService(ApiClient());
  int _currentPage = 0;
  static const int _pageSize = 12;

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
    try {
      final response = await _api.getPhotos();
      final data = response.data;
      if (!mounted) return;
      final parsed = _parseMemories(data);
      appDebugLog('[Memoryboard] response count=${parsed.length}');
      final totalPages = (parsed.length / _pageSize).ceil();
      setState(() {
        _memories = parsed;
        if (_currentPage >= totalPages) {
          _currentPage = math.max(0, totalPages - 1);
        }
        _isLoading = false;
        _isFetching = false;
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
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _memories.length);
    final pageMemories = _memories.sublist(start, end);

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
            _buildBoard(pageMemories),
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
                          ? () => setState(() => _currentPage--)
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
                          ? () => setState(() => _currentPage++)
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

  Widget _buildBoard(List<Memory> pageMemories) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pageMemories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final memory = pageMemories[index];
            final rotation = (index % 2 == 0 ? -1.5 : 1.5) * math.pi / 180;
            final key = memory.id.isNotEmpty
                ? ValueKey<String>('memory_${memory.id}')
                : ValueKey<String>(
                    'memory_${memory.id}_${memory.imageUrl ?? ''}',
                  );
            return GestureDetector(
              key: key,
              onTap: () => _showImagePreview(memory),
              child: _PolaroidCard(memory: memory, rotation: rotation),
            );
          },
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

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final previewCacheWidth = (500 * dpr).round().clamp(500, 1600);
    final previewCacheHeight = (420 * dpr).round().clamp(420, 1600);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => BackdropFilter(
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
                            child: Image.network(
                              memory.imageUrl!,
                              fit: BoxFit.contain,
                              cacheWidth: previewCacheWidth,
                              cacheHeight: previewCacheHeight,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, _, _) => Container(
                                height: 200,
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

class _PolaroidCard extends StatelessWidget {
  const _PolaroidCard({required this.memory, required this.rotation});

  final Memory memory;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.ink, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: _buildPhotoContent(context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        memory.name,
                        style: const TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        memory.date,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -3,
            left: 16,
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.yellowWarm.withValues(alpha: 0.7),
                border: Border.all(color: AppColors.ink, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent(BuildContext context) {
    if (memory.imageUrl != null && memory.imageUrl!.isNotEmpty) {
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final cacheWidth = (90 * dpr).round().clamp(90, 360);
      final cacheHeight = (90 * dpr).round().clamp(90, 360);
      return Image.network(
        memory.imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(color: _getPastelColor(memory.id)),
    );
  }

  Color _getPastelColor(String id) {
    final colors = [
      AppColors.cyan,
      AppColors.green,
      AppColors.pink,
      AppColors.yellowWarm,
      AppColors.paper,
    ];
    final index = id.hashCode % colors.length;
    return colors[index];
  }
}
