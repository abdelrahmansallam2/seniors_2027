import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';

class EditDescriptionScreen extends StatefulWidget {
  final String currentDescription;

  const EditDescriptionScreen({super.key, required this.currentDescription});

  @override
  State<EditDescriptionScreen> createState() => _EditDescriptionScreenState();
}

class _EditDescriptionScreenState extends State<EditDescriptionScreen> {
  final ProfileApiService _api = ProfileApiService(ApiClient());
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _api.updateDescription(text);
      final response = await _api.getMe();
      final data = response.data;
      final user = ProfileUser.fromJson(
        data is Map ? data as Map<String, dynamic> : {},
      );
      if (mounted) Navigator.of(context).pop(user.description);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save description. Please try again.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: const Text(
          'EDIT DESCRIPTION',
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
            Container(
              width: double.infinity,
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
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Write something about yourself...',
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                onTap: (_saving || !hasText) ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _saving || !hasText
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
                            'SAVE DESCRIPTION',
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
        ),
      ),
    );
  }
}
