import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_text_field.dart';

class AddMemorySheet extends StatefulWidget {
  const AddMemorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMemorySheet(),
    );
  }

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? selected = await _picker.pickImage(source: source);
      if (selected != null) {
        setState(() {
          _image = selected;
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 4)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        24,
        22,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADD MEMORY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          if (_image == null) ...[
            Row(
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
            ),
          ] else ...[
            Center(
              child: Stack(
                children: [
                  RetroCard(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.file(File(_image!.path), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: AppColors.ink,
                        child: Icon(
                          Icons.close,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => setState(() => _image = null),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'DESCRIPTION (OPTIONAL)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            RetroTextField(
              controller: _descriptionController,
              hintText: 'What happened?',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: RetroButton(
                label: 'SUBMIT MEMORY',
                height: 54,
                backgroundColor: AppColors.pink,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Memory submitted locally. API integration later.',
                      ),
                      backgroundColor: AppColors.ink,
                    ),
                  );
                },
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
