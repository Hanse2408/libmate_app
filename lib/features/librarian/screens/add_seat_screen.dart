import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/seat_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_validators.dart';
import '../widgets/form_action_buttons.dart';
import '../widgets/info_section_card.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/seat_tile.dart';

/// Add New Seat form (Figma): preview, seat details, seat type and features.
class AddSeatScreen extends StatefulWidget {
  const AddSeatScreen({super.key});

  @override
  State<AddSeatScreen> createState() => _AddSeatScreenState();
}

class _AddSeatScreenState extends State<AddSeatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seatNumber = TextEditingController();
  final _zone = TextEditingController();
  final _readingRoom = TextEditingController(text: 'Reading Room A');
  final _note = TextEditingController();

  SeatType? _type;
  bool _power = false;
  bool _lamp = false;
  bool _accessible = false;
  bool _window = false;

  @override
  void dispose() {
    _seatNumber.dispose();
    _zone.dispose();
    _readingRoom.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Format check plus "already exists in this reading room".
  String? _validateSeatNumber(String? value) {
    final error = LibrarianValidators.seatNumber(value);
    if (error != null) return error;
    final repository = LibrarianScope.read(context).repository;
    if (repository.seatNumberExists(value!, _readingRoom.text)) {
      return 'Seat ${value.trim().toUpperCase()} already exists in this room';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = LibrarianScope.read(context).repository;
    final seatNumber = _seatNumber.text.trim().toUpperCase();
    final result = await repository.addSeat(
      seatNumber: seatNumber,
      zone: _zone.text,
      readingRoom: _readingRoom.text,
      type: _type!,
      hasPowerOutlet: _power,
      hasReadingLamp: _lamp,
      isAccessible: _accessible,
      isNearWindow: _window,
      note: _note.text,
    );
    if (!mounted) return;

    if (result.success) {
      context.go(
        LibrarianRoutes.seats,
        extra: 'Seat $seatNumber added to ${_readingRoom.text.trim()}.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewNumber = _seatNumber.text.trim().toUpperCase();

    return Form(
      key: _formKey,
      child: LibrarianPage(
        maxWidth: 760,
        children: [
          const LibrarianPageHeader(
            title: 'Add New Seat',
            subtitle: 'Register a new reading-room seat',
          ),
          InfoSectionCard(
            children: [
              Center(
                child: previewNumber.isEmpty
                    ? Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: LibrarianColors.lightBlue,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.chair_outlined,
                          size: 64,
                          color: LibrarianColors.primary,
                        ),
                      )
                    : SizedBox(
                        width: 96,
                        child: SeatTile(
                          seat: SeatRecord(
                            id: 'preview',
                            seatNumber: previewNumber,
                            zone: _zone.text,
                            readingRoom: _readingRoom.text,
                            type: _type ?? SeatType.individualDesk,
                            status: SeatStatus.available,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: LibrarianSpacing.md),
              const Text(
                'Seat Preview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LibrarianColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LibrarianSpacing.xs),
              const Text(
                'Seat number will appear on the map',
                textAlign: TextAlign.center,
                style: TextStyle(color: LibrarianColors.secondaryText),
              ),
            ],
          ),
          InfoSectionCard(
            title: 'Seat Details',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Seat Number',
                      controller: _seatNumber,
                      hint: 'D09',
                      textCapitalization: TextCapitalization.characters,
                      validator: _validateSeatNumber,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: LibrarianSpacing.md),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Row / Zone',
                      controller: _zone,
                      hint: 'Row D',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => LibrarianValidators.required(v, 'Row / zone'),
                    ),
                  ),
                ],
              ),
              LabeledTextField(
                label: 'Reading Room',
                controller: _readingRoom,
                hint: 'Reading Room A',
                textCapitalization: TextCapitalization.words,
                validator: (v) => LibrarianValidators.required(v, 'Reading room'),
              ),
              _SeatTypeField(
                value: _type,
                onChanged: (type) => setState(() => _type = type),
              ),
              LabeledTextField(
                label: 'Note',
                controller: _note,
                hint: 'e.g. Newly added desk near the reference section.',
                maxLines: 2,
              ),
            ],
          ),
          InfoSectionCard(
            title: 'Features',
            children: [
              _FeatureToggle(
                icon: Icons.power_outlined,
                label: 'Power Outlet',
                value: _power,
                onChanged: (v) => setState(() => _power = v),
              ),
              _FeatureToggle(
                icon: Icons.lightbulb_outline,
                label: 'Reading Lamp',
                value: _lamp,
                onChanged: (v) => setState(() => _lamp = v),
              ),
              _FeatureToggle(
                icon: Icons.accessible,
                label: 'Accessible',
                value: _accessible,
                onChanged: (v) => setState(() => _accessible = v),
              ),
              _FeatureToggle(
                icon: Icons.window_outlined,
                label: 'Near Window',
                value: _window,
                onChanged: (v) => setState(() => _window = v),
              ),
            ],
          ),
          FormActionButtons(
            saveLabel: 'Save Seat',
            onSave: _save,
            onCancel: () => context.go(LibrarianRoutes.seats),
          ),
        ],
      ),
    );
  }
}

/// "SEAT TYPE" choice chips, validated as part of the form (one is required).
class _SeatTypeField extends StatelessWidget {
  const _SeatTypeField({required this.value, required this.onChanged});

  final SeatType? value;
  final ValueChanged<SeatType> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<SeatType>(
      initialValue: value,
      validator: (_) => value == null ? 'Choose a seat type' : null,
      builder: (field) => Padding(
        padding: const EdgeInsets.only(bottom: LibrarianSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEAT TYPE',
              style: TextStyle(
                color: LibrarianColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LibrarianSpacing.sm),
            Wrap(
              spacing: LibrarianSpacing.sm,
              runSpacing: LibrarianSpacing.sm,
              children: [
                for (final type in SeatType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: value == type,
                    onSelected: (_) {
                      onChanged(type);
                      field.didChange(type);
                    },
                  ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  const _FeatureToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: LibrarianColors.lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: LibrarianColors.primary),
            ),
            const SizedBox(width: LibrarianSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: LibrarianColors.text, fontSize: 17),
              ),
            ),
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          ],
        ),
      ),
    );
  }
}
