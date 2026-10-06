import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/ebook_service.dart';
import '../../../models/action_result.dart';
import '../../../models/ebook.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_validators.dart';
import 'book_cover.dart';
import 'book_cover_asset_field.dart';
import 'labeled_text_field.dart';

/// "Add new e-book" card from the E-book Management design: 1. cover,
/// 2. book details, 3. PDF, then Save draft / Publish e-book. With an
/// [initial] e-book the same form edits it.
class EbookForm extends StatefulWidget {
  const EbookForm({super.key, this.initial, required this.onSaved});

  final EbookRecord? initial;

  /// Called with a success message after Firestore confirmed the save.
  final ValueChanged<String> onSaved;

  @override
  State<EbookForm> createState() => _EbookFormState();
}

class _EbookFormState extends State<EbookForm> {
  static const List<String> _defaultCategories = [
    'Software Engineering',
    'Computer Science',
    'Information Technology',
    'Business',
    'Mathematics',
    'Science',
    'HCI',
    'Fiction',
    'Other',
  ];
  static const List<String> _languages = ['English', 'Sinhala', 'Tamil', 'Other'];

  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _author = TextEditingController(text: widget.initial?.author);
  late final _isbn = TextEditingController(text: widget.initial?.isbn);
  late final _description = TextEditingController(text: widget.initial?.description);
  late final _publisher = TextEditingController(text: widget.initial?.publisher);
  late final _year = TextEditingController(
    text: (widget.initial?.publishedYear ?? 0) > 0 ? '${widget.initial!.publishedYear}' : '',
  );
  late final _pages = TextEditingController(
    text: (widget.initial?.pages ?? 0) > 0 ? '${widget.initial!.pages}' : '',
  );
  late final _location = TextEditingController(
    text: widget.initial?.location ?? EbookRecord.defaultLocation,
  );

  late String? _category = widget.initial?.category;
  late String? _language = widget.initial?.language ?? 'English';
  late String? _coverAsset = widget.initial?.coverAsset;

  /// PDF picked in this form (uploaded when saving).
  PdfFile? _pdf;
  String? _coverError;
  String? _pdfError;
  EbookStatus? _savingAs;

  bool get _isEdit => widget.initial != null;
  bool get _hasPdf => _pdf != null || (widget.initial?.hasPdf ?? false);

