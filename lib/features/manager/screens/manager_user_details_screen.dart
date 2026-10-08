import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/user.dart';
import '../data/manager_mock_data.dart';
import '../providers/manager_scope.dart';
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = ManagerScope.of(context).repository;
    final nextUser = repository.findUserById(widget.user.id) ?? widget.user;
    if (_user.name != nextUser.name ||
        _user.email != nextUser.email ||
        _user.role != nextUser.role ||
        _user.institutionId != nextUser.institutionId ||
        _user.accountStatus != nextUser.accountStatus) {
      setState(() => _user = nextUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ManagerScope.of(context);
    final isOwnAccount = _user.id == scope.authProvider.user?.uid;

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
                          type: _statusBadgeType(_user.accountStatus),
                        ),
                      ],
                    ),
                    const Divider(height: 26),
                    _UserDetailRow(
                      label: 'Student ID / Staff ID',
                      value: _user.institutionId ?? 'Not set',
                    ),
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
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 9),
            PrimaryButton(
              label: 'Edit User',
              icon: Icons.edit_outlined,
              onPressed: _busy
                  ? null
                  : () async {
                      await context.push(
                        AppRoutes.managerUserEdit,
                        extra: _user,
                      );
                      if (!mounted || !context.mounted) return;
                      final repository = ManagerScope.of(context).repository;
                      setState(() {
                        _user =
                            repository.findUserById(widget.user.id) ?? _user;
                      });
                    },
            ),
            if (isOwnAccount) ...[
              const SizedBox(height: 9),
              Text(
                'You cannot change your own account status.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              if (_user.accountStatus != AccountStatus.active) ...[
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _confirmStatusChange(
                          AccountStatus.active,
                          title: 'Activate this user?',
                          actionLabel: 'Activate User',
                          successMessage: 'User activated successfully.',
                          description: 'This user will be able to sign in to LibMate again.',
                        ),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Activate User'),
                ),
              ],
              if (_user.accountStatus == AccountStatus.active) ...[
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _confirmStatusChange(
                          AccountStatus.inactive,
                          title: 'Deactivate this user?',
                          actionLabel: 'Deactivate User',
                          successMessage: 'User deactivated successfully.',
                          description: 'This user will not be able to sign in until the account is activated again.',
                        ),
                  icon: const Icon(Icons.person_off_outlined),
                  label: const Text('Deactivate User'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _statusBadgeType(AccountStatus status) => switch (status) {
    AccountStatus.active => 'available',
    AccountStatus.inactive => 'inactive',
    AccountStatus.suspended => 'inactive',
  };

  Future<void> _confirmStatusChange(
    AccountStatus status, {
    required String title,
    required String actionLabel,
    required String successMessage,
    String? description,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
        title: Text(title),
        content: Text(
          description ??
              '${_user.name}\n${_user.email}\n\nCurrent Role: ${_user.role}\n\n'
                  'Are you sure you want to $actionLabel this account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _changeStatus(status, successMessage);
  }

  Future<void> _changeStatus(
    AccountStatus status,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    final repository = ManagerScope.of(context).repository;
    final result = await repository.setAccountStatus(_user.id, status);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'The request could not be completed.',
          ),
        ),
      );
      return;
    }

    setState(() => _user = _user.copyWith(accountStatus: status));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(successMessage)));
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
