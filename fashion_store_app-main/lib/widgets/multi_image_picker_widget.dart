import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Gallery multi-select with thumbnails and per-item remove.
class MultiImagePickerWidget extends StatelessWidget {
  const MultiImagePickerWidget({
    super.key,
    required this.label,
    required this.files,
    required this.onChanged,
    this.maxImages = 12,
  });

  final String label;
  final List<XFile> files;
  final ValueChanged<List<XFile>> onChanged;
  final int maxImages;

  Future<void> _addMore(BuildContext context) async {
    if (files.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('At most $maxImages images.')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked.isEmpty) return;
    final next = [...files, ...picked];
    onChanged(next.take(maxImages).toList());
  }

  void _removeAt(int index) {
    final next = [...files]..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (files.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                'No images yet',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                return _ThumbTile(
                  file: files[i],
                  onRemove: () => _removeAt(i),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _addMore(context),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(files.isEmpty ? 'Choose images' : 'Add more images'),
        ),
      ],
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 100,
            height: 100,
            child: _ThumbPreview(file: file),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Theme.of(context).colorScheme.error,
            shape: const CircleBorder(),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThumbPreview extends StatelessWidget {
  const _ThumbPreview({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: file.readAsBytes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          return Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          );
        },
      );
    }
    return Image.file(
      File(file.path),
      fit: BoxFit.cover,
      width: 100,
      height: 100,
    );
  }
}
