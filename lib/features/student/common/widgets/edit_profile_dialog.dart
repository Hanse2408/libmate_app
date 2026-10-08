import 'package:flutter/material.dart';
import '../data/student_library_repository.dart';
import 'student_palette.dart';
import 'student_avatar.dart';
import '../../../../core/services/image_storage_service.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.library});
  final StudentLibraryRepository library;
  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.library.student.name);
  late final _phone = TextEditingController(text: widget.library.student.phone);
  bool _saving = false;
  bool _picking = false;
  ImageUpload? _photo;
  bool _removePhoto = false;

  Future<void> _pickPhoto() async {
    if (_saving || _picking) return;
    setState(() { _picking = true; _error = null; });
    try {
      final (photo, error) = await ImagePickerService.instance.pickImage();
      if (!mounted) return;
      setState(() {
        _error = error;
        if (photo != null) { _photo = photo; _removePhoto = false; }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open your photos. Please try again.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _error;

  @override
  void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final result = await widget.library.updateProfile(name: _name.text, phone: _phone.text, photo: _photo, removePhoto: _removePhoto);
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() { _saving = false; _error = result.message ?? 'Could not save your profile. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentPalette.of(context);
    InputDecoration decoration(String label, IconData icon) => InputDecoration(
      labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: colors.field,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.primary, width: 1.5)),
    );
    return PopScope(canPop: !_saving && !_picking, child: Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(child: Form(key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.fromLTRB(22, 14, 10, 18),
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [colors.blueTint, colors.goldTint], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(15)),
                  child: Icon(Icons.manage_accounts_rounded, color: colors.primary, size: 27)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Edit profile', style: TextStyle(color: colors.text, fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Make LibMate yours', style: TextStyle(color: colors.muted, fontSize: 12)),
                ])),
                IconButton(tooltip: 'Close', onPressed: _saving || _picking ? null : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded)),
              ])),
            Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Column(children: [
                StudentAvatar(name: _name.text, size: 82,
                  photoUrl: _removePhoto ? null : widget.library.student.photoUrl,
                  preview: _photo?.bytes),
                const SizedBox(height: 8),
                Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                  TextButton.icon(onPressed: _saving || _picking ? null : _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(_picking ? 'Opening photos?' : 'Choose photo')),
                  if (_photo != null || (!_removePhoto && widget.library.student.photoUrl != null))
                    TextButton(onPressed: _saving || _picking ? null : () => setState(() {
                      _photo = null; _removePhoto = true;
                    }), child: const Text('Remove photo')),
                ]),
                Text('JPG, PNG or WebP ? up to 5 MB', style: TextStyle(color: colors.muted, fontSize: 11)),
              ])),
              const SizedBox(height: 20),
              TextFormField(key: const ValueKey('profile-name'), controller: _name,
                enabled: !_saving, textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name], textInputAction: TextInputAction.next,
                decoration: decoration('Full name', Icons.person_outline_rounded),
                validator: (value) => (value?.trim().length ?? 0) < 2 || value!.trim().length > 80
                  ? 'Enter a name between 2 and 80 characters.' : null),
              const SizedBox(height: 16),
              TextFormField(key: const ValueKey('profile-phone'), controller: _phone,
                enabled: !_saving, keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber],
                decoration: decoration('Phone number (optional)', Icons.phone_outlined),
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) return null;
                  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
                  return !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(phone) || digits.length < 7 || digits.length > 15
                    ? 'Enter a valid phone number.' : null;
                }),
              const SizedBox(height: 18),
              Container(width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.blueTint, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.lock_outline_rounded, size: 15, color: colors.primary),
                    const SizedBox(width: 6), Text('Account details', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700))]),
                  const SizedBox(height: 8),
                  Text('Student ID: ${widget.library.student.studentId}', style: TextStyle(color: colors.text, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(widget.library.student.email, style: TextStyle(color: colors.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('Your student ID and sign-in email stay linked to your account.', style: TextStyle(color: colors.muted, fontSize: 11, height: 1.4)),
                ])),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 14),
                child: Text(_error!, style: TextStyle(color: colors.error, fontSize: 13))),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _saving || _picking ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: _saving || _picking ? null : _save,
                  child: _saving ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save changes'))),
              ]),
            ])),
          ])),
        )),
    ));
  }
}
