import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';
import 'package:seniors_27/features/dashboard/models/daily_highlight.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';

typedef HighlightUploadProgress = void Function(int sent, int total);

typedef HighlightSubmitCallback =
    Future<void> Function({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds,
      HighlightUploadProgress? onSendProgress,
    });

class AddHighlightSheet extends StatefulWidget {
  final HighlightSubmitCallback? onHighlightSubmitted;
  @visibleForTesting
  final DailyHighlightsApiService? apiService;
  @visibleForTesting
  final XFile? initialImage;
  @visibleForTesting
  final ui.Size? initialImageSize;

  const AddHighlightSheet({
    super.key,
    this.onHighlightSubmitted,
    this.apiService,
    this.initialImage,
    this.initialImageSize,
  });

  static Future<void> show(
    BuildContext context, {
    HighlightSubmitCallback? onHighlightSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddHighlightSheet(onHighlightSubmitted: onHighlightSubmitted),
    );
  }

  @override
  State<AddHighlightSheet> createState() => _AddHighlightSheetState();
}

class _AddHighlightSheetState extends State<AddHighlightSheet> {
  final ImagePicker _picker = ImagePicker();
  late final DailyHighlightsApiService _api;
  final ScrollController _scrollController = ScrollController();

  XFile? _image;
  ui.Size? _imageSize;
  bool _isSubmitting = false;
  bool _isProcessing = false;
  int _sentBytes = 0;
  int _totalBytes = 0;

  String _captionText = '';
  double _captionYPercent = 0.5;
  bool _isEditingCaption = false;
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocus = FocusNode();

