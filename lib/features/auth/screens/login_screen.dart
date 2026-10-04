import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

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
  bool _rememberMe = true;
  String _selectedRole = 'Student';

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
      selectedRole: switch (_selectedRole) {
        'Student' => UserRole.student,
        'Librarian' => UserRole.librarian,
        'Manager' => UserRole.manager,
        _ => UserRole.student,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = widget.authProvider;
    if (_selectedRole == 'Manager') {
      return _buildManagerLogin(authProvider);
    }

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
                  const Text(
                    'Login as',
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RoleChoice(
                        label: 'Student',
                        icon: Icons.school_outlined,
                        selected: _selectedRole == 'Student',
                        onTap: () => setState(() => _selectedRole = 'Student'),
                      ),
                      const SizedBox(width: 12),
                      _RoleChoice(
                        label: 'Librarian',
                        icon: Icons.people_outline,
                        selected: _selectedRole == 'Librarian',
                        onTap: () =>
                            setState(() => _selectedRole = 'Librarian'),
                      ),
                      const SizedBox(width: 12),
                      _RoleChoice(
                        label: 'Manager',
                        icon: Icons.location_on_outlined,
                        selected: _selectedRole == 'Manager',
                        onTap: () => setState(() => _selectedRole = 'Manager'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 29),
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
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) =>
                              setState(() => _rememberMe = value ?? false),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
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
                    ],
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
                  const SizedBox(height: 17),
                  const _OrDivider(),
                  const SizedBox(height: 17),
                  SizedBox(
                    height: 47,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Color(0xFF172033),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFDCE4EF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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

  Widget _buildManagerLogin(AuthProvider authProvider) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).colorScheme;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 28,
                      ),
                      shrinkWrap: true,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'LibMate',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Library Management System',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Manager Login',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 21),
                        _ManagerLoginField(
                          label: 'Email',
                          hint: 'manager@libmate.com',
                          controller: _emailController,
                          validator: (value) => value?.trim().isEmpty ?? true
                              ? 'Email is required.'
                              : null,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),
                        _ManagerLoginField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Password is required.'
                              : null,
                          obscureText: !_passwordVisible,
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? false),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              'Remember me',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                        if (authProvider.errorMessage != null) ...[
                          const SizedBox(height: 7),
                          _AuthErrorMessage(
                            message: authProvider.errorMessage!,
                          ),
                        ],
                        const SizedBox(height: 7),
                        AuthPrimaryButton(
                          label: 'Login',
                          isLoading: authProvider.isLoading,
                          onPressed: _signIn,
                        ),
                        const SizedBox(height: 7),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedRole = 'Student'),
                          child: const Text('Back to role selection'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManagerLoginField extends StatelessWidget {
  const _ManagerLoginField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 11,
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 11,
          ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF93B8FF),
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF64748B), size: 21),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE2E8F0))),
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
