import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

/// The single login form used by every role. There is no role picker here:
/// after Firebase Auth succeeds, [AuthProvider] loads `users/{uid}` and the
/// router sends the user to their Student / Librarian / Manager dashboard
/// based on the Firestore `role` alone.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    widget.authProvider.addListener(_handleProviderChange);
  }

  @override
  void dispose() {
    widget.authProvider.removeListener(_handleProviderChange);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleProviderChange() {
    if (mounted) setState(() {});
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'Enter your account email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, emailController.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    final success = await widget.authProvider.sendPasswordResetEmail(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'A password reset link has been sent to $email.'
              : widget.authProvider.errorMessage ??
                    'Could not send the reset link. Please try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = widget.authProvider;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AuthPageBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 27, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandHeader(),
                  const SizedBox(height: 31),
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Sign in to continue your library journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  AuthInput(
                    label: 'Email Address',
                    hint: 'Enter your email address',
                    controller: _emailController,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: validateAuthEmail,
                  ),
                  const SizedBox(height: 17),
                  AuthInput(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
                    validator: (value) => validateRequired(value, 'Password'),
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: authProvider.isLoading ? null : _forgotPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    _AuthErrorMessage(message: authProvider.errorMessage!),
                  ],
                  const SizedBox(height: 22),
                  AuthPrimaryButton(
                    label: 'Login',
                    isLoading: authProvider.isLoading,
                    onPressed: _signIn,
                  ),
                  const SizedBox(height: 34),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.signup),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthErrorMessage extends StatelessWidget {
  const _AuthErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(color: Color(0xFFDC4C4C), fontSize: 13),
      textAlign: TextAlign.center,
    );
  }
}
