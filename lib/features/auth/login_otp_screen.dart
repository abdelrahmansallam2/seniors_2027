import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/auth/session_manager.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/core/storage/token_storage.dart';
import 'package:seniors_27/features/app_shell/main_app_shell.dart';
import 'package:seniors_27/features/auth/data/auth_api_service.dart';
import 'package:seniors_27/features/auth/widgets/login_progress.dart';
import 'package:seniors_27/features/auth/widgets/retro_validation_message.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_pressable.dart';
import 'package:seniors_27/shared/widgets/retro_text_field.dart';

typedef OtpVerifier = Future<String?> Function(String email, String otp);

Future<String?> defaultVerifyOtp(String email, String otp) async {
  final api = AuthApiService(ApiClient());
  try {
    final response = await api.verifyOtp(email, otp);
    final data = response.data;
    if (data is Map) {
      final token = data['token'] as String?;
      if (token != null) {
        await TokenStorage().saveToken(token);
        SessionManager.instance.resetAfterSuccessfulLogin();
        return null;
      }
    }
    return 'Invalid OTP';
  } on ApiException catch (e) {
    final d = e.data;
    if (d is Map && d['message'] is String) {
      return d['message'] as String;
    }
    return 'Invalid OTP. Please try again.';
  } catch (_) {
    return 'Something went wrong. Please try again.';
  }
}

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({
    required this.email,
    this.verifier = defaultVerifyOtp,
    super.key,
  });

  final String email;
  final OtpVerifier verifier;

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _apiError;
  String? _otpError;

  bool get _isLoading => _isVerifying;

  void _updateOtpError() {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _otpError = 'OTP is required.';
    } else if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _otpError = 'OTP must be exactly 6 digits.';
    } else {
      _otpError = null;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;
    setState(() => _apiError = null);
    _updateOtpError();
    if (_otpError != null) return;

    setState(() => _isVerifying = true);
    final error = await widget.verifier(
      widget.email,
      _otpController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (error != null) {
      setState(() => _apiError = error);
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
        child: Stack(
          children: [
            const Positioned(left: 20, top: 15, child: AppLogo()),
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
                      const LoginProgress(step: 2),
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
                              'ENTER OTP',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Code sent to ${widget.email}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 20),
                            RetroTextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              hintText: '-  -  -  -  -  -',
                              autofocus: true,
                              onChanged: (_) {
                                setState(() {
                                  _apiError = null;
                                  _updateOtpError();
                                });
                              },
                            ),
                            if (_otpError != null)
                              RetroValidationMessage(message: _otpError!),
                            if (_apiError case final error?)
                              RetroValidationMessage(
                                message: error,
                                backgroundColor: AppColors.pink,
                                uppercase: false,
                              ),
                            const SizedBox(height: 13),
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 118,
                                child: RetroButton(
                                  label: _isLoading ? 'Verifying...' : 'Verify',
                                  height: 32,
                                  shadowOffset: const Offset(4, 4),
                                  textStyle: const TextStyle(
                                    color: AppColors.ink,
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  onPressed: _isLoading ? null : _verifyOtp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RetroPressable(
                            onTap: () => Navigator.of(context).pop(),
                            builder: (context, isHovered, isPressed) {
                              final offset = isPressed
                                  ? const Offset(1, 1)
                                  : isHovered
                                  ? const Offset(0, -2)
                                  : Offset.zero;
                              return AnimatedContainer(
                                duration: Duration(
                                  milliseconds: isPressed ? 100 : 150,
                                ),
                                curve: Curves.easeOutCubic,
                                transform: Matrix4.translationValues(
                                  offset.dx,
                                  offset.dy,
                                  0,
                                ),
                                child: const Text(
                                  'EDIT EMAIL',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Text(
                            'RESEND OTP',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: AppColors.muted,
                              fontSize: 8,
                            ),
                          ),
                        ],
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
