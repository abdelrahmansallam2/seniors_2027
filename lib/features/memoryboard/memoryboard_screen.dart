import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/memoryboard/mock_memories.dart';
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
  int _currentPage = 0;
  static const int _pageSize = 12;

  @override
  Widget build(BuildContext context) {
    final totalPages = (mockMemories.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, mockMemories.length);
    final pageMemories = mockMemories.sublist(start, end);

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
              onPressed: () => AddMemorySheet.show(context),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
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
                  // Randomized rotation for scrapbook feel
                  final rotation =
                      (index % 2 == 0 ? -1.5 : 1.5) * math.pi / 180;
                  return _PolaroidCard(
                    memory: pageMemories[index],
                    rotation: rotation,
                  );
                },
              ),
            ),
          ),
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
          // Photo/Placeholder behind the frame
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 22),
              child: Container(
                decoration: BoxDecoration(color: _getPastelColor(memory.id)),
              ),
            ),
          ),
          // Polaroid Frame Asset
          Image.asset(AppAssets.polaroidFrame, fit: BoxFit.fill),
          // Name and Date at bottom
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
