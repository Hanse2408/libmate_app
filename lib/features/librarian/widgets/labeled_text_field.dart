import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/librarian_theme.dart';

/// Form field with an uppercase label above it and the light-blue filled
/// style from the Add Book / Add Seat designs.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
      borderSide: BorderSide(color: color),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: LibrarianColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: LibrarianSpacing.sm),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: LibrarianColors.secondaryText),
              filled: true,
              fillColor: LibrarianColors.lightBlue,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LibrarianSpacing.md + 4,
                vertical: 14,
              ),
              border: border(LibrarianColors.border),
              enabledBorder: border(LibrarianColors.primary.withValues(alpha: 0.2)),
              focusedBorder: border(LibrarianColors.primary),
              errorMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
