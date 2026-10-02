import 'package:flutter/material.dart';

import '../../../models/user.dart';
// Uses the agreed LibMate colours, currently defined with the Librarian
// theme; move to app_theme.dart once the shared theme is filled in.
import '../../librarian/theme/librarian_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_role_card.dart';
import '../widgets/login_text_field.dart';

/// LibMate login (Figma). After a successful sign-in the router redirects to
/// the user's area automatically (e.g. /librarian), so this screen never
/// navigates by itself.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  UserRole? _role;
  String? _roleError;
  bool _showPassword = false;
  bool _rememberMe = true; // Takes effect once Firebase Auth persistence is set up.

  static const List<(UserRole, String, IconData)> _roles = [
    (UserRole.student, 'Student', Icons.school_outlined),
    (UserRole.librarian, 'Librarian', Icons.people_outline),
    (UserRole.manager, 'Administrator', Icons.location_on_outlined),
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _role = role;
      _roleError = null;
    });
    widget.authProvider.clearError();
  }

  Future<void> _login() async {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _roleError = _role == null ? 'Please choose how you are logging in.' : null;
    });
    if (!formValid || _role == null) return;

    if (_role == UserRole.librarian) {
      // TEMPORARY LIBRARIAN LOGIN
      // Replace with Firebase Auth when backend/database integration is available.
      widget.authProvider.signInTemporaryLibrarian(
        email: _email.text,
        password: _password.text,
      );
    } else {
      // Existing Firebase Auth sign-in for students and administrators.
      await widget.authProvider.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    }
  }

  /// Actions in the design that need the real account system.
  void _notAvailableYet(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available once LibMate accounts are connected.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LibrarianTheme.light,
      child: Scaffold(
        body: Stack(
          children: [
            const _BackgroundCircles(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LibrarianSpacing.lg,
                    vertical: LibrarianSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: ListenableBuilder(
                      listenable: widget.authProvider,
                      builder: (context, _) => _buildForm(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final auth = widget.authProvider;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const SizedBox(height: LibrarianSpacing.lg + 8),
            const Text(
              'Login as',
              style: TextStyle(
                color: LibrarianColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LibrarianSpacing.sm + 4),
            Row(
              children: [
                for (final (role, label, icon) in _roles) ...[
                  if (role != UserRole.student)
                    const SizedBox(width: LibrarianSpacing.md),
                  Expanded(
                    child: LoginRoleCard(
                      icon: icon,
                      label: label,
                      selected: _role == role,
                      onTap: () => _selectRole(role),
                    ),
                  ),
                ],
              ],
            ),
            if (_roleError != null)
              Padding(
                padding: const EdgeInsets.only(top: LibrarianSpacing.sm),
                child: Text(
                  _roleError!,
                  style: const TextStyle(color: LibrarianColors.unavailable),
                ),
              ),
            const SizedBox(height: LibrarianSpacing.lg + 4),
            LoginTextField(
              label: 'Email or User ID',
              hint: 'Enter your email or user ID',
              icon: Icons.mail_outline,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your email or user ID'
                  : null,
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            LoginTextField(
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              controller: _password,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _login(),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter your password'
                  : null,
              trailing: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: LibrarianColors.secondaryText,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            const SizedBox(height: LibrarianSpacing.sm),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) => setState(() => _rememberMe = value ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Remember me',
                    style: TextStyle(
                      color: LibrarianColors.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Flexible + FittedBox: the link shrinks instead of
                // overflowing on narrow (360px) phones.
                Flexible(
                  child: TextButton(
                    onPressed: () => _notAvailableYet('Password reset'),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (auth.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: LibrarianSpacing.sm),
                padding: const EdgeInsets.all(LibrarianSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: LibrarianColors.unavailable.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LibrarianColors.unavailable.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: LibrarianColors.unavailable),
                    const SizedBox(width: LibrarianSpacing.sm),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: LibrarianColors.unavailable),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: LibrarianSpacing.md + 4),
            FilledButton(
              onPressed: auth.isLoading ? null : _login,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
                ),
                textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              child: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: LibrarianSpacing.md),
                  child: Text(
                    'OR',
                    style: TextStyle(color: LibrarianColors.secondaryText),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _notAvailableYet('Google sign-in'),
              icon: const Text(
                'G',
                style: TextStyle(
                  color: LibrarianColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 58),
                backgroundColor: LibrarianColors.card,
                foregroundColor: LibrarianColors.text,
                side: const BorderSide(color: LibrarianColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
                ),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => _notAvailableYet('Sign up'),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.menu_book, size: 80, color: LibrarianColors.primary),
        SizedBox(height: LibrarianSpacing.sm),
        Text(
          'LibMate',
          style: TextStyle(
            color: LibrarianColors.text,
            fontSize: 40,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: LibrarianSpacing.xs),
        Text(
          'LEARN • RESERVE • BELONG',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LibrarianColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: LibrarianSpacing.lg + 8),
        Text(
          'Welcome Back!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LibrarianColors.text,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: LibrarianSpacing.sm),
        Text(
          'Sign in to continue your library journey.',
          textAlign: TextAlign.center,
          style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 17),
        ),
      ],
    );
  }
}

/// The soft light-blue circles behind the login form (see Figma).
class _BackgroundCircles extends StatelessWidget {
  const _BackgroundCircles();

  @override
  Widget build(BuildContext context) {
    Widget circle(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LibrarianColors.lightBlue.withValues(alpha: 0.8),
      ),
    );

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -120, left: -120, child: circle(340)),
          Positioned(top: 120, right: -160, child: circle(420)),
          Positioned(bottom: -140, left: -100, child: circle(320)),
        ],
      ),
    );
  }
}
