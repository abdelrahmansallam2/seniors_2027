import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/dashboard/models/event.dart';

String _formatMonth(DateTime? date) {
  if (date == null) return 'TBA';
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return months[date.month - 1];
}

String _formatDay(DateTime? date) {
  if (date == null) return '';
  return date.day.toString().padLeft(2, '0');
}

String _formatReadableDate(DateTime? date) {
  if (date == null) return 'TBA';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class EventCard extends StatelessWidget {
  const EventCard({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        event.photoUrl != null && event.photoUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orange,
                border: Border.all(color: AppColors.ink, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _formatMonth(event.eventDate),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    _formatDay(event.eventDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPhoto) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 180),
                        color: Colors.black,
                        child: Image.network(
                          event.photoUrl!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 100,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              height: 80,
                              child: Center(
                                child: Text(
                                  'Could not load image',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashedLinePainter(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatReadableDate(event.eventDate),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.details != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.details!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                  if (event.createdByUsername != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: AppColors.ink.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.person,
                            size: 7,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.createdByUsername!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
