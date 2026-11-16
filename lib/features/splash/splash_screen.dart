import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/core/storage/token_storage.dart';
import 'package:seniors_27/features/app_shell/main_app_shell.dart';
import 'package:seniors_27/features/auth/login_email_screen.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.tokenReader});

  @visibleForTesting
  final Future<String?> Function()? tokenReader;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _logoDuration = Duration(milliseconds: 1500);
  static const _memoryDuration = Duration(milliseconds: 1150);
  static const _buttonDuration = Duration(milliseconds: 280);
  static const _logoAsset = AssetImage('assets/images/app_logo.png');

  late final AnimationController _logoController;
  late final AnimationController _memoryController;
  late final AnimationController _buttonController;
  late final Listenable _logoTimeline;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoTurn;
  late final Animation<double> _stickerOpacity;
  late final Animation<double> _stickerScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonScale;

  bool _logoPreparationStarted = false;
  bool _logoReady = false;
  bool _openingFramePainted = false;
  bool _showMemoryStage = false;
  bool _reduceMotion = false;
  bool _isInForeground = true;
  bool _navigationStarted = false;
  bool? _hasToken;

  Animation<double> _interval(
    Animation<double> animation,
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) => animation.drive(CurveTween(curve: Interval(begin, end, curve: curve)));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isInForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;

    // Stage timing stays predictable; reduced motion is handled by the visuals.
    _logoController = AnimationController(
      duration: _logoDuration,
      animationBehavior: AnimationBehavior.preserve,
      vsync: this,
    )..addStatusListener(_onLogoStageStatus);
    _memoryController =
        AnimationController(
            duration: _memoryDuration,
            animationBehavior: AnimationBehavior.preserve,
            vsync: this,
          )
          ..addListener(_startLoginIfReady)
          ..addStatusListener(_onMemoryStatus);
    _buttonController = AnimationController(
      duration: _buttonDuration,
      animationBehavior: AnimationBehavior.preserve,
      vsync: this,
    );
    _logoTimeline = Listenable.merge([_logoController, _memoryController]);
    _logoOpacity = _interval(_logoController, 0, 0.13);
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.86,
          end: 1.035,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.035,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
    ]).animate(_interval(_logoController, 0, 0.73, Curves.linear));
    _logoTurn = Tween<double>(
      begin: -0.012,
      end: 0,
    ).animate(_interval(_logoController, 0, 0.55));
    _stickerOpacity = _interval(_logoController, 0.14, 0.3);
    _stickerScale = _interval(_logoController, 0.14, 0.36, Curves.easeOutBack);
    _titleOpacity = _interval(_memoryController, 0.24, 0.64);
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_interval(_memoryController, 0.24, 0.64));
    _buttonOpacity = _buttonController.drive(
      CurveTween(curve: Curves.easeOutCubic),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(_buttonOpacity);
    _buttonScale = Tween<double>(
      begin: 0.94,
      end: 1,
    ).animate(_buttonController.drive(CurveTween(curve: Curves.easeOutBack)));

    unawaited(_checkSessionAndRedirect());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = RetroMotion.reduceMotion(context);
    if (!_logoPreparationStarted) {
      _logoPreparationStarted = true;
      unawaited(_prepareLogo());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resumeCurrentStage();
    });
  }

  Future<void> _prepareLogo() async {
    await precacheImage(
      _logoAsset,
      context,
      onError: (error, stackTrace) {
        if (kDebugMode) debugPrint('[Splash] logo preload failed');
      },
    );
    if (!mounted) return;
    setState(() => _logoReady = true);
    // Start the 1.5-second opening only after its decoded logo can be painted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openingFramePainted = true;
      _resumeCurrentStage();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInForeground = state == AppLifecycleState.resumed;
    if (_isInForeground) {
      _resumeCurrentStage();
    } else {
      _logoController.stop(canceled: false);
      _memoryController.stop(canceled: false);
      _buttonController.stop(canceled: false);
    }
  }

  void _resumeCurrentStage() {
    if (!mounted || !_isInForeground || !_openingFramePainted) return;
    if (!_showMemoryStage) {
      if (!_logoController.isAnimating && !_logoController.isCompleted) {
        _logoController.forward();
      }
      return;
    }
    if (_reduceMotion) {
      _memoryController.value = 1;
    } else if (!_memoryController.isAnimating &&
        !_memoryController.isCompleted) {
      _memoryController.forward();
    }
    _startLoginIfReady();
    _maybeNavigateToApp();
  }

  void _onLogoStageStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _showMemoryStage = true);
    _resumeCurrentStage();
  }

  void _onMemoryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _maybeNavigateToApp();
  }

  void _startLoginIfReady() {
    if (!mounted ||
        !_isInForeground ||
        !_showMemoryStage ||
        _hasToken != false ||
        _memoryController.value < 0.6 ||
        _buttonController.isCompleted) {
      return;
    }
    if (_reduceMotion) {
      _buttonController.value = 1;
    } else if (!_buttonController.isAnimating) {
      _buttonController.forward();
    }
  }

  Future<void> _checkSessionAndRedirect() async {
    if (kDebugMode) debugPrint('[Splash] session check started');
    var exists = false;
    try {
      final token =
          await (widget.tokenReader?.call() ?? TokenStorage().readToken());
      exists = token != null && token.trim().isNotEmpty;
    } catch (_) {
      if (kDebugMode) debugPrint('[Splash] session check failed');
    }
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[Splash] session check completed tokenExists=$exists');
    }
    setState(() => _hasToken = exists);
    _startLoginIfReady();
    _maybeNavigateToApp();
  }

  void _maybeNavigateToApp() {
    if (!mounted ||
        !_isInForeground ||
        _navigationStarted ||
        _hasToken != true ||
        !_memoryController.isCompleted) {
      return;
    }
    _navigationStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_isInForeground) {
        _navigationStarted = false;
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        RetroPageRoute<void>(builder: (_) => const MainAppShell()),
        (route) => false,
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _openLogin() async {
    if (_navigationStarted || _hasToken != false) return;
    setState(() => _navigationStarted = true);
    try {
      await Navigator.of(context).push<void>(
        RetroPageRoute<void>(builder: (_) => const LoginEmailScreen()),
      );
    } finally {
      if (mounted) setState(() => _navigationStarted = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoController
      ..removeStatusListener(_onLogoStageStatus)
      ..dispose();
    _memoryController
      ..removeListener(_startLoginIfReady)
      ..removeStatusListener(_onMemoryStatus)
      ..dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Widget _animateSticker(Widget child) {
    if (_reduceMotion) return child;
    return FadeTransition(
      opacity: _stickerOpacity,
      child: ScaleTransition(scale: _stickerScale, child: child),
    );
  }

  Widget _buildLogo(Size size) {
    final openingSize = math.min(200.0, size.shortestSide * 0.52);
    final cornerSize = math.min(120.0, size.shortestSide * 0.36);
    final opening = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: openingSize,
      height: openingSize,
    );
    final corner = Rect.fromLTWH(20, 15, cornerSize, cornerSize);
    return AnimatedBuilder(
      key: const ValueKey('splash_logo_motion'),
      animation: _logoTimeline,
      builder: (context, child) {
        final progress = !_showMemoryStage
            ? 0.0
            : _reduceMotion
            ? 1.0
            : Curves.easeInOutCubic.transform(
                (_memoryController.value / 0.36).clamp(0.0, 1.0),
              );
        final rect = Rect.lerp(opening, corner, progress)!;
        return Positioned.fromRect(
          rect: rect,
          child: SizedBox.expand(
            key: const ValueKey('splash_logo'),
            child: FadeTransition(
              opacity: !_logoReady
                  ? const AlwaysStoppedAnimation(0)
                  : _reduceMotion
                  ? const AlwaysStoppedAnimation(1)
                  : _logoOpacity,
              child: RotationTransition(
                turns: _reduceMotion
                    ? const AlwaysStoppedAnimation(0)
                    : _logoTurn,
                child: ScaleTransition(
                  scale: _reduceMotion
                      ? const AlwaysStoppedAnimation(1)
                      : _logoScale,
                  child: Semantics(
                    image: true,
                    label: 'Seniors 2027',
                    child: ExcludeSemantics(child: AppLogo(size: rect.width)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginSlot() {
    if (_hasToken == true) return const SizedBox.shrink();
    if (_hasToken == null) {
      return FadeTransition(
        opacity: _titleOpacity,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.ink,
              semanticsLabel: 'Checking saved session',
            ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _buttonController,
      child: RetroButton(
        label: 'LOGIN',
        onPressed: _navigationStarted ? null : _openLogin,
      ),
      builder: (context, child) {
        final hidden = !_buttonController.isCompleted || _navigationStarted;
        return ExcludeSemantics(
          excluding: hidden,
          child: IgnorePointer(
            ignoring: hidden,
            child: FadeTransition(
              opacity: _buttonOpacity,
              child: SlideTransition(
                position: _buttonSlide,
                child: ScaleTransition(scale: _buttonScale, child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemoryContent(BuildContext context, Size size) {
    final compact = size.height < 560;
    return Positioned.fill(
      key: const ValueKey('memory_splash_stage'),
      top: compact ? 135 : 0,
      bottom: compact ? 24 : 0,
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -8),
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ONE YEAR,\nA MILLION',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
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
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(width: 255, height: 65, child: _buildLoginSlot()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RetroGridBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return Stack(
                key: const ValueKey('splash_canvas'),
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 94,
                    right: 23,
                    child: _animateSticker(
                      const RetroSticker(
                        color: AppColors.pink,
                        angle: 10 * math.pi / 180,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 56,
                    left: 70,
                    child: _animateSticker(
                      const RetroSticker(
                        color: AppColors.cyan,
                        width: 51,
                        height: 22,
                        angle: -10 * math.pi / 180,
                      ),
                    ),
                  ),
                  if (_showMemoryStage) _buildMemoryContent(context, size),
                  _buildLogo(size),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
