import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpotifyPreview extends StatefulWidget {
  final String embedUrl;

  const SpotifyPreview({required this.embedUrl, super.key});

  @override
  State<SpotifyPreview> createState() => _SpotifyPreviewState();
}

class _SpotifyPreviewState extends State<SpotifyPreview>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _loading = true;
  String? _mainFrameError;
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appDebugLog('[Spotify] disposed');
    super.dispose();
  }

  @override
  void didUpdateWidget(SpotifyPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl && _controller != null) {
      _initController();
    }
  }

  void _activate() {
    if (_activated || _controller != null) return;
    _activated = true;
    appDebugLog('[Spotify] activation requested');
    setState(_initController);
  }

  void _initController() {
    if (widget.embedUrl.isEmpty) return;
    _loading = true;
    _mainFrameError = null;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _loading = true;
                _mainFrameError = null;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            final isMainFrame = error.isForMainFrame == true;
            if (isMainFrame) {
              appDebugLog('[Spotify] load failed code=${error.errorCode}');
              if (mounted) {
                setState(() {
                  _mainFrameError = error.description;
                  _loading = false;
                });
              }
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            final isSpotifyHost =
                uri.host.contains('spotify.com') ||
                uri.host.contains('scdn.co');
            if (isSpotifyHost) {
              return NavigationDecision.navigate;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );
    appDebugLog('[Spotify] controller initialized');
    controller.loadRequest(Uri.parse(widget.embedUrl));
    _controller = controller;
  }

  void _retry() {
    setState(() {
      _mainFrameError = null;
      _loading = true;
    });
    _controller?.loadRequest(Uri.parse(widget.embedUrl));
  }

  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: _activate,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1DB954),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'TAP TO PLAY',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedUrl.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      key: const ValueKey('spotify_widget'),
      height: 152,
      width: double.infinity,
      child: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(
              key: ValueKey('webview_${widget.embedUrl}'),
              controller: _controller!,
            )
          else
            _buildPlaceholder(),
          if (_controller != null && _loading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1DB954),
                ),
              ),
            ),
          if (_controller != null && _mainFrameError != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not load Spotify player.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _retry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'RETRY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
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
