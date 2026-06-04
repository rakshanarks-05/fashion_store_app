/// Compile-time feature toggles.
///
/// **Admin:** set [enableAdminInSource] to `true`, or build with
/// `flutter run --dart-define=ENABLE_CREATE_MODE=true`.
abstract final class FeatureFlags {
  static const bool _fromEnvironment = bool.fromEnvironment(
    'ENABLE_CREATE_MODE',
    defaultValue: false,
  );

  /// When `true`, shows **Admin** in the app drawer. Off by default.
  static const bool enableAdminInSource = true;

  static bool get enableAdmin => _fromEnvironment || enableAdminInSource;
}
