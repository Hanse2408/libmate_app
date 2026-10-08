import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Loan length remains numeric; the unit is supplied by the interface.
class LoanPeriodField extends StatelessWidget {
  const LoanPeriodField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });
  final int initialValue;
  final ValueChanged<int> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: '$initialValue',
    enabled: enabled,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: const InputDecoration(
      labelText: 'Loan period (1–30 days)',
      helperText: 'Enter 1–30 days',
      suffixText: 'days',
      errorMaxLines: 3,
      helperMaxLines: 2,
      border: OutlineInputBorder(),
    ),
    validator: (value) {
      final days = int.tryParse(value ?? '');
      return days == null || days < 1 || days > 30
          ? 'Enter a whole number from 1 to 30.'
          : null;
    },
    onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
  );
}

Future<int?> selectLoanPeriod(BuildContext context, int initialValue) async {
  final form = GlobalKey<FormState>();
  var days = initialValue;
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Loan period'),
      content: Form(
        key: form,
        child: LoanPeriodField(
          initialValue: initialValue,
          onChanged: (value) => days = value,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate())
              Navigator.pop(dialogContext, days);
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
}
