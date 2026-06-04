import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/cloudinary_config.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../services/cloudinary_service.dart';

/// Picks a single image and uploads it to Cloudinary under [CloudinaryConfig.profilesUploadFolder].
///
/// Returns the HTTPS `secure_url`, or `null` if the user cancels or upload fails
/// (failures also show a [SnackBar] when [context] is mounted).
Future<String?> pickAndUploadProfilePhotoToCloudinary(
  BuildContext context,
  WidgetRef ref, {
  void Function(bool uploading)? onUploading,
  Color? accentColor,
}) async {
  if (!context.mounted) return null;

  final color = accentColor ?? Theme.of(context).colorScheme.primary;

  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: color),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: color),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;

  final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: source,
    imageQuality: 85,
    maxWidth: 2048,
    maxHeight: 2048,
  );
  if (xfile == null || !context.mounted) return null;

  onUploading?.call(true);
  try {
    final cloudinary = ref.read(cloudinaryServiceProvider);
    final result = await cloudinary.uploadImage(
      xfile,
      folder: CloudinaryConfig.profilesUploadFolder,
    );
    return result.imageUrl;
  } on CloudinaryUploadException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
    return null;
  } finally {
    onUploading?.call(false);
  }
}