  @override
  void dispose() {
    for (final c in [_title, _author, _isbn, _description, _publisher, _year, _pages, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseCover() async {
    final chosen = await showBookCoverPicker(context, selected: _coverAsset);
    if (chosen != null) {
      setState(() {
        _coverAsset = chosen;
        _coverError = null;
      });
    }
  }

  Future<void> _choosePdf() async {
    try {
      final (pdf, error) = await PdfPickerService.instance.pickPdf();
      if (!mounted) return;
      if (pdf == null && error == null) return; // cancelled
      setState(() {
        if (pdf != null) _pdf = pdf;
        _pdfError = error;
      });
    } catch (_) {
      if (mounted) setState(() => _pdfError = 'Could not open the file picker.');
    }
  }

  Future<void> _save(EbookStatus status) async {
    final provider = LibrarianScope.read(context).ebooks();
    final formOk = _formKey.currentState!.validate();
    final publishing = status == EbookStatus.published;
    setState(() {
      _coverError = publishing && _coverAsset == null
          ? 'Choose a cover image before publishing.'
          : null;
      _pdfError = publishing && !_hasPdf ? 'Upload the PDF before publishing.' : _pdfError;
    });
    if (!formOk || _coverError != null || (publishing && !_hasPdf)) return;

    final initial = widget.initial;
    final ebook = EbookRecord(
      id: initial?.id ?? '',
      title: _title.text,
      author: _author.text,
      category: _category!,
      language: _language!,
      isbn: _isbn.text,
      description: _description.text,
      publisher: _publisher.text,
      publishedYear: int.tryParse(_year.text.trim()) ?? 0,
      pages: int.tryParse(_pages.text.trim()) ?? 0,
      location: _location.text,
      coverAsset: _coverAsset,
      pdfUrl: initial?.pdfUrl,
      pdfPath: initial?.pdfPath,
      pdfFileName: initial?.pdfFileName,
      pdfSizeBytes: initial?.pdfSizeBytes ?? 0,
      status: status,
    );

    setState(() => _savingAs = status);
    final ActionResult result = await provider.save(ebook: ebook, isNew: !_isEdit, newPdf: _pdf);
    if (!mounted) return;
    setState(() => _savingAs = null);

    if (result.success) {
      final title = ebook.title.trim();
      widget.onSaved(switch ((status, _isEdit)) {
        (EbookStatus.published, false) => '"$title" was published.',
        (EbookStatus.draft, false) => '"$title" was saved as a draft.',
        (EbookStatus.published, true) => '"$title" was updated and published.',
        (EbookStatus.draft, true) => '"$title" was saved as a draft.',
      });
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = LibrarianScope.of(context).ebooks();
    final books = LibrarianScope.of(context).repository.books;
    final categories = <String>{
      ..._defaultCategories,
      for (final b in books)
        if (b.category.trim().isNotEmpty) b.category.trim(),
      ?_category,
    }.toList()
      ..sort();

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final saving = provider.isSaving;
        return Form(
          key: _formKey,
          child: Container(
            margin: const EdgeInsets.only(bottom: LibrarianSpacing.md + 4),
            padding: const EdgeInsets.all(LibrarianSpacing.md + 4),
            decoration: BoxDecoration(
              color: LibrarianColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: LibrarianColors.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit e-book' : 'Add new e-book',
                        style: TextStyle(
                          color: LibrarianColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('* Required', style: TextStyle(color: LibrarianColors.secondaryText)),
                  ],
                ),
                const SizedBox(height: LibrarianSpacing.md),
                _StepTile(
                  key: const ValueKey('ebook-cover-step'),
                  leading: _coverAsset == null
                      ? Icon(Icons.add_photo_alternate_outlined, color: LibrarianColors.primary, size: 30)
                      : BookCover(title: _title.text, coverAsset: _coverAsset, width: 40, height: 54),
                  title: '1. Choose cover image *',
                  subtitle: _coverAsset == null
                      ? 'JPG, PNG or WebP from assets/images/books/'
                      : _coverAsset!.substring(_coverAsset!.lastIndexOf('/') + 1),
                  trailing: Icon(
                    _coverAsset == null ? Icons.file_upload_outlined : Icons.swap_horiz,
                    color: LibrarianColors.primary,
                  ),
                  error: _coverError,
                  onTap: saving ? null : _chooseCover,
                ),
                const SizedBox(height: LibrarianSpacing.lg),
                Text(
                  '2. Enter book details',
                  style: TextStyle(color: LibrarianColors.text, fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: LibrarianSpacing.md),
                _Pair(
                  LabeledTextField(
                    label: 'Book title *',
                    controller: _title,
                    hint: 'Clean Code',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => LibrarianValidators.required(v, 'Book title'),
                    onChanged: (_) => setState(() {}), // cover preview title
                  ),
                  LabeledTextField(
                    label: 'Author *',
                    controller: _author,
                    hint: 'Robert C. Martin',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => LibrarianValidators.required(v, 'Author'),
                  ),
                ),
                LabeledTextField(
                  label: 'ISBN',
                  controller: _isbn,
                  hint: '978-0132350884',
                  keyboardType: TextInputType.number,
                  validator: (v) => (v ?? '').trim().isEmpty ? null : LibrarianValidators.isbn(v),
                ),
                _Pair(
                  _LabeledDropdown(
                    label: 'Category *',
                    value: _category,
                    options: categories,
                    hint: 'Choose',
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) => v == null ? 'Category is required' : null,
                  ),
                  _LabeledDropdown(
                    label: 'Language *',
                    value: _language,
                    options: {..._languages, ?_language}.toList(),
                    hint: 'Choose',
                    onChanged: (v) => setState(() => _language = v),
                    validator: (v) => v == null ? 'Language is required' : null,
                  ),
                ),
                LabeledTextField(
                  label: 'Description',
                  controller: _description,
                  hint: 'A handbook of agile software craftsmanship.',
                  maxLines: 2,
                ),
                LabeledTextField(
                  label: 'Publisher',
                  controller: _publisher,
                  hint: 'Prentice Hall',
                  textCapitalization: TextCapitalization.words,
                ),
                _Pair(
                  LabeledTextField(
                    label: 'Published year',
                    controller: _year,
                    hint: '2008',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: LibrarianValidators.optionalYear,
                  ),
                  LabeledTextField(
                    label: 'Pages',
                    controller: _pages,
                    hint: '464',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: LibrarianValidators.optionalPages,
                  ),
                ),
                LabeledTextField(
                  label: 'Location',
                  controller: _location,
                  hint: EbookRecord.defaultLocation,
                  textCapitalization: TextCapitalization.words,
                ),
                _PdfStep(
                  pdf: _pdf,
                  existing: widget.initial,
                  error: _pdfError,
                  progress: provider.uploadProgress,
                  onTap: saving ? null : _choosePdf,
                ),
                const SizedBox(height: LibrarianSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: saving ? null : () => _save(EbookStatus.draft),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          backgroundColor: LibrarianColors.lightBlue,
                          foregroundColor: LibrarianColors.primary,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LibrarianSpacing.radius)),
                        ),
                        child: _savingAs == EbookStatus.draft
                            ? const _Spinner()
                            : const Text('Save draft', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: LibrarianSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: saving ? null : () => _save(EbookStatus.published),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LibrarianSpacing.radius)),
                        ),
                        child: _savingAs == EbookStatus.published
                            ? const _Spinner(onPrimary: true)
                            : const Text('Publish e-book', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Two fields side by side (one under the other on narrow phones).
class _Pair extends StatelessWidget {
  const _Pair(this.first, this.second);

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) return Column(children: [first, second]);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: LibrarianSpacing.md),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

/// Dropdown styled like LabeledTextField (uppercase label, tinted field).
class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.validator,
    this.hint,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validator;
  final String? hint;

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
            style: TextStyle(color: LibrarianColors.text, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: LibrarianSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            dropdownColor: LibrarianColors.card,
            icon: Icon(Icons.keyboard_arrow_down, color: LibrarianColors.secondaryText),
            style: TextStyle(color: LibrarianColors.text, fontSize: 16),
            hint: hint == null ? null : Text(hint!, style: TextStyle(color: LibrarianColors.secondaryText)),
            items: [
              for (final option in options)
                DropdownMenuItem(value: option, child: Text(option, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: LibrarianColors.lightBlue,
              contentPadding: const EdgeInsets.symmetric(horizontal: LibrarianSpacing.md + 4, vertical: 14),
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

/// Tinted, rounded step row ("1. Choose cover image *").
class _StepTile extends StatelessWidget {
  const _StepTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.error,
    this.dashed = false,
    this.footer,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final String? error;
  final bool dashed;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LibrarianSpacing.radius);
    final borderColor = error != null
        ? LibrarianColors.unavailable
        : LibrarianColors.primary.withValues(alpha: dashed ? 0.5 : 0.0);
    final body = Padding(
      padding: const EdgeInsets.all(LibrarianSpacing.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LibrarianColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: leading,
              ),
              const SizedBox(width: LibrarianSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: LibrarianColors.primary, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: LibrarianSpacing.sm),
              trailing,
            ],
          ),
          if (footer != null) ...[const SizedBox(height: LibrarianSpacing.sm), footer!],
          if (error != null) ...[
            const SizedBox(height: LibrarianSpacing.sm),
            Text(error!, style: TextStyle(color: LibrarianColors.unavailable, fontSize: 13)),
          ],
        ],
      ),
    );
    return Material(
      color: LibrarianColors.lightBlue,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: CustomPaint(
          foregroundPainter: _BorderPainter(color: borderColor, radius: LibrarianSpacing.radius, dashed: dashed),
          child: body,
        ),
      ),
    );
  }
}

/// "3. Upload PDF *" with the chosen / saved file and upload progress.
class _PdfStep extends StatelessWidget {
  const _PdfStep({
    required this.pdf,
    required this.existing,
    required this.error,
    required this.progress,
    required this.onTap,
  });

