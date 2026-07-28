import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpotifyPreview extends StatefulWidget {
  final String embedUrl;

  const SpotifyPreview({required this.embedUrl, super.key});

  @override
  State<SpotifyPreview> createState() => _SpotifyPreviewState();
}

class _SpotifyPreviewState extends State<SpotifyPreview> {
  WebViewController? _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(SpotifyPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl) {
      _initController();
    }
  }

  void _initController() {
    if (widget.embedUrl.isEmpty) return;
    _loading = true;
    _error = false;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (uri.host.contains('spotify.com')) {
              return NavigationDecision.navigate;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );
    _controller!.loadRequest(Uri.parse(widget.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedUrl.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 152,
      width: double.infinity,
      child: Stack(
        children: [
          if (_controller != null && !_error)
            WebViewWidget(controller: _controller!),
          if (_loading && !_error)
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
          if (_error)
            const Center(
              child: Text(
                'Could not load Spotify player.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
