import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';

class EditProfilePhotoScreen extends StatefulWidget {
  final String? currentPhotoUrl;

  const EditProfilePhotoScreen({super.key, required this.currentPhotoUrl});

  @override
  State<EditProfilePhotoScreen> createState() => _EditProfilePhotoScreenState();
}

class _EditProfilePhotoScreenState extends State<EditProfilePhotoScreen> {
  final ProfileApiService _api = ProfileApiService(ApiClient());
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  bool _saving = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      final croppedPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => _CropScreen(imageBytes: bytes)),
      );

      if (croppedPath != null && mounted) {
        setState(() {
          _selectedImagePath = croppedPath;
          _error = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_selectedImagePath == null || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final photoUrl = await _api.updateProfilePhoto(_selectedImagePath!);
      if (mounted) Navigator.of(context).pop(photoUrl);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Upload failed (${e.statusCode}): ${e.data ?? e.message}';
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Upload failed: $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedImagePath != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: const Text(
          'EDIT PROFILE PHOTO',
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
            Center(
              child: RetroPhotoFrame(
                child: hasSelection
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.file(
                          File(_selectedImagePath!),
                          width: 120,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.currentPhotoUrl != null &&
                          widget.currentPhotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.network(
                          widget.currentPhotoUrl!,
                          width: 120,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _EditorPhotoPlaceholder(),
                        ),
                      )
                    : const _EditorPhotoPlaceholder(),
              ),
            ),
            const SizedBox(height: 24),
            if (!hasSelection) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
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
                            'CAMERA',
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
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
                            'GALLERY',
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
            ] else ...[
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
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
                      'RETAKE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
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
                      'CHOOSE FROM GALLERY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                onTap: (_saving || !hasSelection) ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _saving || !hasSelection
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
                            'SAVE PHOTO',
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

class RetroPhotoFrame extends StatelessWidget {
  final Widget child;
  const RetroPhotoFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: child,
    );
  }
}

class _EditorPhotoPlaceholder extends StatelessWidget {
  const _EditorPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 150,
      color: AppColors.paper,
      alignment: Alignment.center,
      child: const Text(
        'NO PHOTO',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const _CropScreen({required this.imageBytes});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final CropController _cropController = CropController();
  bool _cropping = false;
  String? _error;

  Future<void> _handleCropResult(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final file = File(
            '${Directory.systemTemp.path}/crop_${timestamp}_$timestamp.jpg',
          );
          await file.writeAsBytes(croppedImage);
          if (mounted) Navigator.of(context).pop(file.path);
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = 'Failed to save cropped image: $e';
              _cropping = false;
            });
          }
        }
      case CropFailure(:final cause):
        if (mounted) {
          setState(() {
            _error = 'Crop failed: $cause';
            _cropping = false;
          });
        }
    }
  }

  void _onDone() {
    setState(() {
      _cropping = true;
      _error = null;
    });
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'CROP PROFILE PHOTO',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.paper,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _cropController,
              aspectRatio: 4 / 5,
              interactive: true,
              fixCropRect: true,
              baseColor: Colors.black,
              maskColor: Colors.black54,
              progressIndicator: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.paper,
                ),
              ),
              onCropped: _handleCropResult,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppColors.ink,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: AppColors.ink, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'CANCEL',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.ink,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _cropping ? null : _onDone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _cropping ? AppColors.muted : AppColors.paper,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check,
                          color: _cropping ? AppColors.ink : AppColors.ink,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _cropping ? '...' : 'DONE',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.ink,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
