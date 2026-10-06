import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../../../core/services/image_storage_service.dart';
import '../data/librarian_repository.dart';
import '../models/action_result.dart';
import '../models/seat_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_validators.dart';
import '../widgets/form_action_buttons.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/info_section_card.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';

/// Add New Seat form (Figma): preview, seat details, seat type and features.
/// With a [seatId] the same form edits that seat.
class AddSeatScreen extends StatefulWidget {
  const AddSeatScreen({super.key, this.seatId});

  final String? seatId;

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

  LibrarianRepository? _repository;
  SeatRecord? _editing;

  /// New photo picked in this form (uploaded on save).
  ImageUpload? _image;
  bool _removeImage = false;
  bool _saving = false;
  double? _uploadProgress;

  bool get _isEdit => widget.seatId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository != null) return;
    _repository = LibrarianScope.read(context).repository..addListener(_onDataChanged);
    _fillForm();
  }

  /// When editing, the seat may arrive from Firestore after the page opens.
  void _onDataChanged() {
    if (_isEdit && _editing == null) setState(_fillForm);
  }

  void _fillForm() {
    if (!_isEdit || _editing != null) return;
    final seat = _repository!.seatById(widget.seatId!);
    if (seat == null) return;
    _editing = seat;
    _seatNumber.text = seat.seatNumber;
    _zone.text = seat.zone;
    _readingRoom.text = seat.readingRoom;
    _note.text = seat.note;
    _type = seat.type;
    _power = seat.hasPowerOutlet;
    _lamp = seat.hasReadingLamp;
    _accessible = seat.isAccessible;
    _window = seat.isNearWindow;
  }

  @override
  void dispose() {
    _repository?.removeListener(_onDataChanged);
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
    if (repository.seatNumberExists(value!, _readingRoom.text, exceptSeatId: widget.seatId)) {
      return 'Seat ${value.trim().toUpperCase()} already exists in this room';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final repository = LibrarianScope.read(context).repository;
    final seatNumber = _seatNumber.text.trim().toUpperCase();
    setState(() {
      _saving = true;
      _uploadProgress = _image == null ? null : 0;
    });
    void onProgress(double value) {
      if (mounted) setState(() => _uploadProgress = value);
    }

    final ActionResult result;
    if (_isEdit) {
      result = await repository.updateSeat(
        id: widget.seatId!,
        seatNumber: seatNumber,
        zone: _zone.text,
        readingRoom: _readingRoom.text,
        type: _type!,
        hasPowerOutlet: _power,
        hasReadingLamp: _lamp,
        isAccessible: _accessible,
        isNearWindow: _window,
        note: _note.text,
        newImage: _image,
        removeImage: _removeImage,
        onUploadProgress: onProgress,
      );
    } else {
      result = await repository.addSeat(
        seatNumber: seatNumber,
        zone: _zone.text,
        readingRoom: _readingRoom.text,
        type: _type!,
        hasPowerOutlet: _power,
        hasReadingLamp: _lamp,
        isAccessible: _accessible,
        isNearWindow: _window,
        note: _note.text,
        image: _image,
        onUploadProgress: onProgress,
      );
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _uploadProgress = null;
    });

    // Only report success when the repository confirms the save.
    if (result.success) {
      context.go(
        LibrarianRoutes.seats,
        extra: _isEdit
            ? 'Seat $seatNumber was updated.'
            : 'Seat $seatNumber added to ${_readingRoom.text.trim()}.',
      );
    } else {
      _showMessage(result.message!);
    }
  }

  Future<void> _delete() async {
    final seat = _editing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Seat ${seat.seatNumber}?'),
        content: const Text(
          'The seat will be removed from the seat map and students can no '
          'longer book it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: LibrarianColors.unavailable),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await LibrarianScope.read(context).repository.deleteSeat(seat.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      context.go(LibrarianRoutes.seats, extra: 'Seat ${seat.seatNumber} was deleted.');
    } else {
      _showMessage(result.message!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;
    final header = LibrarianPageHeader(
      title: _isEdit ? 'Edit Seat' : 'Add New Seat',
      subtitle: _isEdit
          ? 'Update this reading-room seat'
          : 'Register a new reading-room seat',
    );

    if (_isEdit && _editing == null) {
      return LibrarianPage(
        maxWidth: 760,
        children: [
          header,
          if (repository.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            const LibrarianEmptyState(
              icon: Icons.search_off,
              title: 'Seat not found',
              message: 'It may have been removed.',
            ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: LibrarianPage(
        maxWidth: 760,
        children: [
          header,
          InfoSectionCard(
            children: [
              ImageUploadField(
                label: 'Seat Photo',
                previewSize: const Size(200, 130),
                placeholder: Container(
                  color: LibrarianColors.lightBlue,
                  child: Icon(
                    Icons.photo_outlined,
                    size: 48,
                    color: LibrarianColors.primary,
                  ),
                ),
                picked: _image,
                savedUrl: _removeImage ? null : _editing?.imageUrl,
                enabled: repository.supportsImageUpload,
                disabledReason:
                    'Seat photos need Firebase Storage (not available with demo data).',
                uploadProgress: _uploadProgress,
                onPicked: (image) => setState(() {
                  _image = image;
                  _removeImage = false;
                }),
                onRemove: () => setState(() {
                  _image = null;
                  _removeImage = _editing?.imageUrl != null;
                }),
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
            saveLabel: _isEdit ? 'Save Changes' : 'Save Seat',
            onSave: _save,
            onCancel: () => context.go(LibrarianRoutes.seats),
            saving: _saving,
          ),
          if (_isEdit) ...[
            const SizedBox(height: LibrarianSpacing.md),
            OutlinedButton.icon(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Seat'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                foregroundColor: LibrarianColors.unavailable,
                side: BorderSide(color: LibrarianColors.unavailable),
              ),
            ),
          ],
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
            Text(
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
                style: TextStyle(color: LibrarianColors.text, fontSize: 17),
              ),
            ),
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          ],
        ),
      ),
    );
  }
}
