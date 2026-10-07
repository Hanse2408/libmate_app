import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerUsersScreen extends StatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  State<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends State<ManagerUsersScreen> {
  String _query = '';
  String _roleFilter = 'All Roles';
  String _statusFilter = 'All Status';

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    if (repository.isLoading) {
      return ManagerScaffold(
        title: 'Users & Roles',
        currentIndex: 3,
        fourthItem: ManagerFourthNav.users,
        body: ManagerPagePadding(
          child: const Center(
            child: Text('Loading users...'),
          ),
        ),
      );
    }

    if (repository.loadError != null) {
      return ManagerScaffold(
        title: 'Users & Roles',
        currentIndex: 3,
        fourthItem: ManagerFourthNav.users,
        body: ManagerPagePadding(
          child: Center(
            child: Text(repository.loadError!),
          ),
        ),
      );
    }

    final users = repository.users.where((user) {
      final query = _query.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.id.toLowerCase().contains(query);
      final matchesRole =
          _roleFilter == 'All Roles' || user.role == _roleFilter;
      final matchesStatus =
          _statusFilter == 'All Status' || user.status == _statusFilter;
      return matchesQuery && matchesRole && matchesStatus;
    }).toList();

    return ManagerScaffold(
      title: 'Users & Roles',
      currentIndex: 3,
      fourthItem: ManagerFourthNav.users,
      body: ManagerPagePadding(
        child: Column(
          children: [
            SearchField(
              hint: 'Search by name, email or ID',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _UserFilterDropdown(
                    value: _roleFilter,
                    values: const [
                      'All Roles',
                      'Student',
                      'Librarian',
                      'Manager',
                    ],
                    onChanged: (value) => setState(() => _roleFilter = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _UserFilterDropdown(
                    value: _statusFilter,
                    values: const ['All Status', 'Active', 'Inactive'],
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${users.length} users',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await context.push(AppRoutes.managerUserAdd);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add User'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return UserListTile(
                          user: user,
                          onTap: () async {
                            await context.push(
                              AppRoutes.managerUserDetails,
                              extra: user,
                            );
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFilterDropdown extends StatelessWidget {
  const _UserFilterDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true),
      items: [
        for (final option in values)
          DropdownMenuItem(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
