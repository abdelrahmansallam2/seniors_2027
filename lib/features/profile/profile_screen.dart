import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/auth/session_manager.dart';
import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/notes/data/notes_api_service.dart';
import 'package:seniors_27/features/seniors_directory/data/seniors_api_service.dart';
import 'package:seniors_27/features/notes/models/note.dart';
import 'package:seniors_27/features/notes/notes_open_book_screen.dart';
import 'package:seniors_27/features/notes/send_note_screen.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';
import 'package:seniors_27/features/profile/data/profile_gallery_api_service.dart';
import 'package:seniors_27/features/profile/models/profile_gallery_photo.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';
import 'package:seniors_27/features/profile/models/social_link.dart';
import 'package:seniors_27/features/profile/favorite_song_screen.dart';
import 'package:seniors_27/features/profile/edit_description_screen.dart';
import 'package:seniors_27/features/profile/edit_name_screen.dart';
import 'package:seniors_27/features/profile/edit_profile_photo_screen.dart';
import 'package:seniors_27/features/profile/social_links_screen.dart';
import 'package:seniors_27/shared/widgets/note_card.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seniors_27/features/profile/widgets/profile_gallery_card.dart';
import 'package:seniors_27/features/profile/widgets/spotify_preview.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.onOpenNotes,
    this.userId,
    this.readOnly = false,
    this.registerRefresh,
    this.onRefreshSuccess,
    super.key,
  });

  final VoidCallback onOpenNotes;
  final String? userId;
  final bool readOnly;
  final void Function(Future<void> Function({bool force}) refresh)?
  registerRefresh;
  final VoidCallback? onRefreshSuccess;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileApiService _profileApi = ProfileApiService(ApiClient());
  final ProfileGalleryApiService _galleryApi = ProfileGalleryApiService(
    ApiClient(),
  );
  final NotesApiService _notesApi = NotesApiService(ApiClient());

  ProfileUser _user = const ProfileUser(id: '', name: 'Student');

  List<ProfileGalleryPhoto> _galleryPhotos = [];
  bool _galleryLoading = true;
  String? _galleryError;

  List<String> _socialLinks = [];

  String _currentUserId = '';
  List<Note> _latestNotes = [];
  int _totalNotesCount = 0;
  bool _notesLoading = true;
  String? _notesError;
  VoidCallback? _notifyRefreshSuccess;

  @override
  void initState() {
    super.initState();
    widget.registerRefresh?.call(refresh);
    _notifyRefreshSuccess = widget.onRefreshSuccess;
    _loadProfile();
  }

  Future<void> refresh({bool force = true}) {
    return _loadProfile(forceRefresh: force);
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    if (widget.readOnly) {
      await _loadVisitedProfile();
      return;
    }
    try {
      List<String>? fetchedLinks;
      final parsed = await CurrentUserCache.get(
        forceRefresh: forceRefresh,
        fetcher: () async {
          final response = await _profileApi.getMe();
          final data = response.data;
          appDebugLog(
            '[Profile] /api/Auth/me response type: ${data.runtimeType}',
          );

          if (data is Map<String, dynamic>) {
            fetchedLinks = _parseSocialLinks(data);
            return ProfileUser.fromJson(data);
          }
          throw const FormatException('unexpected /api/Auth/me payload');
        },
      );
      appDebugLog('[Profile] loaded user id=${parsed.id}');

      if (mounted) {
        final links = fetchedLinks;
        setState(() {
          _user = parsed;
          if (links != null) {
            _socialLinks = links;
          }
        });
        _notifyRefreshSuccess?.call();
        _loadGallery(parsed.id);
        _loadLatestNotes(parsed.id);
      }
    } catch (e) {
      appDebugLog(
        '[Profile] /api/Auth/me failed status=${e is ApiException ? e.statusCode : null}',
      );
      _stopChildLoading();
    }
  }

  Future<void> _loadVisitedProfile() async {
    try {
      final me = CurrentUserCache.peek();
      if (me != null) {
        _currentUserId = me.id;
      }

      final api = SeniorsApiService(ApiClient());
      final response = await api.getUserById(widget.userId!);
      final data = response.data;
      appDebugLog(
        '[Profile] /api/Users/{id} response type: ${data.runtimeType}',
      );

      if (data is Map<String, dynamic>) {
        final parsed = ProfileUser.fromJson(data);
        appDebugLog('[Profile] visited user id=${parsed.id}');

        if (mounted) {
          setState(() {
            _user = parsed;
            _socialLinks = _parseSocialLinks(data);
          });
          _loadGallery(parsed.id);
          _loadLatestNotes(parsed.id);
        }
      } else {
        appDebugLog(
          '[Profile] unexpected /api/Users/{id} type: ${data.runtimeType}',
        );
      }
    } catch (e) {
      appDebugLog(
        '[Profile] visited profile failed status=${e is ApiException ? e.statusCode : null}',
      );
      _stopChildLoading();
    }
  }

  void _stopChildLoading() {
    if (!mounted) return;
    setState(() {
      if (_galleryPhotos.isEmpty) {
        _galleryError = 'Failed to load gallery.';
      }
      _galleryLoading = false;
      if (_latestNotes.isEmpty && _totalNotesCount == 0) {
        _notesError = 'Notes unavailable.';
      }
      _notesLoading = false;
    });
  }

  Future<void> _loadGallery(String userId) async {
    if (!_isValidProfileId(userId)) {
      appDebugLog(
        '[Profile] child requests skipped because user id is unavailable',
      );
      if (mounted) {
        setState(() {
          _galleryLoading = false;
        });
      }
      return;
    }

    setState(() {
      _galleryLoading = true;
      _galleryError = null;
    });

    try {
      final response = await _galleryApi.getUserGallery(userId);
      final data = response.data;

      appDebugLog('[Profile] gallery response type: ${data.runtimeType}');

      List<dynamic> itemsList;

      if (data is List) {
        appDebugLog('[Profile] gallery raw list length: ${data.length}');
        itemsList = data;
      } else if (data is Map) {
        itemsList =
            (data['items'] as List<dynamic>?) ??
            (data['photos'] as List<dynamic>?) ??
            (data['results'] as List<dynamic>?) ??
            (data['data'] as List<dynamic>?) ??
            [];
        appDebugLog('[Profile] gallery items length: ${itemsList.length}');
      } else {
        appDebugLog('[Profile] unexpected gallery type: ${data.runtimeType}');
        itemsList = [];
      }

      final parsed = itemsList
          .whereType<Map<String, dynamic>>()
          .map(ProfileGalleryPhoto.fromJson)
          .toList();

      if (mounted) {
        setState(() {
          _galleryPhotos = parsed;
          _galleryLoading = false;
        });
      }
    } catch (e) {
      appDebugLog(
        '[Profile] gallery failed status=${e is ApiException ? e.statusCode : null}',
      );
      if (mounted) {
        setState(() {
          final isRateLimited = e is ApiException && e.statusCode == 429;
          if (!(isRateLimited && _galleryPhotos.isNotEmpty)) {
            _galleryError = 'Failed to load gallery.';
          }
          _galleryLoading = false;
        });
      }
    }
  }

  Future<void> _loadLatestNotes(String recipientId) async {
    appDebugLog('[VisitedNotes] _loadLatestNotes started');

    if (!_isValidProfileId(recipientId)) {
      appDebugLog(
        '[Profile] child requests skipped because user id is unavailable',
      );
      if (mounted) {
        setState(() {
          _notesLoading = false;
        });
      }
      return;
    }

    setState(() {
      _notesLoading = true;
      _notesError = null;
    });

    try {
      final response = await _notesApi.getReceivedNotes(recipientId);
      final data = response.data;

      List<dynamic> itemsList = [];
      int totalCount = 0;

      if (data is Map) {
        totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
        for (final key in ['items', 'data', 'results', 'notes']) {
          final val = data[key];
          if (val is List) {
            itemsList = val;
            break;
          }
        }
      } else if (data is List) {
        totalCount = data.length;
        itemsList = data;
      }

      final parsed = itemsList
          .whereType<Map<String, dynamic>>()
          .map(Note.fromJson)
          .toList();

      parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      appDebugLog(
        '[VisitedNotes] parsed=${parsed.length} totalCount=$totalCount',
      );

      if (mounted) {
        setState(() {
          _totalNotesCount = totalCount > 0 ? totalCount : parsed.length;
          _latestNotes = parsed.take(4).toList();
          _notesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final isRateLimited = e is ApiException && e.statusCode == 429;
          if (!(isRateLimited &&
              (_latestNotes.isNotEmpty || _totalNotesCount > 0))) {
            _notesError = 'Notes unavailable.';
          }
          _notesLoading = false;
        });
      }
    }
  }

  static bool _isValidProfileId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;
    final parsed = int.tryParse(trimmed);
    if (parsed != null && parsed == 0) return false;
    return true;
  }

  static List<String> _parseSocialLinks(Map<String, dynamic> data) {
    final raw = data['socialLinks'];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return [];
  }

  Future<void> _openLink(String url) async {
    final normalized = SocialLink.normalizeUrl(url);
    final uri = Uri.tryParse(normalized);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          _showLinkError();
        }
      } catch (_) {
        _showLinkError();
      }
    }
  }

  void _showLinkError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not open this link.',
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openSocialLinksScreen() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SocialLinksScreen(
          initialLinks: _socialLinks,
          onSaved: _loadProfile,
        ),
      ),
    );
  }

  Future<void> _openFavoriteSongEditor() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            FavoriteSongScreen(initialEmbedUrl: _user.favoriteSongEmbedUrl),
      ),
    );
    if (result == true && mounted) {
      _loadProfile();
    }
  }

  Future<void> _openNameEditor() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditNameScreen(currentName: _user.name),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _user = ProfileUser(
          id: _user.id,
          name: result,
          email: _user.email,
          role: _user.role,
          description: _user.description,
          gender: _user.gender,
          photoUrl: _user.photoUrl,
          points: _user.points,
          status: _user.status,
          favoriteSongEmbedUrl: _user.favoriteSongEmbedUrl,
        );
      });
    }
  }

  Future<void> _openDescriptionEditor() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            EditDescriptionScreen(currentDescription: _user.description),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _user = ProfileUser(
          id: _user.id,
          name: _user.name,
          email: _user.email,
          role: _user.role,
          description: result,
          gender: _user.gender,
          photoUrl: _user.photoUrl,
          points: _user.points,
          status: _user.status,
          favoriteSongEmbedUrl: _user.favoriteSongEmbedUrl,
        );
      });
    }
  }

  Future<void> _openPhotoEditor() async {
    final oldUrl = _user.photoUrl;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditProfilePhotoScreen(currentPhotoUrl: oldUrl),
      ),
    );
    if (result != null && mounted) {
      if (oldUrl != null && oldUrl.isNotEmpty) {
        imageCache.evict(NetworkImage(oldUrl));
      }

      setState(() {
        _user = ProfileUser(
          id: _user.id,
          name: _user.name,
          email: _user.email,
          role: _user.role,
          description: _user.description,
          gender: _user.gender,
          photoUrl: result,
          points: _user.points,
          status: _user.status,
          favoriteSongEmbedUrl: _user.favoriteSongEmbedUrl,
        );
      });
      appDebugLog('[Profile] userUpdated: true');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.ink, width: 2.5),
        ),
        title: const Text(
          'LOG OUT?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: AppColors.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'LOG OUT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: AppColors.pink,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await SessionManager.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final content = _buildContent(user);

    if (widget.readOnly) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: RetroGridBackground(child: SafeArea(child: content)),
      );
    }
    return content;
  }

  Widget _buildContent(ProfileUser user) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        key: const PageStorageKey('profile_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.readOnly)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: 100,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: 14,
                            color: AppColors.ink,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'BACK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                MainPageHeader(
                  title: widget.readOnly ? 'PROFILE' : 'My Profile',
                  subtitle: widget.readOnly
                      ? (user.name.isNotEmpty
                            ? user.name.toUpperCase()
                            : 'VISITING')
                      : 'Your senior identity.',
                ),
                Positioned(
                  top: 2,
                  right: 4,
                  child: RetroSticker(
                    color: AppColors.magenta,
                    width: 58,
                    height: 20,
                    angle: 0.12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTopSection(user),
            const SizedBox(height: 20),
            _buildSocialAndSpotify(),
            const SizedBox(height: 20),
            if (widget.readOnly)
              _buildCompactNotes()
            else
              GestureDetector(
                onTap: widget.onOpenNotes,
                child: _buildLatestNotes(),
              ),
            const SizedBox(height: 20),
            _buildGallerySection(),
            if (!widget.readOnly) ...[
              const SizedBox(height: 28),
              _buildLogoutButton(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBadge(int points) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.yellowWarm,
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 14, color: AppColors.ink),
            const SizedBox(width: 6),
            Text(
              '${_formatPoints(points)} POINTS',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                height: 1.2,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(ProfileUser user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 6),
            RetroCard(
              padding: const EdgeInsets.all(6),
              child: Stack(
                children: [
                  user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            user.photoUrl!,
                            key: ValueKey(user.photoUrl),
                            width: 120,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _PhotoPlaceholder(),
                          ),
                        )
                      : const _PhotoPlaceholder(),
                  if (!widget.readOnly)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: _openPhotoEditor,
                        child: Container(
                          width: 28,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            border: Border.all(
                              color: AppColors.ink,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.ink,
                                offset: Offset(1.5, 1.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.edit,
                            size: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'HELLO',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'SENIOR',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      user.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (!widget.readOnly) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openNameEditor,
                      child: Container(
                        width: 28,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.ink,
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.edit,
                          size: 13,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (user.points != null) ...[
                const SizedBox(height: 8),
                _buildPointsBadge(user.points!),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!widget.readOnly) ...[
                    GestureDetector(
                      onTap: _openDescriptionEditor,
                      child: Container(
                        width: 28,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.ink,
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.edit,
                          size: 13,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (user.description.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
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
                      child: Text(
                        '"${user.description}"',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: widget.readOnly ? null : _openDescriptionEditor,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
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
                        child: const Text(
                          'No description yet.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialAndSpotify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSocialLinks(),
        const SizedBox(height: 20),
        _buildSpotifyCard(),
      ],
    );
  }

  Widget _buildSocialLinks() {
    final links = _socialLinks.map(SocialLink.fromUrl).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'SOCIAL LINKS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 1.5,
              ),
            ),
            if (!widget.readOnly) ...[
              const Spacer(),
              GestureDetector(
                onTap: _openSocialLinksScreen,
                child: Container(
                  width: 28,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.edit, size: 13, color: AppColors.ink),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (links.isEmpty)
          const Text(
            'No links added yet.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final link in links)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _openLink(link.url),
                      child: _SocialIcon(platform: link.platform),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSpotifyCard() {
    final embedUrl = _user.favoriteSongEmbedUrl;
    final hasSong = embedUrl != null && embedUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'SPOTIFY',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 1.5,
              ),
            ),
            if (!widget.readOnly) ...[
              const Spacer(),
              GestureDetector(
                onTap: _openFavoriteSongEditor,
                child: Container(
                  width: 28,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.edit, size: 13, color: AppColors.ink),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (hasSong)
          RetroCard(
            padding: const EdgeInsets.all(12),
            child: SpotifyPreview(embedUrl: embedUrl),
          )
        else
          _buildEmptyPlayer(),
      ],
    );
  }

  Widget _buildEmptyPlayer() {
    return GestureDetector(
      onTap: widget.readOnly ? null : _openFavoriteSongEditor,
      child: RetroCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: const FaIcon(
                FontAwesomeIcons.spotify,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No favorite song yet.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ADD',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _logout,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.pink,
            border: Border.all(color: AppColors.ink, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 16, color: AppColors.ink),
              SizedBox(width: 8),
              Text(
                'LOG OUT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
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
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildCompactNotes() {
    final int totalNotesCount = _totalNotesCount;
    final int visibleCount = _notesLoading || _notesError != null
        ? 0
        : _latestNotes.length.clamp(0, 4);
    final int remainingCount = (totalNotesCount - visibleCount).clamp(
      0,
      totalNotesCount,
    );

    return RetroCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            onTap: _openVisitedNotesBook,
            child: const RetroSectionHeader(
              title: 'LATEST 4 NOTES',
              backgroundColor: AppColors.yellow,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Text(
                        'TOTAL: $totalNotesCount',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.paper,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openVisitedNotesBook,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: const Text(
                          'OPEN BOOK',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    if (_canSendNote) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _openSendNote,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954),
                            border: Border.all(
                              color: AppColors.ink,
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            'SEND NOTE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppColors.paper,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _notesLoading
                      ? 'Loading notes...'
                      : _notesError != null
                      ? 'Notes currently unavailable.'
                      : totalNotesCount == 0
                      ? 'No notes yet.'
                      : 'Showing $visibleCount of $totalNotesCount notes — $remainingCount more notes inside the Notes Book.',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                if (_notesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                else if (_notesError != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Notes currently unavailable.',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                else if (totalNotesCount == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No notes yet.',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                else
                  for (final note in _latestNotes.take(4))
                    NoteCard(
                      senderName: note.senderName.isNotEmpty
                          ? note.senderName
                          : 'Anonymous',
                      senderPhotoUrl: note.senderPhotoUrl,
                      date: note.createdAt.isNotEmpty
                          ? _formatDate(note.createdAt)
                          : '',
                      content: note.content,
                      maxLines: 2,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSendNote {
    if (!widget.readOnly) return false;
    if (widget.userId == null) return false;
    final visitedId = int.tryParse(widget.userId!);
    if (visitedId == null || visitedId == 0) return false;
    if (_currentUserId.isNotEmpty && _currentUserId == widget.userId) {
      return false;
    }
    return true;
  }

  void _openVisitedNotesBook() {
    final visitedUserId = widget.userId;
    if (visitedUserId == null) return;
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: AppColors.background,
              body: RetroGridBackground(
                child: SafeArea(
                  child: NotesOpenBookScreen(
                    onBackToProfile: () => Navigator.pop(context, true),
                    openedFromProfile: true,
                    userId: visitedUserId,
                    readOnly: true,
                  ),
                ),
              ),
            ),
          ),
        )
        .then((_) {
          if (mounted) _loadLatestNotes(widget.userId!);
        });
  }

  void _openSendNote() {
    final visitedId = int.tryParse(widget.userId ?? '');
    if (visitedId == null || visitedId == 0) return;

    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => SendNoteScreen(
              recipientId: visitedId,
              recipientName: _user.name,
            ),
          ),
        )
        .then((success) {
          if (success == true && mounted) {
            _loadLatestNotes(widget.userId!);
          }
        });
  }

  Widget _buildLatestNotes() {
    final int totalNotesCount = _totalNotesCount;
    final int visibleCount = _latestNotes.length.clamp(0, 4);

    return RetroCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'LATEST 4 NOTES',
            backgroundColor: AppColors.yellow,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Text(
                        'TOTAL: $totalNotesCount',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.paper,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: const Text(
                        'OPEN BOOK',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _notesLoading
                      ? 'Loading notes...'
                      : _notesError != null
                      ? 'Notes currently unavailable.'
                      : totalNotesCount == 0
                      ? 'No notes yet.'
                      : 'Showing $visibleCount of $totalNotesCount notes${totalNotesCount > 4 ? ' — ${totalNotesCount - 4} more notes inside the Notes Book.' : '.'}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (_notesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else if (_latestNotes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No notes yet.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            for (final note in _latestNotes.take(4))
              NoteCard(
                senderName: note.senderName.isNotEmpty
                    ? note.senderName
                    : 'Anonymous',
                senderPhotoUrl: note.senderPhotoUrl,
                date: note.createdAt.isNotEmpty
                    ? _formatDate(note.createdAt)
                    : '',
                content: note.content,
                maxLines: 2,
              ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GALLERY',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ProfileGalleryCard(
          photos: _galleryPhotos,
          isLoading: _galleryLoading,
          errorMessage: _galleryError,
          onOpenGallery: () =>
              _showGalleryViewer(context, _galleryPhotos, initialIndex: 0),
          onRetry: () => _loadGallery(_user.id),
        ),
      ],
    );
  }

  void _showGalleryViewer(
    BuildContext context,
    List<ProfileGalleryPhoto> photos, {
    required int initialIndex,
  }) {
    if (photos.isEmpty) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gallery viewer',
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) {
        return _GalleryViewerSheet(photos: photos, initialIndex: initialIndex);
      },
    );
  }
}

class _GalleryViewerSheet extends StatefulWidget {
  const _GalleryViewerSheet({required this.photos, required this.initialIndex});

  final List<ProfileGalleryPhoto> photos;
  final int initialIndex;

  @override
  State<_GalleryViewerSheet> createState() => _GalleryViewerSheetState();
}

class _GalleryViewerSheetState extends State<_GalleryViewerSheet> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.photos.length) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final photo = photos[_currentIndex];
    final bool isFirst = _currentIndex == 0;
    final bool isLast = _currentIndex == photos.length - 1;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, right: 16),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      border: Border.all(color: Colors.white24, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Image.network(
                          photo.photoUrl ?? '',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                        ),
                      ),
                    ),
                    if (!isFirst)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _ArrowButton(
                            icon: Icons.chevron_left,
                            onTap: () => _goTo(_currentIndex - 1),
                          ),
                        ),
                      ),
                    if (!isLast)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _ArrowButton(
                            icon: Icons.chevron_right,
                            onTap: () => _goTo(_currentIndex + 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.platform});

  final SocialPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      alignment: Alignment.center,
      child: FaIcon(_icon, size: 16, color: AppColors.paper),
    );
  }

  FaIconData get _icon {
    switch (platform) {
      case SocialPlatform.instagram:
        return FontAwesomeIcons.instagram;
      case SocialPlatform.facebook:
        return FontAwesomeIcons.facebook;
      case SocialPlatform.linkedin:
        return FontAwesomeIcons.linkedin;
      case SocialPlatform.spotify:
        return FontAwesomeIcons.spotify;
      case SocialPlatform.github:
        return FontAwesomeIcons.github;
      case SocialPlatform.twitter:
        return FontAwesomeIcons.xTwitter;
      case SocialPlatform.tiktok:
        return FontAwesomeIcons.tiktok;
      case SocialPlatform.youtube:
        return FontAwesomeIcons.youtube;
      case SocialPlatform.snapchat:
        return FontAwesomeIcons.snapchat;
      case SocialPlatform.discord:
        return FontAwesomeIcons.discord;
      case SocialPlatform.generic:
        return FontAwesomeIcons.link;
    }
  }

  Color get _color {
    switch (platform) {
      case SocialPlatform.instagram:
        return AppColors.pink;
      case SocialPlatform.facebook:
        return const Color(0xFF1877F2);
      case SocialPlatform.linkedin:
        return const Color(0xFF0A66C2);
      case SocialPlatform.spotify:
        return const Color(0xFF1DB954);
      case SocialPlatform.github:
        return const Color(0xFF333333);
      case SocialPlatform.twitter:
        return const Color(0xFF000000);
      case SocialPlatform.tiktok:
        return const Color(0xFF010101);
      case SocialPlatform.youtube:
        return const Color(0xFFFF0000);
      case SocialPlatform.snapchat:
        return const Color(0xFFFFFC00);
      case SocialPlatform.discord:
        return const Color(0xFF5865F2);
      case SocialPlatform.generic:
        return AppColors.yellow;
    }
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 150,
      color: AppColors.cyan,
      alignment: Alignment.center,
      child: const Text(
        'PHOTO',
        style: TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

String _formatPoints(int points) {
  final str = points.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}
