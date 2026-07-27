import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/notes/data/notes_api_service.dart';
import 'package:seniors_27/features/notes/models/note.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/note_card.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class NotesOpenBookScreen extends StatefulWidget {
  const NotesOpenBookScreen({
    required this.onBackToProfile,
    this.openedFromProfile = false,
    super.key,
  });

  final VoidCallback onBackToProfile;
  final bool openedFromProfile;

  @override
  State<NotesOpenBookScreen> createState() => _NotesOpenBookScreenState();
}

class _NotesOpenBookScreenState extends State<NotesOpenBookScreen> {
  final _api = NotesApiService(ApiClient());
  List<Note> _notes = [];
  String _currentUserId = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      try {
        final meRes = await _api.getMe();
        final meData = meRes.data;
        if (meData is Map) {
          _currentUserId =
              (meData['id'] as num?)?.toString() ??
              meData['id'] as String? ??
              '';
        }
      } catch (_) {}

      final notesRes = await _api.getReceivedNotes(_currentUserId);
      final notesData = notesRes.data;

      List<Note> parsed = [];
      if (notesData is Map) {
        for (final key in ['items', 'data', 'results', 'notes']) {
          final val = notesData[key];
          if (val is List) {
            parsed = val
                .map((e) => Note.fromJson(e as Map<String, dynamic>))
                .toList();
            break;
          }
        }
      } else if (notesData is List) {
        parsed = notesData
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (mounted) {
        setState(() {
          _notes = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notes.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleReaction(Note note, String type) async {
    final isCurrentlyReacted = type == 'Like' ? note.likedByMe : note.lovedByMe;
    final newLiked = type == 'Like' ? !note.likedByMe : note.likedByMe;
    final newLoved = type == 'Love' ? !note.lovedByMe : note.lovedByMe;
    final newLikeCount = type == 'Like'
        ? (note.likeCount ?? 0) + (isCurrentlyReacted ? -1 : 1)
        : note.likeCount;
    final newLoveCount = type == 'Love'
        ? (note.loveCount ?? 0) + (isCurrentlyReacted ? -1 : 1)
        : note.loveCount;

    setState(() {
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx >= 0) {
        _notes[idx] = _notes[idx].copyWith(
          likedByMe: newLiked,
          lovedByMe: newLoved,
          likeCount: newLikeCount != null && newLikeCount < 0
              ? 0
              : newLikeCount,
          loveCount: newLoveCount != null && newLoveCount < 0
              ? 0
              : newLoveCount,
        );
      }
    });

    try {
      final res = await _api.addReaction(note.id, type);
      debugPrint('[Notes] reaction status: ${res.statusCode}');
      debugPrint('[Notes] reaction response type: ${res.data.runtimeType}');
      if (res.data is Map) {
        debugPrint(
          '[Notes] reaction response keys: ${(res.data as Map).keys.toList()}',
        );
      }
      debugPrint('[Notes] reaction data: ${res.data}');

      if (res.data is Map) {
        final data = res.data as Map;
        final serverLikeCount = data['likeCount'] ?? data['likesCount'];
        final serverLoveCount = data['loveCount'] ?? data['lovesCount'];
        final serverLiked = data['likedByMe'] ?? data['isLikedByMe'];
        final serverLoved = data['lovedByMe'] ?? data['isLovedByMe'];
        if (serverLikeCount != null ||
            serverLoveCount != null ||
            serverLiked != null ||
            serverLoved != null) {
          setState(() {
            final idx = _notes.indexWhere((n) => n.id == note.id);
            if (idx >= 0) {
              _notes[idx] = _notes[idx].copyWith(
                likedByMe: serverLiked as bool? ?? _notes[idx].likedByMe,
                lovedByMe: serverLoved as bool? ?? _notes[idx].lovedByMe,
                likeCount: serverLikeCount is num
                    ? serverLikeCount.toInt()
                    : _notes[idx].likeCount,
                loveCount: serverLoveCount is num
                    ? serverLoveCount.toInt()
                    : _notes[idx].loveCount,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[Notes] reaction error: $e');
      setState(() {
        final idx = _notes.indexWhere((n) => n.id == note.id);
        if (idx >= 0) {
          _notes[idx] = _notes[idx].copyWith(
            likedByMe: note.likedByMe,
            lovedByMe: note.lovedByMe,
            likeCount: note.likeCount,
            loveCount: note.loveCount,
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to react: $e')));
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        title: const Text(
          'DELETE NOTE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: AppColors.pink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteNote(note.id);
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note deleted')));
      }
    } catch (e) {
      debugPrint('[Notes] delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  bool _canDeleteNote(Note note) {
    if (note.canDelete == true) return true;
    if (note.isOwnedByCurrentUser == true) return true;
    if (note.isCreatedByCurrentUser == true) return true;
    if (note.senderId.isNotEmpty && note.senderId == _currentUserId) {
      return true;
    }
    if (note.recipientId.isNotEmpty && note.recipientId == _currentUserId) {
      return true;
    }
    return false;
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('notes_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onBackToProfile,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.orange,
                border: Border.all(color: AppColors.ink, width: 3),
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                '\u2190',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const MainPageHeader(
            title: 'Open Book',
            subtitle: 'Latest notes from seniors.',
          ),
          const SizedBox(height: 30),
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.openedFromProfile)
                const RetroSectionHeader(
                  title: 'NOTES',
                  backgroundColor: AppColors.orange,
                )
              else
                Row(
                  children: [
                    const Expanded(
                      child: RetroSectionHeader(
                        title: 'NOTES',
                        backgroundColor: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: RetroButton(
                        label: 'ADD NOTE',
                        height: 42,
                        backgroundColor: AppColors.green,
                        onPressed: () {},
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              Positioned(
                top: -15,
                left: 20,
                child: Transform.rotate(
                  angle: -0.1,
                  child: const RetroSticker(
                    color: AppColors.cyan,
                    width: 40,
                    height: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  'Loading notes...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Error: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 120,
                      child: RetroButton(
                        label: 'RETRY',
                        height: 38,
                        backgroundColor: AppColors.pink,
                        onPressed: _loadData,
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_notes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  'No notes yet.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            for (var index = 0; index < _notes.length; index++) ...[
              Transform.rotate(
                angle: (index % 2 == 0 ? -1.0 : 1.0) * math.pi / 180,
                child: NoteCard(
                  senderName: _notes[index].senderName.isNotEmpty
                      ? _notes[index].senderName
                      : 'Anonymous',
                  date: _notes[index].createdAt.isNotEmpty
                      ? _formatDate(_notes[index].createdAt)
                      : '',
                  content: _notes[index].content,
                  loveCount: _notes[index].loveCount,
                  likedByMe: _notes[index].likedByMe,
                  lovedByMe: _notes[index].lovedByMe,
                  onLove: () => _toggleReaction(_notes[index], 'Love'),
                  onLike: () => _toggleReaction(_notes[index], 'Like'),
                  canDelete: _canDeleteNote(_notes[index]),
                  onDelete: () => _deleteNote(_notes[index]),
                ),
              ),
              const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }
}
