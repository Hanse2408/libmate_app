import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    widget.authProvider.addListener(_handleProviderChange);
  }

  @override
  void dispose() {
    widget.authProvider.removeListener(_handleProviderChange);
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleProviderChange() {
    if (mounted) setState(() {});
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      studentId: _studentIdController.text.trim(),
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back to login',
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF172033),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const AuthBrandHeader(),
                  const SizedBox(height: 25),
                  const Text(
                    'Create Your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Join LibMate and get access to books, study spaces and more.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                  ),
                  const SizedBox(height: 23),
                  AuthInput(
                    label: 'Full Name',
                    hint: 'e.g. Jane Doe',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) => validateRequired(value, 'Full name'),
                  ),
                  const SizedBox(height: 13),
                  AuthInput(
                    label: 'Student ID',
                    hint: 'e.g. STU12345',
                    controller: _studentIdController,
                    icon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) => validateRequired(value, 'Student ID'),
                  ),
                  const SizedBox(height: 13),
                  AuthInput(
                    label: 'Email Address',
                    hint: 'e.g. student@university.edu',
                    controller: _emailController,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: validateAuthEmail,
                  ),
                  const SizedBox(height: 13),
                  AuthInput(
                    label: 'Password',
                    hint: 'At least 6 characters',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final requiredError = validateRequired(value, 'Password');
                      if (requiredError != null) return requiredError;
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
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
                        color: const Color(0xFF94A3B8),
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  AuthInput(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,
                    obscureText: !_confirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final requiredError = validateRequired(
                        value,
                        'Confirm password',
                      );
                      if (requiredError != null) return requiredError;
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      tooltip: _confirmPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () => setState(
                        () =>
                            _confirmPasswordVisible = !_confirmPasswordVisible,
                      ),
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 21,
                      ),
                    ),
                  ),
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFDC4C4C),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Create Account',
                    isLoading: authProvider.isLoading,
                    onPressed: _createAccount,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
