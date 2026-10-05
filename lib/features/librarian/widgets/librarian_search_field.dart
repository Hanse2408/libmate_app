import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Rounded white search box with a search icon and a clear button.
class LibrarianSearchField extends StatefulWidget {
  const LibrarianSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<LibrarianSearchField> createState() => _LibrarianSearchFieldState();
}

class _LibrarianSearchFieldState extends State<LibrarianSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
      borderSide: const BorderSide(color: LibrarianColors.border),
    );

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {}); // show / hide the clear button
      },
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: LibrarianColors.secondaryText),
        prefixIcon: const Icon(Icons.search, color: LibrarianColors.secondaryText),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: _clear,
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: border,
        enabledBorder: border,
      ),
    );
  }
}
