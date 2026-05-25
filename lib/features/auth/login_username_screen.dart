import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/features/auth/login_gender_screen.dart';
import 'package:seniors_27/features/auth/widgets/login_progress.dart';
import 'package:seniors_27/features/auth/widgets/retro_validation_message.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';
import 'package:seniors_27/shared/widgets/retro_text_field.dart';

class LoginUsernameScreen extends StatefulWidget {
  const LoginUsernameScreen({super.key});

  @override
  State<LoginUsernameScreen> createState() => _LoginUsernameScreenState();
}

class _LoginUsernameScreenState extends State<LoginUsernameScreen> {
  final _usernameController = TextEditingController();
  bool _hasInteracted = false;
  bool _hasAttemptedSubmit = false;

  String? get _usernameError {
    if (!_hasInteracted && !_hasAttemptedSubmit) {
      return null;
    }
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return 'Username is required.';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    return null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _hasAttemptedSubmit = true);
    if (_usernameError != null) {
      return;
    }
    Navigator.of(
      context,
    ).push(RetroPageRoute<void>(builder: (_) => const LoginGenderScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RetroGridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: RetroCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              shadowOffset: const Offset(8, 12),
              borderRadius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOGIN',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome back. Move step by step.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const LoginProgress(step: 3),
                  const SizedBox(height: 17),
                  RetroShadowContainer(
                    height: 470,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    shadowOffset: const Offset(7, 8),
                    borderRadius: 12,
                    backgroundColor: AppColors.paper,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'USERNAME',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pick your display name for the\nyearbook.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 17),
                        const Text(
                          'USERNAME',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        RetroTextField(
                          controller: _usernameController,
                          hintText: 'ENTER USERNAME',
                          onChanged: (_) {
                            setState(() => _hasInteracted = true);
                          },
                        ),
                        if (_usernameError case final error?)
                          RetroValidationMessage(message: error),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: RetroButton(
                                label: 'Back',
                                height: 56,
                                onPressed: () => Navigator.of(context).pop(),
                                textStyle: const TextStyle(
                                  color: AppColors.ink,
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: RetroButton(
                                label: 'Next',
                                height: 56,
                                onPressed: _next,
                                textStyle: const TextStyle(
                                  color: AppColors.ink,
                                  fontFamily: 'monospace',
                                  fontSize: 16,
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
