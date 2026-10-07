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
  late final TextEditingController _idController;
  late UserRole _role;
  late bool _isActive;
  bool _saving = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _idController = TextEditingController(text: user?.id ?? '');
    _role = user == null
        ? UserRole.student
        : managerRoleFromLabel(user.role);
    _isActive = user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                validator: (value) {
                  final requiredError = _required(value, 'Enter an email.');
                  if (requiredError != null) return requiredError;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value!.trim())
                      ? null
                      : 'Enter a valid email address.';
                },
              ),
              const SizedBox(height: 12),
              _field(
                label: 'University / Staff ID',
                controller: _idController,
                enabled: !_isEditing,
                validator: (value) =>
                    _required(value, 'Enter a university or staff ID.'),
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
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                initialValue: _isActive,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Active')),
                  DropdownMenuItem(value: false, child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _isActive = value);
                },
              ),
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
                      onPressed: _saving ? null : _save,
                      child: Text(_isEditing ? 'Save Changes' : 'Create User'),
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
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final user = ManagerUser(
      name: _nameController.text.trim(),
      id: _idController.text.trim(),
      role: managerRoleLabel(_role),
      email: _emailController.text.trim(),
      isActive: _isActive,
      createdAt: widget.user?.createdAt ?? DateTime.now(),
    );
    try {
      final repository = ManagerScope.of(context).repository;
      if (_isEditing) {
        repository.updateUser(widget.user!.id, user);
      } else {
        repository.addUser(user);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'User updated successfully.' : 'User created successfully.'),
        ),
      );
      context.pop(true);
    } on FormatException catch (error) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on StateError catch (error) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}
