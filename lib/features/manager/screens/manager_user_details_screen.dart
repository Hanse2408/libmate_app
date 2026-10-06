import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../data/manager_mock_data.dart';
import '../widgets/manager_widgets.dart';

class ManagerUserDetailsScreen extends StatefulWidget {
  const ManagerUserDetailsScreen({super.key, required this.user});

  final ManagerUser user;

  @override
  State<ManagerUserDetailsScreen> createState() =>
      _ManagerUserDetailsScreenState();
}

class _ManagerUserDetailsScreenState extends State<ManagerUserDetailsScreen> {
  late ManagerUser _user;

  @override
  void initState() {
    super.initState();
    _user = ManagerUserStore.instance.findById(widget.user.id) ?? widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'User Details',
      body: ManagerPagePadding(
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.12),
                          child: Icon(
                            Icons.person_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _user.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _user.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          text: _user.status,
                          type: _user.isActive ? 'available' : 'inactive',
                        ),
                      ],
                    ),
                    const Divider(height: 26),
                    _UserDetailRow(label: 'University / Staff ID', value: _user.id),
                    _UserDetailRow(label: 'Role', value: _user.role),
                    _UserDetailRow(label: 'Status', value: _user.status),
                    _UserDetailRow(
                      label: 'Created',
                      value: _user.createdAt == null
                          ? 'Not available'
                          : _formatDate(_user.createdAt!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 9),
            PrimaryButton(
              label: 'Edit User',
              icon: Icons.edit_outlined,
              onPressed: () async {
                await context.push(
                  AppRoutes.managerUserEdit,
                  extra: _user,
                );
                if (!mounted) return;
                setState(() {
                  _user =
                      ManagerUserStore.instance.findById(widget.user.id) ??
                      _user;
                });
              },
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _user.isActive ? _confirmDeactivation : null,
              icon: const Icon(Icons.person_off_outlined),
              label: const Text('Deactivate User'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Demo mode: profile changes are local only. Deactivation does not change sign-in access.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeactivation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.person_off_outlined, color: AppColors.error),
        title: const Text('Deactivate User?'),
        content: Text(
          '${_user.name}\n${_user.email}\n\nCurrent Role: ${_user.role}\n\nAre you sure you want to deactivate this account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      ManagerUserStore.instance.deactivate(_user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deactivated successfully (demo).')),
      );
      context.pop(true);
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _UserDetailRow extends StatelessWidget {
  const _UserDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
