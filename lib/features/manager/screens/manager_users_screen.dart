import 'package:flutter/material.dart';

import '../data/manager_mock_data.dart';
import '../widgets/manager_widgets.dart';

class ManagerUsersScreen extends StatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  State<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends State<ManagerUsersScreen> {
  String _query = '';
  int _filter = 0;
  static const _filters = ['All', 'Students', 'Librarians', 'Managers'];
  final Map<String, String> _roleUpdates = {};

  @override
  Widget build(BuildContext context) {
    final results = managerUsers
        .where((user) {
          final role = _roleUpdates[user.id] ?? user.role;
          final roleMatch =
              _filter == 0 ||
              role.toLowerCase() ==
                  _filters[_filter]
                      .substring(0, _filters[_filter].length - 1)
                      .toLowerCase();
          final query = _query.toLowerCase();
          return roleMatch ||
              (_filter == 0 &&
                  (query.isEmpty ||
                      user.name.toLowerCase().contains(query) ||
                      user.id.toLowerCase().contains(query)));
        })
        .where((user) {
          final query = _query.toLowerCase();
          return query.isEmpty ||
              user.name.toLowerCase().contains(query) ||
              user.id.toLowerCase().contains(query);
        })
        .toList();

    return ManagerScaffold(
      title: 'Users & Roles',
      currentIndex: 3,
      fourthItem: ManagerFourthNav.users,
      body: ManagerPagePadding(
        child: Column(
          children: [
            SearchField(
              hint: 'Search users...',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 8),
            FilterChipsRow(
              labels: _filters,
              selectedIndex: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => UserListTile(
                        user: ManagerUser(
                          name: results[index].name,
                          id: results[index].id,
                          email: results[index].email,
                          role:
                              _roleUpdates[results[index].id] ??
                              results[index].role,
                        ),
                        onTap: () => _showUserDetails(context, results[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserDetails(BuildContext context, ManagerUser user) async {
    var role = _roleUpdates[user.id] ?? user.role;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              5,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  user.id,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 15),
                Text('Email', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(
                      value: 'Librarian',
                      child: Text('Librarian'),
                    ),
                    DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => role = value);
                  },
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Save Role',
                  onPressed: () {
                    setState(() => _roleUpdates[user.id] = role);
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated (demo)')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
