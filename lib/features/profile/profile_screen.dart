import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/auth/data/auth_api_service.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_photo_placeholder.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onOpenNotes, super.key});

  final VoidCallback onOpenNotes;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = AuthApiService(ApiClient());
  ProfileUser? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getMe();
      final data = response.data;
      if (!mounted) return;
      if (data is Map<String, dynamic>) {
        setState(() {
          _user = ProfileUser.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Unexpected response format.';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('profile_scroll'),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Stack(
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
          const SizedBox(height: 24),
          _buildBody(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: RetroButton(
              label: 'OPEN NOTES',
              height: 46,
              backgroundColor: AppColors.orange,
              onPressed: widget.onOpenNotes,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Text(
            'Loading profile...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const Text(
                'Could not load profile.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 100,
                child: RetroButton(
                  label: 'Retry',
                  height: 36,
                  onPressed: _loadProfile,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    return _ProfileCard(user: user);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RetroCard(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            children: [
              Center(
                child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? ClipRect(
                        child: Image.network(
                          user.photoUrl!,
                          width: 140,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const RetroPhotoPlaceholder(
                                label: 'PHOTO',
                                width: 140,
                                height: 180,
                                backgroundColor: AppColors.cyan,
                              ),
                        ),
                      )
                    : const RetroPhotoPlaceholder(
                        label: 'PHOTO',
                        width: 140,
                        height: 180,
                        backgroundColor: AppColors.cyan,
                      ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name.toUpperCase() : '—',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (user.role.isNotEmpty)
                      Text(
                        user.role,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (user.description.isNotEmpty)
                      Text(
                        user.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 12),
                    _buildMetaSection(user),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -6,
          child: Transform.rotate(
            angle: 0.15,
            child: const RetroSticker(
              color: AppColors.pink,
              width: 36,
              height: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaSection(ProfileUser user) {
    final hasMeta =
        user.gender.isNotEmpty ||
        user.email.isNotEmpty ||
        user.points != null ||
        user.status != null;

    if (!hasMeta) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        children: [
          if (user.gender.isNotEmpty)
            _MetaLine(label: 'Gender', value: user.gender),
          if (user.gender.isNotEmpty && user.email.isNotEmpty)
            const SizedBox(height: 4),
          if (user.email.isNotEmpty)
            _MetaLine(label: 'Email', value: user.email),
          if (user.email.isNotEmpty && user.points != null)
            const SizedBox(height: 4),
          if (user.points != null)
            _MetaLine(label: 'Points', value: user.points.toString()),
          if (user.points != null && user.status != null)
            const SizedBox(height: 4),
          if (user.status != null && user.status!.isNotEmpty)
            _MetaLine(label: 'Status', value: user.status!),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