  List<DailyHighlightUser> _selectedMentions = [];
  List<DailyHighlightUser> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  int _searchRequestId = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey _mentionFieldKey = GlobalKey();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? DailyHighlightsApiService(ApiClient());
    _image = widget.initialImage;
    _imageSize = widget.initialImageSize;
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _captionController.dispose();
    _captionFocus.dispose();
    _searchController.dispose();
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (_searchFocus.hasFocus) {
      Future<void>.delayed(
        const Duration(milliseconds: 150),
        _ensureMentionFieldVisible,
      );
    }
  }

  void _ensureMentionFieldVisible() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _mentionFieldKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.15,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final stopwatch = Stopwatch()..start();
      final XFile? selected = await _picker.pickImage(source: source);
      final pickedMs = stopwatch.elapsedMilliseconds;
      if (selected != null) {
        _imageSize = null;
        final file = File(selected.path);
        final completer = Completer<ui.Size>();
        final stream = FileImage(file).resolve(const ImageConfiguration());
        stream.addListener(
          ImageStreamListener(
            (info, _) {
              if (!completer.isCompleted) {
                completer.complete(
                  ui.Size(
                    info.image.width.toDouble(),
                    info.image.height.toDouble(),
                  ),
                );
              }
            },
            onError: (error, stackTrace) {
              if (!completer.isCompleted) {
                completer.completeError(error, stackTrace);
              }
            },
          ),
        );
        final size = await completer.future;
        if (!mounted) return;
        appDebugLog(
          '[HighlightImage] pickMs=$pickedMs '
          'decodeMs=${stopwatch.elapsedMilliseconds - pickedMs} '
          'width=${size.width.round()} height=${size.height.round()}',
        );
        setState(() {
          _image = selected;
          _imageSize = size;
          _captionText = '';
          _captionYPercent = 0.5;
          _captionController.clear();
          _isEditingCaption = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    _debounce?.cancel();
    final requestId = ++_searchRequestId;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (trimmed.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchError = null;
        });
        return;
      }
      _performSearch(trimmed, requestId: requestId);
    });
  }

  Future<void> _performSearch(String query, {required int requestId}) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      appDebugLog('[MentionSearch] search started requestId=$requestId');
      final results = await _api.searchUsers(query: query);
      if (!mounted) return;
      if (requestId != _searchRequestId) {
        appDebugLog('[MentionSearch] ignored stale response');
        return;
      }
      appDebugLog('[MentionSearch] itemCount=${results.length}');
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (requestId != _searchRequestId) return;
      appDebugLog('[MentionSearch] errorStatus=${e.statusCode}');
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = _resolveSearchErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      if (requestId != _searchRequestId) return;
      appDebugLog('[MentionSearch] unexpected error');
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = 'Could not search seniors. Try again.';
      });
    }
  }

  String _resolveSearchErrorMessage(ApiException e) {
    if (e.statusCode == 401) return 'Session expired. Please log in again.';
    if (e.statusCode == 400) {
      if (e.data is Map) {
        return (e.data as Map)['message']?.toString() ??
            (e.data as Map)['error']?.toString() ??
            'Invalid search request.';
      }
      return 'Invalid search request.';
    }
    return 'Could not search seniors. Try again.';
  }

  void _toggleMention(DailyHighlightUser user) {
    setState(() {
      if (_selectedMentions.any((m) => m.id == user.id)) {
        _selectedMentions.removeWhere((m) => m.id == user.id);
      } else {
        _selectedMentions = [..._selectedMentions, user];
      }
    });
  }

  void _removeMention(int id) {
    setState(() {
      _selectedMentions.removeWhere((m) => m.id == id);
    });
  }

  void _startCaptionEdit() {
    _captionController.text = _captionText;
    setState(() => _isEditingCaption = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _captionFocus.requestFocus();
    });
  }

  String get _latestCaptionText {
    final raw = _isEditingCaption ? _captionController.text : _captionText;
    return raw.trim();
  }

  void _finishCaptionEdit() {
    final trimmed = _captionController.text.trim();
    setState(() {
      _captionText = trimmed;
      _captionController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      _isEditingCaption = false;
    });
  }

  void _removeCaption() {
    setState(() {
      _captionText = '';
      _captionController.clear();
      _isEditingCaption = false;
    });
  }

  void _handleSendProgress(int sent, int total) {
    if (!mounted) return;
    final safeSent = sent < 0 ? 0 : sent;
    final safeTotal = total < 0 ? 0 : total;
    final isProcessing = safeTotal > 0 && safeSent >= safeTotal;
    if (_sentBytes == safeSent &&
        _totalBytes == safeTotal &&
        _isProcessing == isProcessing) {
      return;
    }
    setState(() {
      _sentBytes = safeSent;
      _totalBytes = safeTotal;
      _isProcessing = isProcessing;
    });
  }

  Future<void> _submit() async {
    if (_image == null || _isSubmitting) return;
    final image = _image!;
    final caption = _latestCaptionText;
    final captionYPercent = _captionYPercent;
    final mentionUserIds = _selectedMentions.map((m) => m.id).toList();
    if (_captionFocus.hasFocus) {
      _captionFocus.unfocus();
    }
    setState(() {
      _captionText = caption;
      _isEditingCaption = false;
      _isSubmitting = true;
      _isProcessing = false;
      _sentBytes = 0;
      _totalBytes = 0;
    });

    appDebugLog(
      '[HighlightSubmit] width=${_imageSize?.width.round() ?? 'unknown'} '
      'height=${_imageSize?.height.round() ?? 'unknown'}',
    );

    final stopwatch = Stopwatch()..start();
    try {
      await widget.onHighlightSubmitted?.call(
        filePath: image.path,
        captionText: caption.isEmpty ? null : caption,
        captionYPercent: caption.isEmpty ? null : captionYPercent,
        mentionUserIds: mentionUserIds,
        onSendProgress: _handleSendProgress,
      );
      appDebugLog(
        '[HighlightSubmit] completed elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    } catch (e) {
      if (mounted) {
        String message;
        if (e is ApiException) {
          if (e.statusCode == 429) {
            message =
                'Too many upload attempts. Please wait a moment and try again.';
          } else if (e.statusCode == 400) {
            message = e.data is Map
                ? (e.data as Map)['message']?.toString() ??
                      (e.data as Map)['error']?.toString() ??
                      'Invalid request. Please try again.'
                : 'Invalid request. Please try again.';
          } else {
            message = 'Error submitting highlight. Please try again.';
          }
        } else {
          message = 'Error submitting highlight. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isProcessing = false;
          _sentBytes = 0;
          _totalBytes = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.ink, width: 4)),
        ),
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADD HIGHLIGHT',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_image == null) _buildSourceButtons(),
            if (_image != null) _buildEditor(),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButtons() {
    return Row(
      children: [
        Expanded(
          child: RetroButton(
            label: 'CAMERA',
            height: 50,
            backgroundColor: AppColors.cyan,
            onPressed: () => _pickImage(ImageSource.camera),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: RetroButton(
            label: 'GALLERY',
            height: 50,
            backgroundColor: AppColors.yellow,
            onPressed: () => _pickImage(ImageSource.gallery),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePreview(),
        const SizedBox(height: 16),
        _buildCaptionInfo(),
        const SizedBox(height: 16),
        _buildMentionSection(),
        if (_isSubmitting) ...[
          const SizedBox(height: 16),
          _buildUploadStatus(),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: RetroButton(
            label: _isSubmitting
                ? (_isProcessing ? 'PROCESSING...' : 'UPLOADING...')
                : 'SUBMIT HIGHLIGHT',
            height: 54,
            backgroundColor: AppColors.pink,
            onPressed: _isSubmitting ? null : _submit,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadStatus() {
    final hasTotal = _totalBytes > 0;
    final progress = hasTotal
        ? (_sentBytes / _totalBytes).clamp(0.0, 1.0).toDouble()
        : null;
    final label = _isProcessing
        ? 'PROCESSING HIGHLIGHT...'
        : progress == null
        ? 'UPLOADING PHOTO...'
        : 'UPLOADING PHOTO ${(progress * 100).round()}%';
    return Semantics(
      label: label,
      value: progress == null ? null : '${(progress * 100).round()}%',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cyan,
          border: Border.all(color: AppColors.ink, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: _isProcessing ? null : progress,
              minHeight: 8,
              color: AppColors.ink,
              backgroundColor: AppColors.paper,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Stack(
        children: [
          RetroCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 300,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final container = ui.Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final imageSize = _imageSize;
                    if (imageSize == null) {
                      return const SizedBox();
                    }
                    final rect = fittedRect(container, imageSize);
                    final maxTravel = rect.height - _captionBandHeight;
                    final captionTop =
                        rect.top +
                        _captionYPercent.clamp(0.0, 1.0) *
                            (maxTravel > 0 ? maxTravel : 0);

                    return Stack(
                      children: [
                        Center(
                          child: Image.file(
                            File(_image!.path),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isEditingCaption ? null : _startCaptionEdit,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.transparent,
                          ),
                        ),
                        if (_captionText.isNotEmpty || _isEditingCaption)
                          Positioned(
                            top: captionTop.clamp(
                              rect.top,
                              rect.bottom - _captionBandHeight,
                            ),
                            left: rect.left,
                            width: rect.width,
                            child: GestureDetector(
                              onVerticalDragUpdate: (details) {
                                final oldTop =
                                    rect.top +
                                    _captionYPercent *
                                        (maxTravel > 0 ? maxTravel : 0);
                                final newTop = (oldTop + details.delta.dy)
                                    .clamp(rect.top, rect.top + maxTravel);
                                setState(() {
                                  _captionYPercent = maxTravel > 0
                                      ? (newTop - rect.top) / maxTravel
                                      : 0.5;
                                });
                              },
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: _captionBandHeight,
                                ),
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: _isEditingCaption
                                    ? TextField(
                                        controller: _captionController,
                                        focusNode: _captionFocus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        minLines: 1,
                                        decoration:
                                            const InputDecoration.collapsed(
                                              hintText: 'Type caption...',
                                              hintStyle: TextStyle(
                                                color: Colors.white38,
                                              ),
                                            ),
                                        onSubmitted: (_) =>
                                            _finishCaptionEdit(),
                                      )
                                    : GestureDetector(
                                        onTap: _startCaptionEdit,
                                        child: Text(
                                          _captionText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        if (_isEditingCaption && _captionText.isNotEmpty)
                          Positioned(
                            top: captionTop.clamp(
                              rect.top,
                              rect.bottom - _captionBandHeight,
                            ),
                            right: rect.left + 4,
                            child: GestureDetector(
                              onTap: _removeCaption,
                              child: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: AppColors.ink,
                child: Icon(Icons.close, color: AppColors.white, size: 20),
              ),
              onPressed: () => setState(() {
                _image = null;
                _imageSize = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  double get _captionBandHeight => 40.0;

  Widget _buildCaptionInfo() {
    if (_captionText.isEmpty && !_isEditingCaption) {
      return GestureDetector(
        onTap: _startCaptionEdit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
          child: const Text(
            'Tap image to add caption',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.text_fields, size: 16, color: AppColors.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _captionText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          GestureDetector(
            key: const ValueKey('highlight-remove-caption'),
            onTap: _removeCaption,
            child: const Icon(Icons.close, size: 16, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MENTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedMentions.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _selectedMentions.map((user) {
              return Chip(
                label: Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => _removeMention(user.id),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          key: _mentionFieldKey,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 120,
            ),
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search seniors...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 4),
        _buildSearchState(),
      ],
    );
  }

  Widget _buildSearchState() {
    final queryEmpty = _searchController.text.trim().isEmpty;

    if (queryEmpty && !_isSearching) {
      return _buildStateMessage('Type a name to search seniors.');
    }

    if (_isSearching) {
      return _buildStateMessage('Searching...');
    }

    if (_searchError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300, width: 1),
          color: Colors.red.shade50,
        ),
        child: Text(
          _searchError!,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && !queryEmpty) {
      return _buildStateMessage('No seniors found.');
    }

    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (ctx, i) {
          final user = _searchResults[i];
          final selected = _selectedMentions.any((m) => m.id == user.id);
          return Material(
            type: MaterialType.transparency,
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundImage:
                    user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              title: Text(
                user.username,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: selected
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 20,
                    )
                  : const Icon(Icons.add_circle_outline, size: 20),
              onTap: () => _toggleMention(user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 1),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
