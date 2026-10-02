import 'package:flutter/material.dart';

import '../../librarian/theme/librarian_theme.dart';

/// Labelled input from the Login design: bold label, white rounded field
/// with a leading icon and an optional trailing widget (e.g. show password).
class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: LibrarianColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LibrarianSpacing.sm + 4),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: LibrarianColors.secondaryText),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, color: LibrarianColors.secondaryText),
            ),
            suffixIcon: trailing,
            filled: true,
            fillColor: LibrarianColors.card,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: border(LibrarianColors.border),
            enabledBorder: border(LibrarianColors.primary.withValues(alpha: 0.35)),
            focusedBorder: border(LibrarianColors.primary, 2),
          ),
        ),
      ],
    );
  }
}
