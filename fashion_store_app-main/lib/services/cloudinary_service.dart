import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/cloudinary_config.dart';

/// Result of a successful unsigned Cloudinary upload.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.imageUrl,
    required this.publicId,
  });

  /// HTTPS URL suitable for storage in Firestore (`secure_url` from API).
  final String imageUrl;

  /// Cloudinary asset id (folder segments allowed), used for transforms / future admin API.
  final String publicId;
}

/// Thrown when upload fails or response is invalid.
class CloudinaryUploadException implements Exception {
  CloudinaryUploadException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CloudinaryUploadException: $message';
}

/// Unsigned image upload + URL transformation helpers.
///
/// For production, prefer a backend that signs uploads; this client path uses
/// [CloudinaryConfig.uploadPreset] only (no secret).
class CloudinaryService {
  CloudinaryService({
    String? cloudName,
    String? uploadPreset,
    http.Client? httpClient,
  })  : _cloudName = cloudName ?? CloudinaryConfig.cloudName,
        _uploadPreset = uploadPreset ?? CloudinaryConfig.uploadPreset,
        _client = httpClient ?? http.Client();

  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  /// Uploads [file] via multipart POST (unsigned preset).
  ///
  /// [folder] is optional (e.g. [CloudinaryConfig.profilesUploadFolder]); the
  /// upload preset must allow client-side folder assignment when set.
  ///
  /// Returns [CloudinaryUploadResult] with `secure_url` and `public_id`.
  Future<CloudinaryUploadResult> uploadImage(
    XFile file, {
    String? folder,
  }) async {
    if (_uploadPreset.trim().isEmpty) {
      throw CloudinaryUploadException(
        'Cloudinary upload preset is not set. In the Cloudinary Dashboard go to '
        'Settings → Upload → Upload presets, create an **unsigned** preset, '
        'then set `CloudinaryConfig.uploadPreset` in '
        '`lib/core/constants/cloudinary_config.dart` to that preset name.',
      );
    }

    final request = http.MultipartRequest('POST', _uploadUri);
    request.fields['upload_preset'] = _uploadPreset;
    final f = folder?.trim();
    if (f != null && f.isNotEmpty) {
      request.fields['folder'] = f;
    }

    final multipartFile = await _multipartFileFromXFile(file);
    request.files.add(multipartFile);

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request);
    } catch (e) {
      throw CloudinaryUploadException(
        'Network error: ${e is Exception ? e.toString() : '$e'}',
      );
    }

    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw CloudinaryUploadException(
        'Upload failed (${streamed.statusCode}): $body',
        streamed.statusCode,
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw CloudinaryUploadException('Invalid JSON from Cloudinary: $body');
    }

    final secureUrl = json['secure_url'] as String?;
    final publicId = json['public_id'] as String?;
    if (secureUrl == null ||
        secureUrl.isEmpty ||
        publicId == null ||
        publicId.isEmpty) {
      throw CloudinaryUploadException('Missing secure_url or public_id: $body');
    }

    return CloudinaryUploadResult(imageUrl: secureUrl, publicId: publicId);
  }

  static Future<http.MultipartFile> _multipartFileFromXFile(XFile file) async {
    final name = file.name;
    final lower = name.toLowerCase();
    String subType = 'jpeg';
    if (lower.endsWith('.png')) subType = 'png';
    if (lower.endsWith('.webp')) subType = 'webp';
    if (lower.endsWith('.gif')) subType = 'gif';

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
        contentType: MediaType('image', subType),
      );
    }

    return http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: name,
      contentType: MediaType('image', subType),
    );
  }

  // --- Dynamic transforms (single stored `imageUrl`; derive sizes in UI) ---

  /// Inserts [transformation] immediately after `/upload/` in a Cloudinary HTTPS URL.
  static String applyTransformation(String secureUrl, String transformation) {
    const marker = '/upload/';
    final idx = secureUrl.indexOf(marker);
    if (idx < 0) return secureUrl;
    final rest = secureUrl.substring(idx + marker.length);
    // Heuristic: already has a transformation chain before version or public_id.
    if (rest.startsWith('c_') ||
        rest.startsWith('w_') ||
        rest.startsWith('h_') ||
        rest.startsWith('f_')) {
      return secureUrl;
    }
    return '${secureUrl.substring(0, idx + marker.length)}$transformation/$rest';
  }

  /// Thumbnail: crop fill 300×300, auto format/quality.
  static String thumbnailUrl(String secureUrl) =>
      applyTransformation(secureUrl, 'c_fill,w_300,h_300,q_auto,f_auto');

  /// Medium width for detail / larger grids.
  static String mediumUrl(String secureUrl) =>
      applyTransformation(secureUrl, 'w_600,q_auto,f_auto');

  /// `secure_url` from Cloudinary Upload API / delivery URLs.
  static bool isCloudinaryUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('res.cloudinary.com') && u.contains('/image/upload/');
  }
}
