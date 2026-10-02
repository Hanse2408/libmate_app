import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';

/// Small dialogs used by the Settings screen to edit preferences.

/// Asks for a whole number between [min] and [max] using − / + buttons.
/// Returns the chosen value, or null if cancelled.
Future<int?> showNumberSettingDialog(
  BuildContext context, {
  required String title,
  required int value,
  required int min,
  required int max,
  required String unit,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _NumberDialog(title: title, initial: value, min: min, max: max, unit: unit),
  );
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
    required this.unit,
  });

  final String title;
  final int initial;
  final int min;
  final int max;
  final String unit;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.outlined(
            tooltip: 'Decrease',
            onPressed: _value > widget.min ? () => setState(() => _value--) : null,
            icon: const Icon(Icons.remove),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LibrarianSpacing.md),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$_value ${widget.unit}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Increase',
            onPressed: _value < widget.max ? () => setState(() => _value++) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Asks for opening and closing hours (whole hours, 06:00 - 23:00).
/// Returns (opening, closing), or null if cancelled.
Future<(int, int)?> showOpeningHoursDialog(
  BuildContext context, {
  required int opening,
  required int closing,
}) {
  return showDialog<(int, int)>(
    context: context,
    builder: (_) => _HoursDialog(opening: opening, closing: closing),
  );
}

class _HoursDialog extends StatefulWidget {
  const _HoursDialog({required this.opening, required this.closing});

  final int opening;
  final int closing;

  @override
  State<_HoursDialog> createState() => _HoursDialogState();
}

class _HoursDialogState extends State<_HoursDialog> {
  late int _opening = widget.opening;
  late int _closing = widget.closing;

  static final List<int> _hours = [for (var h = 6; h <= 23; h++) h];

  static String label(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  Widget _dropdown(String text, int value, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: text),
      items: [for (final h in _hours) DropdownMenuItem(value: h, child: Text(label(h)))],
      onChanged: (h) => setState(() => onChanged(h!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = _opening < _closing;
    return AlertDialog(
      title: const Text('Library opening hours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dropdown('Opens at', _opening, (h) => _opening = h),
          const SizedBox(height: LibrarianSpacing.md),
          _dropdown('Closes at', _closing, (h) => _closing = h),
          if (!valid)
            const Padding(
              padding: EdgeInsets.only(top: LibrarianSpacing.sm),
              child: Text(
                'Closing time must be after opening time.',
                style: TextStyle(color: LibrarianColors.unavailable),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: valid ? () => Navigator.of(context).pop((_opening, _closing)) : null,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
