import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/user.dart';
import '../widgets/manager_widgets.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.authProvider.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.authProvider.profile;
    final email = profile?.email.trim().isNotEmpty == true
        ? profile!.email
        : widget.authProvider.user?.email ?? 'Not available';

    return ManagerScaffold(
      title: 'My Profile',
      currentIndex: 4,
      body: ManagerPagePadding(
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.name.isNotEmpty == true
                          ? profile!.name
                          : 'Library Manager',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    const StatusBadge(text: 'Manager', type: 'manager'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Account information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _ProfileInfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: _roleName(profile?.role),
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  _ProfileInfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: email,
                  ),
                  if (profile?.studentId?.trim().isNotEmpty == true) ...[
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ProfileInfoTile(
                      icon: Icons.numbers_rounded,
                      label: 'University / Staff ID',
                      value: profile!.studentId!,
                    ),
                  ],
                  if (profile?.createdAt != null) ...[
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ProfileInfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member since',
                      value: _dateLabel(profile!.createdAt!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: widget.authProvider.isLoading ? null : _confirmLogout,
              icon: widget.authProvider.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                widget.authProvider.isLoading ? 'Signing out...' : 'Log Out',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (widget.authProvider.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.authProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
        title: const Text('Log out?'),
        content: const Text('You will be returned to role selection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.authProvider.signOut();
      if (mounted) context.go(AppRoutes.roleSelection);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to log out: $error')));
    }
  }

  String _roleName(UserRole? role) => switch (role) {
    UserRole.student => 'Student',
    UserRole.librarian => 'Librarian',
    UserRole.manager => 'Manager',
    null => 'Not available',
  };

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
