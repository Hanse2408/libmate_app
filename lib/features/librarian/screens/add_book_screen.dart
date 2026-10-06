import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../../../core/services/image_storage_service.dart';
import '../data/librarian_repository.dart';
import '../models/action_result.dart';
import '../models/book_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_validators.dart';
import '../widgets/book_cover.dart';
import '../widgets/form_action_buttons.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/info_section_card.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';

/// Add New Book form (Figma). With a [bookId] the same form edits that book.
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key, this.bookId});

  final String? bookId;

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _isbn = TextEditingController();
  final _category = TextEditingController();
  final _language = TextEditingController(text: 'English');
  final _copies = TextEditingController();
  final _shelf = TextEditingController();
  final _description = TextEditingController();
  final _publisher = TextEditingController();
  final _year = TextEditingController();
  final _pages = TextEditingController();

  LibrarianRepository? _repository;
  BookRecord? _editing;

  /// Saved cover (Cloudinary URL or older asset path); null when removed.
  String? _coverAsset;

  /// Newly picked cover, uploaded when the form is saved.
  ImageUpload? _coverImage;
  double? _uploadProgress;
  bool _saving = false;

  bool get _isEdit => widget.bookId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository != null) return;
    _repository = LibrarianScope.read(context).repository..addListener(_onDataChanged);
    _fillForm();
  }

  /// When editing, the book may arrive from Firestore after the page opens.
  void _onDataChanged() {
    if (_isEdit && _editing == null) setState(_fillForm);
  }

  /// Fills the form once with the book being edited.
  void _fillForm() {
    if (!_isEdit || _editing != null) return;
    final book = _repository!.bookById(widget.bookId!);
    if (book == null) return;
    _editing = book;
    _title.text = book.title;
    _author.text = book.author;
    _isbn.text = book.isbn;
    _category.text = book.category;
    _language.text = book.language;
    _copies.text = '${book.totalCopies}';
    _shelf.text = book.shelfLocation;
    _description.text = book.description;
    _coverAsset = book.coverAsset;
    _publisher.text = book.publisher;
    _year.text = book.publishedYear > 0 ? '${book.publishedYear}' : '';
    _pages.text = book.pages > 0 ? '${book.pages}' : '';
  }

  @override
  void dispose() {
    _repository?.removeListener(_onDataChanged);
    for (final controller in [
      _title,
      _author,
      _isbn,
      _category,
      _language,
      _copies,
      _shelf,
      _description,
      _publisher,
      _year,
      _pages,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Format check plus "another book already has this ISBN".
  String? _validateIsbn(String? value) {
    final error = LibrarianValidators.isbn(value);
    if (error != null) return error;
    final repository = LibrarianScope.read(context).repository;
    if (repository.isbnExists(value!, exceptBookId: widget.bookId)) {
      return 'A book with this ISBN already exists';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onUploadProgress(double value) {
    if (mounted) setState(() => _uploadProgress = value);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final repository = LibrarianScope.read(context).repository;
    final title = _title.text.trim();
    final copies = int.parse(_copies.text.trim());
    final publishedYear = int.tryParse(_year.text.trim()) ?? 0;
    final pages = int.tryParse(_pages.text.trim()) ?? 0;
    setState(() {
      _saving = true;
      _uploadProgress = _coverImage == null ? null : 0;
    });

    ActionResult result;
    try {
      if (_isEdit) {
        result = await repository.updateBook(
          id: widget.bookId!,
          title: title,
          author: _author.text,
          isbn: _isbn.text,
          category: _category.text,
          language: _language.text,
          shelfLocation: _shelf.text,
          totalCopies: copies,
          description: _description.text,
          coverAsset: _coverAsset,
          coverImage: _coverImage,
          onUploadProgress: _onUploadProgress,
          publisher: _publisher.text,
          publishedYear: publishedYear,
          pages: pages,
        );
      } else {
        result = await repository.addBook(
          title: title,
          author: _author.text,
          isbn: _isbn.text,
          category: _category.text,
          language: _language.text,
          shelfLocation: _shelf.text,
          totalCopies: copies,
          description: _description.text,
          coverAsset: _coverAsset,
          coverImage: _coverImage,
          onUploadProgress: _onUploadProgress,
          publisher: _publisher.text,
          publishedYear: publishedYear,
          pages: pages,
        );
      }
    } catch (_) {
      result = const ActionResult.failure('The book could not be saved. Please try again.');
    } finally {
      // Always stop the spinner, whatever happened.
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = null;
        });
      }
    }
    if (!mounted) return;

    // Only report success when the repository confirms the save.
    if (result.success) {
      context.go(
        LibrarianRoutes.books,
        extra: _isEdit ? '"$title" was updated.' : '"$title" added to the catalogue.',
      );
    } else {
      _showMessage(result.message!);
    }
  }

  Future<void> _delete() async {
    final book = _editing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this book?'),
        content: Text(
          '"${book.title}" will be removed from the catalogue and students '
          'will no longer see it. This cannot be undone.',
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
    final result = await LibrarianScope.read(context).repository.deleteBook(book.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      context.go(LibrarianRoutes.books, extra: '"${book.title}" was deleted.');
    } else {
      _showMessage(result.message!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;
    final header = LibrarianPageHeader(
      title: _isEdit ? 'Edit Book' : 'Add New Book',
      subtitle: _isEdit
          ? 'Update this book in the library catalogue'
          : 'Add a book to the library catalogue',
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
              title: 'Book not found',
              message: 'It may have been removed from the catalogue.',
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
                label: 'Book Cover',
                previewSize: const Size(120, 160),
                placeholder: BookCover(
                  title: _title.text.trim(),
                  width: 120,
                  height: 160,
                ),
                picked: _coverImage,
                savedUrl: _coverAsset,
                enabled: repository.supportsImageUpload,
                disabledReason: 'Cover uploads are unavailable with demo data.',
                uploadProgress: _uploadProgress,
                chooseLabel: 'Choose Cover',
                replaceLabel: 'Change Cover',
                onPicked: (image) => setState(() => _coverImage = image),
                onRemove: () => setState(() {
                  _coverImage = null;
                  _coverAsset = null;
                }),
              ),
            ],
          ),
          InfoSectionCard(
            title: 'Book Details',
            children: [
              LabeledTextField(
                label: 'Book Title',
                controller: _title,
                hint: 'Clean Code',
                textCapitalization: TextCapitalization.words,
                validator: (v) => LibrarianValidators.required(v, 'Book title'),
                onChanged: (_) => setState(() {}), // live cover preview
              ),
              LabeledTextField(
                label: 'Author',
                controller: _author,
                hint: 'Robert C. Martin',
                textCapitalization: TextCapitalization.words,
                validator: (v) => LibrarianValidators.required(v, 'Author'),
              ),
              LabeledTextField(
                label: 'ISBN',
                controller: _isbn,
                hint: '978-0132350884',
                keyboardType: TextInputType.number,
                validator: _validateIsbn,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Category',
                      controller: _category,
                      hint: 'Software Eng.',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => LibrarianValidators.required(v, 'Category'),
                    ),
                  ),
                  const SizedBox(width: LibrarianSpacing.md),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Language',
                      controller: _language,
                      hint: 'English',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => LibrarianValidators.required(v, 'Language'),
                    ),
                  ),
                ],
              ),
              LabeledTextField(
                label: 'Publisher',
                controller: _publisher,
                hint: 'Prentice Hall (optional)',
                textCapitalization: TextCapitalization.words,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Published Year',
                      controller: _year,
                      hint: '2008',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: LibrarianValidators.optionalYear,
                    ),
                  ),
                  const SizedBox(width: LibrarianSpacing.md),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Pages',
                      controller: _pages,
                      hint: '464',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: LibrarianValidators.optionalPages,
                    ),
                  ),
                ],
              ),
            ],
          ),
          InfoSectionCard(
            title: 'Inventory',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Total Copies',
                      controller: _copies,
                      hint: '5',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => LibrarianValidators.positiveCount(v, 'Total copies'),
                    ),
                  ),
                  const SizedBox(width: LibrarianSpacing.md),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Shelf-Location',
                      controller: _shelf,
                      hint: 'CS-14-B',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => LibrarianValidators.required(v, 'Shelf location'),
                    ),
                  ),
                ],
              ),
              LabeledTextField(
                label: 'Description',
                controller: _description,
                hint: 'A short summary of the book (optional)',
                maxLines: 3,
              ),
            ],
          ),
          FormActionButtons(
            saveLabel: _isEdit ? 'Save Changes' : 'Save Book',
            onSave: _save,
            onCancel: () => context.go(LibrarianRoutes.books),
            saving: _saving,
          ),
          if (_isEdit) ...[
            const SizedBox(height: LibrarianSpacing.md),
            OutlinedButton.icon(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Book'),
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
