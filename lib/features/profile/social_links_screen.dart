import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:seniors_27/features/profile/models/social_link.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({
    required this.initialLinks,
    required this.onSaved,
    super.key,
  });

  final List<String> initialLinks;
  final VoidCallback onSaved;

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final _api = ProfileApiService(ApiClient());
  final _urlController = TextEditingController();
  final _focusNode = FocusNode();

  late List<String> _links;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _links = List.from(widget.initialLinks);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isValidUrl {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return false;
    final url = SocialLink.normalizeUrl(raw);
    return Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  bool get _canAdd => _links.length < 8 && _isValidUrl;

  bool _isDuplicate(String normalized) {
    return _links.any(
      (existing) =>
          SocialLink.normalizeUrl(existing).toLowerCase() ==
          normalized.toLowerCase(),
    );
  }

  void _addLink() {
    if (!_canAdd) return;
    final raw = _urlController.text.trim();
    final normalized = SocialLink.normalizeUrl(raw);
    if (_isDuplicate(normalized)) {
      setState(() => _error = 'This link already exists.');
      return;
    }
    setState(() {
      _links.add(normalized);
      _urlController.clear();
      _error = null;
    });
    _focusNode.requestFocus();
  }

  void _removeLink(int index) {
    setState(() => _links.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _links.removeAt(oldIndex);
      _links.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await _api.updateSocialLinks(_links);
      final data = response.data;
      final saved = (data is Map ? data['socialLinks'] : null);
      if (saved is List) {
        _links = saved.whereType<String>().toList();
      }
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save social links. Please try again.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputArea(),
                    const SizedBox(height: 16),
                    if (_links.isNotEmpty) _buildLinksList(),
                    if (_links.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'No social links yet.\nTap + ADD to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_error != null) _buildErrorBanner(),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'SOCIAL LINKS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
              child: const Text(
                'X',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
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
                    focusNode: _focusNode,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _addLink(),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    cursorColor: AppColors.ink,
                    decoration: const InputDecoration(
                      hintText: 'Paste a link...',
                      hintStyle: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _canAdd ? _addLink : null,
                child: Container(
                  width: 56,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _canAdd ? AppColors.yellow : AppColors.muted,
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
                  child: const Text(
                    '+ADD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Paste any profile link or email address and we will automatically show the right icon.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.muted.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_links.length}/8 links',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _links.length,
      onReorderItem: _onReorder,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          color: Colors.transparent,
          shadowColor: AppColors.ink.withValues(alpha: 0.3),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final link = SocialLink.fromUrl(_links[index]);
        return _LinkRow(
          key: ValueKey(_links[index]),
          link: link,
          index: index,
          onRemove: () => _removeLink(index),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.pink,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _error ?? '',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Text(
              'DISMISS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'CANCEL',
              backgroundColor: AppColors.paper,
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: _saving ? 'SAVING...' : 'SAVE LINKS',
              backgroundColor: AppColors.yellow,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: onPressed != null
              ? const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: onPressed != null ? AppColors.ink : AppColors.muted,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.link,
    required this.index,
    required this.onRemove,
    super.key,
  });

  final SocialLink link;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(link.url),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 52,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.ink.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Icon(
              Icons.drag_indicator,
              color: AppColors.muted.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
          // Platform icon
          const SizedBox(width: 10),
          _PlatformCircle(platform: link.platform),
          const SizedBox(width: 10),
          // URL
          Expanded(
            child: Text(
              link.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 36,
              height: 52,
              alignment: Alignment.center,
              child: const Text(
                'X',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformCircle extends StatelessWidget {
  const _PlatformCircle({required this.platform});

  final SocialPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: platformColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      alignment: Alignment.center,
      child: FaIcon(platformIcon, size: 14, color: AppColors.paper),
    );
  }

  FaIconData get platformIcon {
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

  Color get platformColor {
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
