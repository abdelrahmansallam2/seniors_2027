import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';
import 'package:seniors_27/features/profile/widgets/spotify_preview.dart';

class FavoriteSongScreen extends StatefulWidget {
  final String? initialEmbedUrl;

  const FavoriteSongScreen({this.initialEmbedUrl, super.key});

  @override
  State<FavoriteSongScreen> createState() => _FavoriteSongScreenState();
}

class _FavoriteSongScreenState extends State<FavoriteSongScreen> {
  final ProfileApiService _api = ProfileApiService(ApiClient());
  final _urlController = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _currentTrackId;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    _parseInitialUrl();
  }

  void _parseInitialUrl() {
    final url = widget.initialEmbedUrl;
    if (url != null && url.isNotEmpty) {
      _urlController.text = url;
    }
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    final info = text.isNotEmpty ? SpotifyTrackInfo.fromUrl(text) : null;
    setState(() {
      _error = null;
      if (info != null) {
        _currentTrackId = info.trackId;
      } else {
        if (text.isEmpty) {
          _currentTrackId = null;
        }
      }
    });
  }

  String get _embedUrl {
    if (_currentTrackId == null) return '';
    return 'https://open.spotify.com/embed/track/$_currentTrackId';
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) return;

    final info = SpotifyTrackInfo.fromUrl(rawUrl);
    if (info == null) {
      setState(() => _error = 'Invalid Spotify track URL.');
      return;
    }

    final embedUrl = info.toEmbedUrl();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response = await _api.updateFavoriteSong(embedUrl);
      final returned = response.data['favoriteSongEmbedUrl'] as String?;
      if (returned != null && returned.isNotEmpty) {
        debugPrint('[FavoriteSong] server stored: $returned');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save. Please try again.';
          _saving = false;
        });
      }
    }
  }

  Future<void> _remove() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.updateFavoriteSong('');
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to remove song.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _urlController.text.trim();
    final hasTrack = _currentTrackId != null;
    final hasSavedSong =
        widget.initialEmbedUrl != null && widget.initialEmbedUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: const Text(
          'FAVORITE SONG',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SPOTIFY TRACK URL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _urlController,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'https://open.spotify.com/track/...',
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_currentTrackId != null) ...[
              const Text(
                'PREVIEW',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              SpotifyPreview(embedUrl: _embedUrl),
            ],
            if (!hasTrack && text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Could not recognize a Spotify track in that URL.',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pink,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pink,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: (_saving || !hasTrack) ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _saving || !hasTrack
                        ? AppColors.muted
                        : const Color(0xFF1DB954),
                    border: Border.all(color: AppColors.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.paper,
                            ),
                          )
                        : const Text(
                            'SAVE SONG',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (hasSavedSong) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _saving ? null : _remove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                    child: const Center(
                      child: Text(
                        'REMOVE SONG',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
