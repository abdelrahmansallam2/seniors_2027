import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_text_field.dart';

class SeniorsSearchBar extends StatelessWidget {
  const SeniorsSearchBar({required this.controller, this.onChanged, super.key});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: RetroTextField(
            controller: controller,
            hintText: 'Search seniors...',
            onChanged: onChanged,
          ),
        ),
        const Positioned(
          right: 14,
          top: 14,
          child: Icon(Icons.search, color: AppColors.ink, size: 22),
        ),
      ],
    );
  }
}
