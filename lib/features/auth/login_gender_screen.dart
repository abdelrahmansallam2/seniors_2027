import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/features/auth/widgets/login_progress.dart';
import 'package:seniors_27/features/auth/widgets/retro_validation_message.dart';
import 'package:seniors_27/features/app_shell/main_app_shell.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_pressable.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';

enum _Gender { male, female }

class LoginGenderScreen extends StatefulWidget {
  const LoginGenderScreen({super.key});

  @override
  State<LoginGenderScreen> createState() => _LoginGenderScreenState();
}

class _LoginGenderScreenState extends State<LoginGenderScreen> {
  _Gender? _selectedGender;
  bool _hasAttemptedSubmit = false;

  void _selectGender(_Gender gender) {
    setState(() {
      _selectedGender = gender;
      _hasAttemptedSubmit = false;
    });
  }

  void _continueToDashboard() {
    if (_selectedGender == null) {
      setState(() => _hasAttemptedSubmit = true);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      RetroPageRoute<void>(builder: (_) => const MainAppShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RetroGridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
            child: RetroCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              shadowOffset: const Offset(7, 10),
              borderRadius: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOGIN', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 7),
                  const Text(
                    'Welcome back. Move step by step.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LoginProgress(step: 4),
                  const SizedBox(height: 20),
                  RetroShadowContainer(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    borderRadius: 9,
                    shadowOffset: const Offset(5, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GENDER',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_hasAttemptedSubmit && _selectedGender == null)
                          const RetroValidationMessage(
                            message: 'Select a gender to continue.',
                          ),
                        const SizedBox(height: 24),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.82,
                            child: _GenderOption(
                              optionKey: const Key('male_gender_option'),
                              label: 'MALE',
                              color: const Color(0xFF356BEF),
                              selectedColor: AppColors.cyan,
                              selected: _selectedGender == _Gender.male,
                              onTap: () => _selectGender(_Gender.male),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.82,
                            child: _GenderOption(
                              optionKey: const Key('female_gender_option'),
                              label: 'FEMALE',
                              color: const Color(0xFFE14E55),
                              selectedColor: AppColors.pink,
                              selected: _selectedGender == _Gender.female,
                              onTap: () => _selectGender(_Gender.female),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: RetroButton(
                                label: 'Back',
                                height: 48,
                                onPressed: () => Navigator.of(context).pop(),
                                textStyle: const TextStyle(
                                  color: AppColors.ink,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: RetroButton(
                                label: 'Next',
                                height: 48,
                                onPressed: _continueToDashboard,
                                textStyle: const TextStyle(
                                  color: AppColors.ink,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.optionKey,
    required this.label,
    required this.color,
    required this.selectedColor,
    required this.selected,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final Color color;
  final Color selectedColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RetroPressable(
      onTap: onTap,
      builder: (context, isHovered, isPressed) {
        final isLifted = isHovered && !isPressed;
        final offset = isPressed
            ? const Offset(4, 6)
            : isLifted
            ? const Offset(0, -2)
            : Offset.zero;
        final shadowOffset = isLifted ? const Offset(6, 9) : const Offset(4, 6);
        return AnimatedScale(
          scale: isPressed ? 0.99 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            key: optionKey,
            height: 126,
            duration: Duration(milliseconds: isPressed ? 100 : 150),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
            decoration: BoxDecoration(
              color: selected ? selectedColor : AppColors.paper,
              border: Border.all(color: AppColors.ink, width: 3),
              borderRadius: BorderRadius.circular(7),
              boxShadow: isPressed
                  ? const []
                  : [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: shadowOffset,
                        blurRadius: 0,
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  painter: _GenderIconPainter(color),
                  size: const Size(46, 62),
                ),
                const SizedBox(height: 9),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GenderIconPainter extends CustomPainter {
  _GenderIconPainter(this.accentColor);

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 38;
    final fill = Paint()..color = AppColors.paper;
    final outline = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    final accent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;

    final head = Rect.fromCircle(
      center: Offset(size.width / 2, 8 * scale),
      radius: 7 * scale,
    );
    canvas.drawOval(head, fill);
    canvas.drawOval(head, outline);

    final body = Path()
      ..moveTo(12 * scale, 17 * scale)
      ..lineTo(26 * scale, 17 * scale)
      ..lineTo(27 * scale, 38 * scale)
      ..lineTo(23 * scale, 38 * scale)
      ..lineTo(23 * scale, 51 * scale)
      ..lineTo(16 * scale, 51 * scale)
      ..lineTo(16 * scale, 38 * scale)
      ..lineTo(11 * scale, 38 * scale)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, outline);

    final accentPath = Path()
      ..moveTo(27 * scale, 18 * scale)
      ..lineTo(27 * scale, 39 * scale)
      ..lineTo(23 * scale, 39 * scale)
      ..lineTo(23 * scale, 51 * scale);
    canvas.drawPath(accentPath, accent);
  }

  @override
  bool shouldRepaint(_GenderIconPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