  final PdfFile? pdf;
  final EbookRecord? existing;
  final String? error;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final saved = existing != null && existing!.hasPdf;
    final String subtitle;
    if (pdf != null) {
      subtitle = '${pdf!.fileName} · ${EbookRecord.formatSize(pdf!.sizeBytes)}'
          '${saved ? ' (replaces the current PDF)' : ''}';
    } else if (saved) {
      final size = EbookRecord.formatSize(existing!.pdfSizeBytes);
      subtitle = '${existing!.pdfFileName ?? 'Current PDF'}${size.isEmpty ? '' : ' · $size'}';
    } else {
      subtitle = 'PDF only, up to 25 MB';
    }
    final hasFile = pdf != null || saved;
    return _StepTile(
      key: const ValueKey('ebook-pdf-step'),
      dashed: true,
      leading: Icon(
        hasFile ? Icons.picture_as_pdf_outlined : Icons.upload_file_outlined,
        color: hasFile ? LibrarianColors.unavailable : LibrarianColors.primary,
        size: 30,
      ),
      title: hasFile ? '3. PDF ${pdf != null ? 'selected' : 'uploaded'} *' : '3. Upload PDF *',
      subtitle: subtitle,
      trailing: Icon(hasFile ? Icons.swap_horiz : Icons.add, color: LibrarianColors.primary, size: 28),
      error: error,
      onTap: onTap,
      footer: progress == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 4),
                Text(
                  'Uploading PDF… ${(progress! * 100).round()}%',
                  style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 13),
                ),
              ],
            ),
    );
  }
}

/// Rounded border, solid or dashed (the PDF step in the design is dashed).
class _BorderPainter extends CustomPainter {
  const _BorderPainter({required this.color, required this.radius, required this.dashed});

  final Color color;
  final double radius;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BorderPainter old) =>
      old.color != color || old.radius != radius || old.dashed != dashed;
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.onPrimary = false});

  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: onPrimary ? Theme.of(context).colorScheme.onPrimary : LibrarianColors.primary,
      ),
    );
  }
}
