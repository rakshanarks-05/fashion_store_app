import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/registration_validators.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/utils/profile_photo_cloudinary.dart';
import '../models/register_form_user_data.dart';
import '../providers/auth_providers.dart';
import '../providers/register_providers.dart';
import '../widgets/auth_screen_decor.dart';

/// Email/password sign-up with phone (E.164), display name, address, and Firestore profile write.
///
/// Set [isEditMode] to reuse this form for profile updates (password fields hidden; email read-only).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({
    super.key,
    this.isEditMode = false,
    this.initialUserData,
  });

  final bool isEditMode;
  final RegisterFormUserData? initialUserData;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _phoneNational = TextEditingController();
  final _address = TextEditingController();

  bool _loading = false;
  final bool _obscurePassword = true;
  final bool _obscureConfirm = true;
  String? _serverError;

  /// HTTPS URL from Cloudinary after a successful profile photo upload.
  String? _profilePhotoUrl;
  bool _photoUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _applyEditPrefill(widget.initialUserData);
    }
  }

  void _applyEditPrefill(RegisterFormUserData? data) {
    if (data == null) return;
    _displayName.text = data.displayName?.trim() ?? '';
    _email.text = data.email?.trim() ?? '';
    _address.text = data.address?.trim() ?? '';
    final url = data.photoUrl?.trim();
    _profilePhotoUrl = url != null && url.isNotEmpty ? url : null;

    final e164 = data.phoneNumberE164?.trim() ?? '';
    if (e164.isNotEmpty) {
      // Country selection removed; best-effort prefill with national digits (assumes +1).
      final digits = RegistrationValidators.digitsOnly(e164);
      _phoneNational.text =
          digits.startsWith('1') && digits.length > 1 ? digits.substring(1) : digits;
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _phoneNational.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    if (_loading || _photoUploading) return;
    setState(() => _serverError = null);

    final url = await pickAndUploadProfilePhotoToCloudinary(
      context,
      ref,
      onUploading: (uploading) {
        if (mounted) setState(() => _photoUploading = uploading);
      },
      accentColor: AuthScreenDecor.primaryBlue,
    );
    if (url != null && mounted) setState(() => _profilePhotoUrl = url);
  }

  Future<void> _submit() async {
    if (_photoUploading) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (widget.isEditMode) {
      await _submitEdit();
    } else {
      await _submitRegister();
    }
  }

  Future<void> _submitRegister() async {
    setState(() => _loading = true);
    try {
      final e164 = _buildPhoneE164(_phoneNational.text);

      await ref.read(registerWithProfileUseCaseProvider).call(
            email: _email.text,
            password: _password.text,
            phoneNumberE164: e164,
            displayName: _displayName.text,
            photoUrl: _profilePhotoUrl,
            address: _address.text,
          );

      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e, st) {
      debugPrint('Register error: $e\n$st');
      setState(() {
        _serverError = _messageForError(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitEdit() async {
    final uid = widget.initialUserData?.userId ??
        ref.read(authStateProvider).valueOrNull?.id;
    if (uid == null) {
      setState(() => _serverError = 'You must be signed in to update your profile.');
      return;
    }

    setState(() => _loading = true);
    try {
      final e164 = _buildPhoneE164(_phoneNational.text);

      await ref.read(updateUserProfileUseCaseProvider).call(
            userId: uid,
            displayName: _displayName.text,
            phoneNumberE164: e164,
            photoUrl: _profilePhotoUrl,
            address: _address.text,
          );

      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      debugPrint('Update profile error: $e\n$st');
      setState(() {
        _serverError = _messageForError(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Builds a valid E.164 phone number without country selection UI.
  ///
  /// - If the user pastes a full `+<digits>` value, it is preserved (normalized).
  /// - Otherwise we assume US `+1` and treat input as national digits only.
  static String _buildPhoneE164(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) {
      final digits = RegistrationValidators.digitsOnly(trimmed);
      return '+$digits';
    }
    return RegistrationValidators.buildE164(phoneCode: '1', nationalDigits: trimmed);
  }

  static String _messageForError(Object e) {
    if (e is FirebaseAuthException) {
      return _firebaseAuthMessage(e);
    }
    if (e is FirebaseException) {
      return _firebaseMessage(e);
    }
    return e.toString();
  }

  static String _firebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled for this project.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Could not create your account. Please try again.';
    }
  }

  static String _firebaseMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Could not save your profile. Check Firestore security rules.';
      case 'unavailable':
        return 'Service temporarily unavailable. Try again shortly.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong saving your profile.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        title: 'Home',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.center,
                        child: AuthAvatarPlaceholder(
                          size: 84,
                          onTap: _pickProfilePhoto,
                          image: _profilePhotoUrl != null ? NetworkImage(_profilePhotoUrl!) : null,
                          uploading: _photoUploading,
                          accentColor: const Color(0xFFF07D74),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FormCard(
                        children: [
                          _CardTextField(
                            controller: _displayName,
                            labelText: widget.isEditMode ? 'Name' : null,
                            hintText: 'Name',
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: RegistrationValidators.displayNameError,
                            enabled: !(_loading || _photoUploading),
                            onChanged: () => setState(() => _serverError = null),
                          ),
                          _CardDivider(),
                          _CardTextField(
                            controller: _email,
                            labelText: widget.isEditMode ? 'Email' : null,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: widget.isEditMode
                                ? (_) => null
                                : RegistrationValidators.emailError,
                            enabled: !(widget.isEditMode || _loading || _photoUploading),
                            onChanged: () => setState(() => _serverError = null),
                          ),
                          _CardDivider(),
                          _CardTextField(
                            controller: _phoneNational,
                            labelText: widget.isEditMode ? 'Phone' : null,
                            hintText: 'Phone',
                            keyboardType: TextInputType.phone,
                            textInputAction:
                                widget.isEditMode ? TextInputAction.next : TextInputAction.next,
                            autofillHints: const [AutofillHints.telephoneNumber],
                              inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                RegistrationValidators.nationalPhoneDigitsError(v),
                            enabled: !(_loading || _photoUploading),
                            onChanged: () => setState(() => _serverError = null),
                          ),
                          if (!widget.isEditMode) ...[
                            _CardDivider(),
                            _CardTextField(
                              controller: _password,
                              hintText: 'Password',
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: RegistrationValidators.passwordError,
                              enabled: !(_loading || _photoUploading),
                              onChanged: () => setState(() => _serverError = null),
                            ),
                            _CardDivider(),
                            _CardTextField(
                              controller: _confirmPassword,
                              hintText: 'Confirm password',
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (v) => RegistrationValidators.confirmPasswordError(
                                v,
                                _password.text,
                              ),
                              enabled: !(_loading || _photoUploading),
                              onChanged: () => setState(() => _serverError = null),
                              onFieldSubmitted: () {
                                if (!_loading) _submit();
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _FormCard(
                        children: [
                          _CardTextField(
                            controller: _address,
                            labelText: widget.isEditMode ? 'Address' : null,
                            hintText: widget.isEditMode ? 'Address' : 'Address (optional)',
                            textInputAction: TextInputAction.done,
                            maxLines: 2,
                            validator: RegistrationValidators.addressError,
                            enabled: !(_loading || _photoUploading),
                            onChanged: () => setState(() => _serverError = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_serverError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 8),
                          child: Text(
                            _serverError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ),
                      _GradientActionButton(
                        onPressed: (_loading || _photoUploading) ? null : _submit,
                        text: widget.isEditMode ? 'Update Profile' : 'Register',
                        loading: _loading,
                      ),
                      const SizedBox(height: 12),
                      if (!widget.isEditMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Color(0xFF5C5C5C),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.1,
                              ),
                            ),
                            TextButton(
                              onPressed: (_loading || _photoUploading)
                                  ? null
                                  : () => Navigator.of(context)
                                      .pushReplacementNamed('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFF07D74),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      if (!widget.isEditMode) ...[
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Colors.black,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE9E9EA),
      ),
    );
  }
}

class _CardTextField extends StatelessWidget {
  const _CardTextField({
    required this.controller,
    this.labelText,
    required this.hintText,
    required this.validator,
    required this.enabled,
    required this.onChanged,
    this.textInputAction,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscureText = false,
    this.inputFormatters,
    this.maxLines = 1,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String? labelText;
  final String hintText;
  final String? Function(String?) validator;
  final bool enabled;
  final VoidCallback onChanged;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final VoidCallback? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
            child: Text(
              labelText!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C5C5C),
                height: 1.25,
              ),
            ),
          ),
        ],
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          maxLines: obscureText ? 1 : maxLines,
          onFieldSubmitted: onFieldSubmitted == null ? null : (_) => onFieldSubmitted!(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.25,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ).copyWith(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8A8A8E),
              height: 1.25,
            ),
          ),
          validator: validator,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.onPressed,
    required this.text,
    required this.loading,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(colors: [Color(0x66F07D74), Color(0x66F07D74)])
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFF1958C), Color(0xFFF07D74)],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(text),
        ),
      ),
    );
  }
}
