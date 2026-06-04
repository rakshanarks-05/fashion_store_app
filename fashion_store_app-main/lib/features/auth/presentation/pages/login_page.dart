import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/registration_validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_screen_decor.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _serverError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref.read(loginWithEmailUseCaseProvider).call(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      if (mounted) {
        setState(() => _serverError = _messageForError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ignore: unused_element
  Future<void> _forgotPassword() async {
    setState(() => _serverError = null);
    final email = _email.text.trim();
    final err = RegistrationValidators.emailError(email);
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid email address first.')),
        );
      }
      return;
    }

    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('If an account exists, a reset link was sent to your email.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Could not send reset email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  static String _messageForError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        default:
          return e.message?.isNotEmpty == true
              ? e.message!
              : 'Could not sign in. Please try again.';
      }
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pad = AuthScreenDecor.horizontalPadding(context);
    final size = MediaQuery.sizeOf(context);

    const titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.black,
      height: 1.1,
      letterSpacing: -0.2,
    );
    const labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.black,
      height: 1.1,
    );
    const hintStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFF8A8A8E),
      height: 1.1,
    );
    const footerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFF5C5C5C),
      height: 1.1,
    );

    const fieldFill = Color(0xFFF5F5F5);
    const actionCoral = Color(0xFFF07D74);

    InputDecoration fieldDecoration({
      required String hintText,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: actionCoral.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.2),
        ),
        suffixIcon: suffixIcon,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Welcome Back', style: titleStyle),
                      SizedBox(height: (size.height * 0.030).clamp(16.0, 22.0)),
                      const Text('Email', style: labelStyle),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        decoration: fieldDecoration(hintText: 'Enter your email'),
                        validator: RegistrationValidators.emailError,
                        onChanged: (_) => setState(() => _serverError = null),
                      ),
                      const SizedBox(height: 14),
                      const Text('Password', style: labelStyle),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) {
                          if (!_loading) _login();
                        },
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        decoration: fieldDecoration(
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF8A8A8E),
                            ),
                          ),
                        ),
                        validator: RegistrationValidators.passwordError,
                        onChanged: (_) => setState(() => _serverError = null),
                      ),
                      if (_serverError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _serverError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionCoral,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('login'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ", style: footerStyle),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.of(context)
                                    .pushReplacementNamed('/register'),
                            style: TextButton.styleFrom(
                              foregroundColor: actionCoral,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
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
