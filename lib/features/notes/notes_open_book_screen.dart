import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/notes/data/notes_api_service.dart';
import 'package:seniors_27/features/notes/models/note.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/note_card.dart';
import 'package:seniors_27/shared/widgets/retro_entrance.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class NotesOpenBookScreen extends StatefulWidget {
  const NotesOpenBookScreen({
    required this.onBackToProfile,
    this.openedFromProfile = false,
    this.userId,
    this.readOnly = false,
    this.apiService,
    super.key,
  });

  final VoidCallback onBackToProfile;
  final bool openedFromProfile;
  final String? userId;
  final bool readOnly;
  final NotesApiService? apiService;

  @override
  State<NotesOpenBookScreen> createState() => _NotesOpenBookScreenState();
}

class _NotesOpenBookScreenState extends State<NotesOpenBookScreen> {
  late final NotesApiService _api =
      widget.apiService ?? NotesApiService(ApiClient());
  List<Note> _notes = [];
  String _currentUserId = '';
  String _authUserId = '';
  bool _isLoading = true;
  bool _loadInFlight = false;
  String? _error;
  final Set<String> _reactingNoteIds = {};
  final Set<String> _deletingNoteIds = {};

  bool get _isMyProfileBook => !widget.readOnly && widget.userId == null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    final allNotes = <Note>[];
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentUserId = widget.userId?.trim() ?? '';
      _authUserId = '';
      try {
        final cached = CurrentUserCache.peek();
        final me = await CurrentUserCache.get(
          forceRefresh: cached != null && !_hasValidUserId(cached.id),
          fetcher: () async {
            final meRes = await _api.getMe();
            final meData = meRes.data;
            if (meData is Map) {
              final user = ProfileUser.fromJson(
                Map<String, dynamic>.from(meData),
              );
              if (_hasValidUserId(user.id)) return user;
            }
            throw const FormatException('Unexpected profile response.');
          },
        );
        _authUserId = me.id.trim();
      } catch (_) {
        // A visited book can still load without granting current-user actions.
        if (!_hasValidUserId(_currentUserId)) rethrow;
      }
      if (!mounted) return;
      if (_currentUserId.isEmpty) _currentUserId = _authUserId;
      if (!_hasValidUserId(_currentUserId)) {
        throw const FormatException('Profile identity is unavailable.');
      }

      final seenIds = <String>{};
      var pageNumber = 1;
      const pageSize = 20;
      int? totalCount;

