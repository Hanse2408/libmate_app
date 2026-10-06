import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../widgets/manager_widgets.dart';

class ManagerPoliciesScreen extends StatefulWidget {
  const ManagerPoliciesScreen({super.key});

  @override
  State<ManagerPoliciesScreen> createState() => _ManagerPoliciesScreenState();
}

class _ManagerPoliciesScreenState extends State<ManagerPoliciesScreen> {
  final _values = [3, 5, 7, 2, 7];

  static const _policies = [
    (
      'Book Reservation Limit',
      'Max books per student',
      Icons.menu_book_outlined,
    ),
    ('Borrowing Limit', 'Max books to borrow', Icons.library_books_outlined),
    (
      'Reservation Expiry',
      'Days before reservation expires',
      Icons.access_time,
    ),
    (
      'Reading Room Booking',
      'Max booking time (hours)',
      Icons.event_seat_outlined,
    ),
    (
      'Advance Booking',
      'Days ahead a student may book',
      Icons.calendar_month_outlined,
    ),
  ];

  Future<void> _editValue(int index) async {
    var value = _values[index];
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_policies[index].$1),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value > 1
                    ? () => setDialogState(() => value--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$value', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                onPressed: () => setDialogState(() => value++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _values[index] = value);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Policy & Limits',
      currentIndex: 0,
      leading: IconButton(
        tooltip: 'Back to dashboard',
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.managerDashboard);
          }
        },
      ),
      body: ManagerPagePadding(
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.managerDashboard);
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.managerDashboard),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Home'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < _policies.length; i++) ...[
              Card(
                child: ListTile(
                  onTap: () => _editValue(i),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Icon(
                    _policies[i].$3,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  title: Text(
                    _policies[i].$1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _policies[i].$2,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 9),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_values[i]}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 7),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Save Changes',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Policies saved (demo)')),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Demo mode: policy values are stored locally for this session only.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
