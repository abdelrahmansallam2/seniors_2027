import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class DashboardUploadPlaceholder extends StatelessWidget {
  const DashboardUploadPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background "stack" layers
          Transform.rotate(
            angle: -0.05,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.03,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          // Main Polaroid area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            decoration: BoxDecoration(
              color: AppColors.white,
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
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 42, color: AppColors.ink),
                        SizedBox(height: 12),
                        Text(
                          "ADD / UPLOAD TODAY'S MEMORY",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'click to open memories',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