      while (mounted) {
        final pageRes = await _api.getReceivedNotes(
          _currentUserId,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        if (!mounted) return;
        final pageData = pageRes.data;
        List<dynamic>? items;
        int? totalPages;

        if (pageData is Map) {
          totalCount ??= (pageData['totalCount'] as num?)?.toInt();
          totalPages = (pageData['totalPages'] as num?)?.toInt();
          for (final key in ['items', 'data', 'results', 'notes']) {
            if (pageData[key] is List) {
              items = pageData[key] as List;
              break;
            }
          }
        } else if (pageData is List) {
          totalCount ??= pageData.length;
          items = pageData;
        }
        if (items == null) {
          throw const FormatException('Unexpected notes response.');
        }

        var added = 0;
        for (final item in items) {
          if (item is! Map) {
            throw const FormatException('Unexpected note item.');
          }
          final note = Note.fromJson(Map<String, dynamic>.from(item));
          if (note.id.isEmpty) {
            throw const FormatException('A note has no identifier.');
          }
          if (seenIds.add(note.id)) {
            allNotes.add(note);
            added++;
          }
        }

        appDebugLog(
          '[Notes] page=$pageNumber returned=${items.length} '
          'loaded=${allNotes.length}',
        );
        if (items.isNotEmpty && added == 0) {
          throw const FormatException('Notes pagination did not advance.');
        }
        if (items.isEmpty ||
            (totalCount != null && allNotes.length >= totalCount) ||
            (totalPages != null && pageNumber >= totalPages) ||
            items.length < pageSize ||
            pageNumber >= 100) {
          break;
        }
        pageNumber++;
      }

      if (!mounted) return;
      allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _notes = allNotes;
        _isLoading = false;
      });
    } catch (error) {
      appDebugLog(
        '[Notes] load failed type=${error.runtimeType} '
        'status=${error is ApiException ? error.statusCode : null}',
      );
      if (!mounted) return;
      allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        if (allNotes.isNotEmpty) _notes = allNotes;
        _error = error is ApiException
            ? error.message
            : 'Failed to load notes. Please try again.';
        _isLoading = false;
      });
    } finally {
      _loadInFlight = false;
    }
  }

  static bool _hasValidUserId(String id) {
    final trimmed = id.trim();
    return trimmed.isNotEmpty && int.tryParse(trimmed) != 0;
  }

  Future<void> _toggleReaction(Note note, String type) async {
    if (_reactingNoteIds.contains(note.id)) return;
    setState(() => _reactingNoteIds.add(note.id));
    try {
      final res = await _api.addReaction(note.id, type);
      if (!mounted) return;
      if (res.data is Map) {
        final updated = Note.fromJson(res.data as Map<String, dynamic>);
        setState(() {
          final idx = _notes.indexWhere((n) => n.id == note.id);
          if (idx >= 0) {
            _notes[idx] = updated;
          }
        });
      }
    } catch (e) {
      appDebugLog(
        '[Notes] reaction failed status=${e is ApiException ? e.statusCode : null}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Failed to react. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reactingNoteIds.remove(note.id));
    }
  }

  bool _canDeleteOwnNote(Note note) {
    final authId = int.tryParse(_authUserId);
    final senderId = int.tryParse(note.senderId);
    if (authId == null || senderId == null) return false;
    if (authId != senderId) return false;
    return note.canDelete ?? true;
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

    if (!mounted || confirmed != true) return;
    if (_deletingNoteIds.contains(note.id)) return;
    setState(() => _deletingNoteIds.add(note.id));

    try {
      await _api.deleteNote(note.id);
      if (!mounted) return;
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
        _deletingNoteIds.remove(note.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note deleted')));
      }
    } catch (e) {
      appDebugLog(
        '[Notes] delete failed status=${e is ApiException ? e.statusCode : null}',
      );
      if (mounted) {
        setState(() => _deletingNoteIds.remove(note.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Failed to delete. Please retry.',
            ),
          ),
        );
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: RetroGridBackground(child: SizedBox.shrink())),
          SafeArea(
            child: SingleChildScrollView(
              key: const PageStorageKey('notes_scroll'),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
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
                      if (widget.openedFromProfile || widget.readOnly)
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.ink, width: 2),
                        borderRadius: BorderRadius.circular(12),
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
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading notes...'),
                        ],
                      ),
                    )
                  else if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.ink, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.ink,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(height: 12),
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
                    )
                  else if (_notes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.ink, width: 2),
                        borderRadius: BorderRadius.circular(12),
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
                          'No notes yet.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  if (!_isLoading && _notes.isNotEmpty && _error != null)
                    const SizedBox(height: 20),
                  if (!_isLoading && _notes.isNotEmpty)
                    for (var index = 0; index < _notes.length; index++) ...[
                      RetroEntrance(
                        key: ValueKey<String>(
                          'note_entrance_${_notes[index].id}',
                        ),
                        delay: RetroMotion.staggerDelay(index),
                        child: Transform.rotate(
                          angle: (index % 2 == 0 ? -1.0 : 1.0) * math.pi / 180,
                          child: NoteCard(
                            senderName: _notes[index].senderName.isNotEmpty
                                ? _notes[index].senderName
                                : 'Anonymous',
                            senderPhotoUrl: _notes[index].senderPhotoUrl,
                            date: _notes[index].createdAt.isNotEmpty
                                ? _formatDate(_notes[index].createdAt)
                                : '',
                            content: _notes[index].content,
                            loveCount: _notes[index].loveCount,
                            likeCount: _notes[index].likeCount,
                            likedByMe: _notes[index].likedByMe,
                            lovedByMe: _notes[index].lovedByMe,
                            onLove: () =>
                                _toggleReaction(_notes[index], 'Love'),
                            onLike: () =>
                                _toggleReaction(_notes[index], 'Ahaha'),
                            canDelete: _isMyProfileBook
                                ? _canDeleteNote(_notes[index])
                                : _canDeleteOwnNote(_notes[index]),
                            onDelete: () => _deleteNote(_notes[index]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
