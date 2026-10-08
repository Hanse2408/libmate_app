import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user.dart';
import '../data/manager_mock_data.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerUserFormScreen extends StatefulWidget {
  const ManagerUserFormScreen({super.key, this.user});

  final ManagerUser? user;

  @override
  State<ManagerUserFormScreen> createState() => _ManagerUserFormScreenState();
}

class _ManagerUserFormScreenState extends State<ManagerUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _institutionIdController;
  late final TextEditingController _passwordController;
  late UserRole _role;
  late AccountStatus _accountStatus;
  bool _passwordVisible = false;
  bool _saving = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _institutionIdController = TextEditingController(
      text: user?.institutionId ?? '',
    );
    _passwordController = TextEditingController();
    _role = user == null ? UserRole.student : managerRoleFromLabel(user.role);
    _accountStatus = user?.accountStatus ?? AccountStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _institutionIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ManagerScope.of(context);
    // A Manager cannot demote/suspend/deactivate themselves through this
    // form, so role and account status are locked when editing their own
    // profile (see also the Firestore rules and ManagerUserDetailsScreen).
    final isOwnAccount =
        _isEditing && widget.user!.id == scope.authProvider.user?.uid;

    return ManagerScaffold(
      title: _isEditing ? 'Edit User' : 'Add User',
      body: ManagerPagePadding(
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                _isEditing ? 'Edit User Information' : 'Add New User',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Full Name',
                controller: _nameController,
                validator: (value) => _required(value, 'Enter a full name.'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                // Firestore and Firebase Auth email must stay in sync. We do
                // not update the Auth email for another account from the
                // client, so email is read-only once the account exists.
                enabled: !_isEditing,
                validator: (value) {
                  final requiredError = _required(value, 'Enter an email.');
                  if (requiredError != null) return requiredError;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value!.trim())
                      ? null
                      : 'Enter a valid email address.';
                },
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 12),
                _field(
                  label: 'Temporary Password',
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (value) {
                    final requiredError = _required(value, 'Enter a temporary password.');
                    if (requiredError != null) return requiredError;
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              _field(
                label: 'Student ID / Staff ID',
                controller: _institutionIdController,
                validator: (value) => null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  for (final role in UserRole.values)
                    DropdownMenuItem(
                      value: role,
                      child: Text(managerRoleLabel(role)),
                    ),
                ],
                onChanged: isOwnAccount
                    ? null
                    : (value) {
                        if (value != null) setState(() => _role = value);
                      },
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountStatus>(
                  initialValue: _accountStatus,
                  decoration: const InputDecoration(labelText: 'Account Status'),
                  items: const [
                    DropdownMenuItem(
                      value: AccountStatus.active,
                      child: Text('Active'),
                    ),
                    DropdownMenuItem(
                      value: AccountStatus.inactive,
                      child: Text('Inactive'),
                    ),
                    DropdownMenuItem(
                      value: AccountStatus.suspended,
                      child: Text('Suspended'),
                    ),
                  ],
                  onChanged: isOwnAccount
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _accountStatus = value);
                          }
                        },
                ),
              ],
              if (isOwnAccount) ...[
                const SizedBox(height: 8),
                Text(
                  'You cannot change your own role or account status.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () => _save(scope),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Create User'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
    );
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  Future<void> _save(ManagerScope scope) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final institutionId = _institutionIdController.text.trim();
    final repository = scope.repository;

    final result = _isEditing
        ? await repository.updateUser(
            widget.user!.id,
            name: name,
            role: _role,
            accountStatus: _accountStatus,
            institutionId: institutionId,
          )
        : await repository.addUser(
            name: name,
            email: email,
            password: _passwordController.text,
            role: _role,
            institutionId: institutionId,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'The request could not be completed.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'User updated successfully.' : 'User created successfully.',
        ),
      ),
    );
    if (mounted) context.pop(true);
  }
}
