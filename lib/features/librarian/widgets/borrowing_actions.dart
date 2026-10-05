import 'package:flutter/material.dart';

import '../models/borrowing_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';

/// "Mark as Returned" and "Renew" for a loan, shared by the Borrowing list
/// and Borrowing Details. The repository decides whether the action is
/// allowed; these functions only confirm and show the result.
class BorrowingActions {
  const BorrowingActions._();

  static Future<void> markReturned(BuildContext context, BorrowingRecord loan) async {
    final repository = LibrarianScope.read(context).repository;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as returned?'),
        content: Text('"${loan.bookTitle}" borrowed by ${loan.memberName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Mark Returned'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await repository.markBorrowingReturned(loan.id);
    if (!context.mounted) return;
    _showMessage(
      context,
      result.success ? '"${loan.bookTitle}" marked as returned.' : result.message!,
      success: result.success,
    );
  }

  static Future<void> renew(BuildContext context, BorrowingRecord loan) async {
    final repository = LibrarianScope.read(context).repository;
    final result = await repository.renewBorrowing(loan.id);
    if (!context.mounted) return;

    final newDue = repository.borrowingById(loan.id)!.dueDate;
    _showMessage(
      context,
      result.success
          ? 'Loan renewed. New due date: ${LibrarianFormatters.date(newDue)}.'
          : result.message!,
      success: result.success,
    );
  }

  static void _showMessage(BuildContext context, String text, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: success ? null : LibrarianColors.unavailable,
      ));
  }
}
