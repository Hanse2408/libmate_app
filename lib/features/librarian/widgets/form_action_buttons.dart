import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// "Cancel" + "Save ..." buttons at the bottom of the Add Book / Add Seat forms.
class FormActionButtons extends StatelessWidget {
  const FormActionButtons({
    super.key,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
  });

  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;

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
            onPressed: onCancel,
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
            onPressed: onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              shape: shape,
              textStyle: textStyle,
            ),
            child: Text(saveLabel, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
