import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_api_service.dart';
import 'package:seniors_27/features/memoryboard/memory_model.dart';
import 'package:seniors_27/shared/widgets/add_memory_sheet.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class MemoryboardScreen extends StatefulWidget {
  const MemoryboardScreen({super.key});

  @override
  State<MemoryboardScreen> createState() => _MemoryboardScreenState();
}

class _MemoryboardScreenState extends State<MemoryboardScreen> {
  final _api = MemoryboardApiService(ApiClient());
  int _currentPage = 0;
  static const int _pageSize = 12;

  List<Memory> _memories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getPhotos();
      final data = response.data;
      if (!mounted) return;
      setState(() {
        _memories = _parseMemories(data);
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

  List<Memory> _parseMemories(dynamic data) {
    if (data is List) {
      return data
          .map((item) => Memory.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> _handleAddMemory(String filePath, String? description) async {
    await _api.uploadPhoto(filePath: filePath, description: description);
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_memories.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _memories.length);
    final pageMemories = _memories.sublist(start, end);

    return SingleChildScrollView(
      key: const PageStorageKey('memoryboard_scroll'),
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
            final rotation = (index % 2 == 0 ? -1.5 : 1.5) * math.pi / 180;
            return _PolaroidCard(
              memory: pageMemories[index],
              rotation: rotation,
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
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 22),
              child: Container(
                decoration: BoxDecoration(color: _getPastelColor(memory.id)),
              ),
            ),
          ),
          Image.asset(AppAssets.polaroidFrame, fit: BoxFit.fill),
          Positioned(
            bottom: 8,
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
