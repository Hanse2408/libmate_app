import 'package:flutter/material.dart';

import '../models/reservation_record.dart';
import '../theme/librarian_theme.dart';

/// Asks the librarian to confirm a rejection and pick a reason.
/// Returns the reason, or null if the librarian cancelled.
Future<String?> showRejectReasonDialog(
  BuildContext context,
  ReservationRecord reservation,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RejectReasonDialog(reservation: reservation),
  );
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.reservation});

  final ReservationRecord reservation;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  static const String _other = 'Other';

  final TextEditingController _otherController = TextEditingController();
  String? _selected;

  List<String> get _reasons => widget.reservation.type == ReservationType.book
      ? const ['No copies available', 'Student has overdue books', 'Duplicate request', _other]
      : const ['Seat not available at that time', 'Seat under maintenance', 'Duplicate request', _other];

  /// The final reason, or null while the choice is incomplete.
  String? get _reason {
    if (_selected == null) return null;
    if (_selected != _other) return _selected;
    final text = _otherController.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject reservation?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.reservation.studentName} · ${widget.reservation.itemName}\n'
              'Choose a reason. The student will see it.',
              style: const TextStyle(color: LibrarianColors.secondaryText),
            ),
            const SizedBox(height: LibrarianSpacing.md),
            Wrap(
              spacing: LibrarianSpacing.sm,
              runSpacing: LibrarianSpacing.sm,
              children: [
                for (final reason in _reasons)
                  ChoiceChip(
                    label: Text(reason),
                    selected: _selected == reason,
                    onSelected: (_) => setState(() => _selected = reason),
                  ),
              ],
            ),
            if (_selected == _other) ...[
              const SizedBox(height: LibrarianSpacing.md),
              TextField(
                controller: _otherController,
                autofocus: true,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Enter the reason'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(_reason),
          style: FilledButton.styleFrom(
            backgroundColor: LibrarianColors.unavailable,
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
