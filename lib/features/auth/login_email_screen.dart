import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/features/auth/login_otp_screen.dart';
import 'package:seniors_27/features/auth/widgets/login_progress.dart';
import 'package:seniors_27/features/auth/widgets/retro_validation_message.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';
import 'package:seniors_27/shared/widgets/retro_text_field.dart';

enum EmailAuthStatus {
  idle,
  loading,
  otpSent,
  pendingApproval,
  deletedOrInactive,
  rejected,
  error,
}

typedef EmailOtpRequester = Future<EmailAuthStatus> Function(String email);

Future<EmailAuthStatus> requestOtp(String email) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return EmailAuthStatus.otpSent;
}

class LoginEmailScreen extends StatefulWidget {
  const LoginEmailScreen({this.otpRequester = requestOtp, super.key});

  final EmailOtpRequester otpRequester;

  @override
  State<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final _emailController = TextEditingController();
  bool _hasInteracted = false;
  bool _hasAttemptedSubmit = false;
  EmailAuthStatus _status = EmailAuthStatus.idle;

  bool get _isLoading => _status == EmailAuthStatus.loading;

  String? get _emailError {
    if (!_hasInteracted && !_hasAttemptedSubmit) {
      return null;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? get _statusMessage {
    return switch (_status) {
      EmailAuthStatus.otpSent =>
        'OTP sent successfully. Please check your email.',
      EmailAuthStatus.pendingApproval =>
        'Your request is waiting for admin approval. Please try again after approval.',
      EmailAuthStatus.deletedOrInactive =>
        'This account request is no longer active. Please contact the admin or submit a new request.',
      EmailAuthStatus.rejected =>
        'Your request was rejected. Please contact the admin.',
      EmailAuthStatus.error => 'Something went wrong. Please try again.',
      EmailAuthStatus.idle || EmailAuthStatus.loading => null,
    };
  }

  Color get _statusColor {
    return switch (_status) {
      EmailAuthStatus.otpSent => AppColors.green,
      EmailAuthStatus.pendingApproval => AppColors.orange,
      EmailAuthStatus.deletedOrInactive ||
      EmailAuthStatus.rejected ||
      EmailAuthStatus.error => AppColors.pink,
      EmailAuthStatus.idle || EmailAuthStatus.loading => AppColors.paper,
    };
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continueToOtp() async {
    if (_isLoading) {
      return;
    }
    setState(() => _hasAttemptedSubmit = true);
    if (_emailError != null) {
      return;
    }
    final email = _emailController.text.trim();
    setState(() => _status = EmailAuthStatus.loading);
    EmailAuthStatus result;
    try {
      result = await widget.otpRequester(email);
    } on Object {
      result = EmailAuthStatus.error;
    }
    if (!mounted) {
      return;
    }
    setState(() => _status = result);
    if (result != EmailAuthStatus.otpSent) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).push(RetroPageRoute<void>(builder: (_) => LoginOtpScreen(email: email)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RetroGridBackground(
        child: Stack(
          children: [
            const Positioned(left: 20, top: 15, child: AppLogo()),
            const Positioned(
              top: 137,
              right: 96,
              child: RetroSticker(
                color: AppColors.yellow,
                width: 60,
                height: 22,
                angle: 7 * math.pi / 180,
              ),
            ),
            const Positioned(
              bottom: 95,
              left: 60,
              child: RetroSticker(
                color: AppColors.pink,
                angle: 10 * math.pi / 180,
              ),
            ),
            const Positioned(bottom: 164, right: 67, child: _OutlinedDot()),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: RetroCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  shadowOffset: const Offset(6, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOGIN',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome back. Move step by step.',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 8),
                      ),
                      const SizedBox(height: 20),
                      const LoginProgress(step: 1),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ink, width: 2.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMAIL',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Type your email then continue.',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'EMAIL',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 17),
                            RetroTextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'you@email.com',
                              onChanged: (_) {
                                setState(() {
                                  _hasInteracted = true;
                                  _status = EmailAuthStatus.idle;
                                });
                              },
                            ),
                            if (_emailError case final error?)
                              RetroValidationMessage(message: error),
                            if (_emailError == null)
                              if (_statusMessage case final message?)
                                RetroValidationMessage(
                                  message: message,
                                  backgroundColor: _statusColor,
                                  uppercase: false,
                                ),
                            const SizedBox(height: 13),
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 112,
                                child: RetroButton(
                                  label: _isLoading ? 'Sending...' : 'Send OTP',
                                  height: 32,
                                  shadowOffset: const Offset(4, 4),
                                  textStyle: const TextStyle(
                                    color: AppColors.ink,
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  onPressed: _isLoading ? null : _continueToOtp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'CURRENT: EMAIL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.muted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedDot extends StatelessWidget {
  const _OutlinedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFC9FF87),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 3),
      ),
    );
  }
}
