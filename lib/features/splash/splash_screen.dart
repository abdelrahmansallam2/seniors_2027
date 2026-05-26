import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/features/auth/login_email_screen.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoStageController;
  late final AnimationController _memoryController;
  late final Animation<double> _openingLogoOpacity;
  late final Animation<double> _openingLogoScale;
  late final Animation<double> _openingLogoTurn;
  late final Animation<double> _openingStickerScale;
  late final Animation<double> _memoryLogoOpacity;
  late final Animation<double> _memoryLogoScale;
  late final Animation<double> _memoryLogoTurn;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonScale;
  late final Animation<double> _topStickerScale;
  late final Animation<double> _bottomStickerScale;
  bool _showMemoryStage = false;

  @override
  void initState() {
    super.initState();
    _logoStageController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _openingLogoOpacity = CurvedAnimation(
      parent: _logoStageController,
      curve: const Interval(0, 0.2, curve: Curves.easeOut),
    );
    _openingLogoScale = _logoPopScale(_logoStageController);
    _openingLogoTurn = _logoTurnAnimation(_logoStageController);
    _openingStickerScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoStageController,
        curve: const Interval(0.2, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoStageController.addStatusListener(_onLogoStageStatus);

    _memoryController = AnimationController(
      duration: const Duration(milliseconds: 1150),
      vsync: this,
    );
    _memoryLogoOpacity = CurvedAnimation(
      parent: _memoryController,
      curve: const Interval(0, 0.24, curve: Curves.easeOut),
    );
    _memoryLogoScale = _logoPopScale(_memoryController);
    _memoryLogoTurn = _logoTurnAnimation(_memoryController);
    _titleOpacity = CurvedAnimation(
      parent: _memoryController,
      curve: const Interval(0.18, 0.62, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _memoryController,
            curve: const Interval(0.18, 0.62, curve: Curves.easeOutCubic),
          ),
        );
    _buttonOpacity = CurvedAnimation(
      parent: _memoryController,
      curve: const Interval(0.55, 0.82, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _memoryController,
            curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
          ),
        );
    _buttonScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _memoryController,
        curve: const Interval(0.55, 0.96, curve: Curves.easeOutBack),
      ),
    );
    _topStickerScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _memoryController,
        curve: const Interval(0.16, 0.42, curve: Curves.easeOutBack),
      ),
    );
    _bottomStickerScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _memoryController,
        curve: const Interval(0.4, 0.68, curve: Curves.easeOutBack),
      ),
    );

    _logoStageController.forward();
  }

  Animation<double> _logoPopScale(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.68,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
    ]).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 0.92)),
    );
  }

  Animation<double> _logoTurnAnimation(AnimationController controller) {
    return Tween<double>(begin: -0.018, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _onLogoStageStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() => _showMemoryStage = true);
    _memoryController.forward();
  }

  @override
  void dispose() {
    _logoStageController
      ..removeStatusListener(_onLogoStageStatus)
      ..dispose();
    _memoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RetroGridBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 440),
          reverseDuration: const Duration(milliseconds: 360),
          transitionBuilder: (child, animation) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.985,
                    end: 1,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              ),
            );
          },
          child: _showMemoryStage
              ? _buildMemoryContent(context)
              : _buildLogoStage(),
        ),
      ),
    );
  }

  Widget _buildLogoStage() {
    return Stack(
      key: const ValueKey('logo_splash_stage'),
      children: [
        Positioned(
          top: 94,
          right: 23,
          child: ScaleTransition(
            scale: _openingStickerScale,
            child: const RetroSticker(
              color: AppColors.pink,
              angle: 10 * math.pi / 180,
            ),
          ),
        ),
        Positioned(
          bottom: 56,
          left: 70,
          child: ScaleTransition(
            scale: _openingStickerScale,
            child: const RetroSticker(
              color: AppColors.cyan,
              width: 51,
              height: 22,
              angle: -10 * math.pi / 180,
            ),
          ),
        ),
        Center(
          child: FadeTransition(
            opacity: _openingLogoOpacity,
            child: RotationTransition(
              turns: _openingLogoTurn,
              child: ScaleTransition(
                scale: _openingLogoScale,
                child: const AppLogo(size: 184),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryContent(BuildContext context) {
    return Stack(
      key: const ValueKey('memory_splash_stage'),
      children: [
        Positioned(
          left: 20,
          top: 15,
          child: FadeTransition(
            opacity: _memoryLogoOpacity,
            child: RotationTransition(
              turns: _memoryLogoTurn,
              child: ScaleTransition(
                scale: _memoryLogoScale,
                child: const AppLogo(),
              ),
            ),
          ),
        ),
        Positioned(
          top: 94,
          right: 23,
          child: ScaleTransition(
            scale: _topStickerScale,
            child: const RetroSticker(
              color: AppColors.pink,
              angle: 10 * math.pi / 180,
            ),
          ),
        ),
        Positioned(
          bottom: 56,
          left: 70,
          child: ScaleTransition(
            scale: _bottomStickerScale,
            child: const RetroSticker(
              color: AppColors.cyan,
              width: 51,
              height: 22,
              angle: -10 * math.pi / 180,
            ),
          ),
        ),
        Center(
          child: Transform.translate(
            offset: const Offset(0, -8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _titleOpacity,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        Text(
                          'ONE YEAR,\nA MILLION',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 12),
                        Transform.rotate(
                          angle: -1.2 * math.pi / 180,
                          child: const RetroShadowContainer(
                            width: 282,
                            height: 78,
                            backgroundColor: AppColors.yellowWarm,
                            borderRadius: 0,
                            shadowOffset: Offset(7, 8),
                            child: Center(
                              child: Text(
                                'MEMORIES',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 46,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _buttonOpacity,
                  child: SlideTransition(
                    position: _buttonSlide,
                    child: ScaleTransition(
                      scale: _buttonScale,
                      child: SizedBox(
                        width: 255,
                        child: RetroButton(
                          label: 'LOGIN',
                          onPressed: () {
                            Navigator.of(context).push(
                              RetroPageRoute<void>(
                                builder: (_) => const LoginEmailScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
