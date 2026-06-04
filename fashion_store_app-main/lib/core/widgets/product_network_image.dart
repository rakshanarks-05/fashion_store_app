import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../services/cloudinary_service.dart';
import '../constants/product_assets.dart';

/// How to derive the display URL from a stored Cloudinary `secure_url`.
enum CloudinaryVariant {
  /// Raw [imageUrl] (no transform).
  original,
  thumbnail,
  medium,
}

/// Cached remote image with optional Cloudinary transforms (single stored URL).
///
/// Non-Cloudinary URLs are loaded as-is.
class ProductNetworkImage extends StatelessWidget {
  const ProductNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.cloudinaryVariant = CloudinaryVariant.medium,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  /// When [imageUrl] is a Cloudinary delivery URL, apply this transform chain.
  final CloudinaryVariant cloudinaryVariant;

  String get _resolvedUrl {
    final u = imageUrl.trim();
    if (u.isEmpty) return u;
    if (cloudinaryVariant == CloudinaryVariant.original) return u;
    if (!CloudinaryService.isCloudinaryUrl(u)) return u;
    switch (cloudinaryVariant) {
      case CloudinaryVariant.thumbnail:
        return CloudinaryService.thumbnailUrl(u);
      case CloudinaryVariant.medium:
        return CloudinaryService.mediumUrl(u);
      case CloudinaryVariant.original:
        return u;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    if (url.isEmpty) {
      return _placeholder;
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => _loadingPlaceholder,
      errorWidget: (context, url, err) => _placeholder,
    );
  }

  Widget get _loadingPlaceholder {
    final w = width ?? 48;
    final h = height ?? 48;
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: SizedBox(
          width: w.clamp(16, 40),
          height: h.clamp(16, 40),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget get _placeholder => Image.asset(
        ProductAssets.productPlaceholder,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
      );
}
