import 'package:flutter/material.dart';

import '../widgets/manager_widgets.dart';

class ManagerPoliciesScreen extends StatefulWidget {
  const ManagerPoliciesScreen({super.key});

  @override
  State<ManagerPoliciesScreen> createState() => _ManagerPoliciesScreenState();
}

class _ManagerPoliciesScreenState extends State<ManagerPoliciesScreen> {
  final _values = [3, 5, 24, 2];

  static const _policies = [
    ('Book Reservation Limit', 'Max books per student', Icons.menu_book_outlined),
    ('Borrowing Limit', 'Max books to borrow', Icons.library_books_outlined),
    ('Reservation Expiry', 'Hours before auto-cancel', Icons.access_time),
    ('Reading Room Booking', 'Max booking time (hours)', Icons.event_seat_outlined),
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
                onPressed: value > 1 ? () => setDialogState(() => value--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
      body: ManagerPagePadding(
        child: ListView(
          children: [
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
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _policies[i].$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
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
          ],
        ),
      ),
    );
  }
}
