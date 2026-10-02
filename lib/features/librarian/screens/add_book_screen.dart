import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/action_result.dart';
import '../models/book_record.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_validators.dart';
import '../widgets/book_cover.dart';
import '../widgets/form_action_buttons.dart';
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

  BookRecord? _editing;
  bool _loaded = false;

  bool get _isEdit => widget.bookId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fill the form once when editing an existing book.
    if (_loaded || !_isEdit) return;
    _loaded = true;
    _editing = LibrarianScope.read(context).repository.bookById(widget.bookId!);
    final book = _editing;
    if (book == null) return;
    _title.text = book.title;
    _author.text = book.author;
    _isbn.text = book.isbn;
    _category.text = book.category;
    _language.text = book.language;
    _copies.text = '${book.totalCopies}';
    _shelf.text = book.shelfLocation;
    _description.text = book.description;
  }

  @override
  void dispose() {
    for (final controller in [
      _title, _author, _isbn, _category, _language, _copies, _shelf, _description,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = LibrarianScope.read(context).repository;
    final title = _title.text.trim();
    final copies = int.parse(_copies.text.trim());

    final ActionResult result;
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
      );
    }
    if (!mounted) return;

    if (result.success) {
      context.go(
        LibrarianRoutes.books,
        extra: _isEdit
            ? '"$title" was updated.'
            : '"$title" added to the catalogue.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Center(
                child: BookCover(title: _title.text.trim(), width: 96, height: 128),
              ),
              const SizedBox(height: LibrarianSpacing.md),
              const Text(
                'Cover preview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LibrarianColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LibrarianSpacing.xs),
              const Text(
                'A cover is generated from the title. Uploading a JPG or PNG '
                'cover will be available once cloud storage is connected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: LibrarianColors.secondaryText),
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
                      validator: (v) =>
                          LibrarianValidators.positiveCount(v, 'Total copies'),
                    ),
                  ),
                  const SizedBox(width: LibrarianSpacing.md),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Shelf-Location',
                      controller: _shelf,
                      hint: 'CS-14-B',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          LibrarianValidators.required(v, 'Shelf location'),
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
          ),
        ],
      ),
    );
  }
}
