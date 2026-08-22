import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/photo_storage.dart';

/// Admin control for attaching a real photograph to an object or situation.
/// Takes a photo or picks from the gallery, copies it into local storage, and
/// reports the stored path via [onChanged] (null when removed).
class PhotoField extends StatefulWidget {
  final String? initialPath;
  final String idHint;
  final ValueChanged<String?> onChanged;

  const PhotoField({
    super.key,
    required this.initialPath,
    required this.idHint,
    required this.onChanged,
  });

  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<PhotoField> {
  final ImagePicker _picker = ImagePicker();
  late String? _path = widget.initialPath;
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (x == null) return;
      final saved = await PhotoStorage.save(x.path, widget.idHint);
      setState(() => _path = saved);
      widget.onChanged(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove() {
    setState(() => _path = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final has = _path != null && _path!.isNotEmpty && File(_path!).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 6),
          child: Text('Photo (optional)',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black26),
          ),
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : has
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_path!), fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Icon(Icons.image_outlined,
                          size: 48, color: Colors.black38)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Camera'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            if (has)
              TextButton.icon(
                onPressed: _busy ? null : _remove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
