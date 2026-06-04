import 'package:country_picker/country_picker.dart';

import 'registration_validators.dart';

/// Best-effort split of stored E.164 into [Country] + national digits for the register form.
({Country country, String nationalDigits})? parseE164ToCountryAndNational(
  String? e164,
) {
  if (e164 == null) return null;
  final trimmed = e164.trim();
  if (trimmed.isEmpty) return null;
  final digits = trimmed.startsWith('+')
      ? trimmed.substring(1).replaceAll(RegExp(r'\D'), '')
      : RegistrationValidators.digitsOnly(trimmed);
  if (digits.isEmpty) return null;

  final service = CountryService();
  final countries = service.getAll()
    ..sort((a, b) => b.phoneCode.length.compareTo(a.phoneCode.length));

  for (final c in countries) {
    final code = RegistrationValidators.digitsOnly(c.phoneCode);
    if (code.isEmpty) continue;
    if (digits.startsWith(code)) {
      final national = digits.substring(code.length);
      if (national.isEmpty) return null;
      return (country: c, nationalDigits: national);
    }
  }
  return null;
}
