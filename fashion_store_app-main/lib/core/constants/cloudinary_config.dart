/// Public Cloudinary identifiers (safe to ship in the app).
///
/// **Never** embed API secret or API key in Flutter — use unsigned upload only,
/// or a future backend that signs uploads server-side.
abstract final class CloudinaryConfig {
  static const String cloudName = 'dbctvoomf';

  /// Unsigned upload preset name (must match Cloudinary Dashboard → Upload presets).
  ///
  /// To change: use **Unsigned** signing mode for direct client uploads.
  static const String uploadPreset = 'ml_default';

  /// Root folder for all client-side uploads.
  ///
  /// Ensure your unsigned upload preset allows folder assignment when using this.
  static const String rootUploadFolder = 'fashion_store_app';

  /// Folder prefix for user profile photos (unsigned preset must allow this folder).
  static const String profilesUploadFolder = '$rootUploadFolder/profiles';

  /// Folder prefix for product gallery images (unsigned preset must allow this folder).
  static const String productsUploadFolder = '$rootUploadFolder/products';
}
