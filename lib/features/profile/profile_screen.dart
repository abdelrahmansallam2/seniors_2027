import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/notes/data/notes_api_service.dart';
import 'package:seniors_27/features/notes/models/note.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';
import 'package:seniors_27/features/profile/data/profile_gallery_api_service.dart';
import 'package:seniors_27/features/profile/models/profile_gallery_photo.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';
import 'package:seniors_27/shared/widgets/note_card.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onOpenNotes, super.key});

  final VoidCallback onOpenNotes;

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

  List<Note> _latestNotes = [];
  int _totalNotesCount = 0;
  bool _notesLoading = true;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _profileApi.getMe();
      final data = response.data;
      debugPrint('[Profile] /api/Auth/me response type: ${data.runtimeType}');

      if (data is Map<String, dynamic>) {
        debugPrint('[Profile] /api/Auth/me keys: ${data.keys.toList()}');
        final parsed = ProfileUser.fromJson(data);
        debugPrint(
          '[Profile] parsed user: id=${parsed.id}, name=${parsed.name}, '
          'email=${parsed.email}, photoUrl=${parsed.photoUrl}',
        );

        if (mounted) {
          setState(() {
            _user = parsed;
          });
          _loadGallery(parsed.id);
          _loadLatestNotes(parsed.id);
        }
      } else {
        debugPrint(
          '[Profile] unexpected /api/Auth/me type: ${data.runtimeType}',
        );
        if (mounted) {
          _loadGallery(_user.id);
          _loadLatestNotes(_user.id);
        }
      }
    } catch (e) {
      debugPrint('[Profile] /api/Auth/me error: $e');
      if (mounted) {
        _loadGallery('');
        _loadLatestNotes('');
      }
    }
  }

  Future<void> _loadGallery(String userId) async {
    setState(() {
      _galleryLoading = true;
      _galleryError = null;
    });

    try {
      final response = await _galleryApi.getUserGallery(userId);
      final data = response.data;

      debugPrint('[Profile] gallery response type: ${data.runtimeType}');

      List<dynamic> itemsList;

      if (data is List) {
        debugPrint('[Profile] gallery raw list length: ${data.length}');
        itemsList = data;
      } else if (data is Map) {
        debugPrint('[Profile] gallery keys: ${data.keys.toList()}');
        itemsList =
            (data['items'] as List<dynamic>?) ??
            (data['photos'] as List<dynamic>?) ??
            (data['results'] as List<dynamic>?) ??
            (data['data'] as List<dynamic>?) ??
            [];
        debugPrint('[Profile] gallery items length: ${itemsList.length}');
      } else {
        debugPrint('[Profile] unexpected gallery type: ${data.runtimeType}');
        itemsList = [];
      }

      if (itemsList.isNotEmpty) {
        final first = itemsList.first;
        if (first is Map) {
          debugPrint(
            '[Profile] gallery first item keys: ${first.keys.toList()}',
          );
        }
      }

      final parsed = itemsList
          .whereType<Map<String, dynamic>>()
          .map(ProfileGalleryPhoto.fromJson)
          .toList();

      if (parsed.isNotEmpty) {
        debugPrint(
          '[Profile] first 3 resolved URLs: ${parsed.take(3).map((p) => p.photoUrl).toList()}',
        );
      }

      if (mounted) {
        setState(() {
          _galleryPhotos = parsed;
          _galleryLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Profile] gallery fetch error: $e');
      if (mounted) {
        setState(() {
          _galleryError = 'Failed to load gallery.';
          _galleryLoading = false;
        });
      }
    }
  }

  Future<void> _loadLatestNotes(String recipientId) async {
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
          _notesError = 'Notes unavailable.';
          _notesLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return SingleChildScrollView(
      key: const PageStorageKey('profile_scroll'),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              MainPageHeader(
                title: 'My Profile',
                subtitle: 'Your senior identity.',
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
          GestureDetector(
            onTap: widget.onOpenNotes,
            child: _buildLatestNotes(),
          ),
          const SizedBox(height: 20),
          _buildGallerySection(),
        ],
      ),
    );
  }

  Widget _buildTopSection(ProfileUser user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RetroCard(
          padding: const EdgeInsets.all(6),
          child: user.photoUrl != null && user.photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    user.photoUrl!,
                    width: 120,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                  ),
                )
              : const _PhotoPlaceholder(),
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
              const SizedBox(height: 0),
              Text(
                user.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
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
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialAndSpotify() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSocialLinks()),
        const SizedBox(width: 12),
        Expanded(child: _buildSpotifyCard()),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SocialIcon(label: 'IG', color: AppColors.pink),
              const SizedBox(width: 10),
              _SocialIcon(label: 'GH', color: AppColors.green),
              const SizedBox(width: 10),
              _SocialIcon(label: 'LN', color: AppColors.cyan),
              const SizedBox(width: 10),
              _SocialIcon(label: 'SP', color: AppColors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpotifyCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 10),
        RetroCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.magenta,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.music_note,
                  size: 22,
                  color: AppColors.paper,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blinding Lights',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'The Weeknd',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: const Text(
                        'DISCONNECT',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
    final int stackCount = _galleryPhotos.length.clamp(0, 5);

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
        RetroCard(
          child: SizedBox(
            width: double.infinity,
            child: _galleryLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Loading gallery...',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : _galleryError != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          _galleryError!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _loadGallery(_user.id),
                          child: const Text(
                            'TAP TO RETRY',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _galleryPhotos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No photos yet.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _showGalleryViewer(
                      context,
                      _galleryPhotos,
                      initialIndex: 0,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 180,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: List.generate(stackCount, (i) {
                            final photo = _galleryPhotos[i];
                            final int behindCount = stackCount - 1 - i;
                            final double offsetDx = behindCount * -8.0;
                            final double offsetDy = behindCount * -10.0;
                            final double rotation = behindCount.isEven
                                ? 0.08
                                : -0.08;
                            final double scale = 1.0 - behindCount * 0.02;

                            return Positioned(
                              left: 20 + offsetDx,
                              top: 10 + offsetDy,
                              child: Transform.rotate(
                                angle: rotation,
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 140,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: AppColors.paper,
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.ink,
                                          offset: Offset(3, 3),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: ClipRect(
                                      child: Image.network(
                                        photo.photoUrl ?? '',
                                        width: 132,
                                        height: 172,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const _PhotoPlaceholder(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
          ),
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Image.network(
                      photo.photoUrl ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ArrowButton(
                      label: '<',
                      visible: !isFirst,
                      onTap: () => _goTo(_currentIndex - 1),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '${_currentIndex + 1} / ${photos.length}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 24),
                    _ArrowButton(
                      label: '>',
                      visible: !isLast,
                      onTap: () => _goTo(_currentIndex + 1),
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
  const _ArrowButton({
    required this.label,
    required this.visible,
    required this.onTap,
  });

  final String label;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox(width: 40, height: 40);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.paper,
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
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: AppColors.paper,
        ),
      ),
    );
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
