import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// "Cancel" + "Save ..." buttons at the bottom of the Add Book / Add Seat forms.
class FormActionButtons extends StatelessWidget {
  const FormActionButtons({
    super.key,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
    this.saving = false,
  });

  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  /// While true both buttons are disabled and Save shows a spinner, so the
  /// form cannot be submitted twice.
  final bool saving;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
              foregroundColor: LibrarianColors.text,
              side: BorderSide(
                color: LibrarianColors.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
              shape: shape,
              textStyle: textStyle,
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: LibrarianSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              shape: shape,
              textStyle: textStyle,
            ),
            child: saving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(saveLabel, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
