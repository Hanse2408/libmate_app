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
      // Full-screen background, so the decorative circles sit at the
      // screen's corners rather than the form's.
      body: SizedBox.expand(
        child: AuthPageBackground(
          child: SafeArea(
            child: Form(
              key: _formKey,
              // Spacing follows the screen height (roomy on tall phones, as in
              // the design; compact and scrollable on short ones). On tablets
              // and desktop the form stays a centred, phone-width column.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final topGap = (height * 0.075).clamp(16.0, 72.0);
                  final formGap = (height * 0.085).clamp(28.0, 84.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: topGap),
                            const AuthBrandHeader(),
                            const SizedBox(height: 40),
                            const Text(
                              'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to continue your library journey.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: formGap),
                            AuthInput(
                              label: 'Email Address',
                              hint: 'Enter your email address',
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: validateAuthEmail,
                            ),
                            const SizedBox(height: 22),
                            AuthInput(
                              label: 'Password',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              obscureText: !_passwordVisible,
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  validateRequired(value, 'Password'),
                              suffixIcon: IconButton(
                                tooltip: _passwordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible,
                                ),
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 21,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _forgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                              _AuthErrorMessage(
                                message: authProvider.errorMessage!,
                              ),
                            ],
                            const SizedBox(height: 26),
                            AuthPrimaryButton(
                              label: 'Login',
                              isLoading: authProvider.isLoading,
                              onPressed: _signIn,
                            ),
                            const SizedBox(height: 18),
                            const _OrDivider(),
                            const SizedBox(height: 40),
                            // Wraps instead of overflowing on very narrow
                            // screens or with large text.
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin "OR" separator between Login and the Sign Up link (as in the design).
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
    );
    return const Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        line,
      ],
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
