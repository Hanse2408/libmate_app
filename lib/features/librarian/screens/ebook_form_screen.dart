import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../providers/librarian_scope.dart';
import '../widgets/ebook_form.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';

/// Add E-book page, or Edit E-book with an [ebookId] (form pre-filled with
/// the saved details, cover and PDF). Returns to E-book Management on save.
class EbookFormScreen extends StatelessWidget {
  const EbookFormScreen({super.key, this.ebookId});

  final String? ebookId;

  bool get _isEdit => ebookId != null;

  @override
  Widget build(BuildContext context) {
    final provider = LibrarianScope.of(context).ebooks();
    final header = LibrarianPageHeader(
      title: _isEdit ? 'Edit E-book' : 'Add New E-book',
      subtitle: _isEdit
          ? 'Update this e-book and its PDF'
          : 'Add a digital book to the catalogue',
      onBack: () => context.go(LibrarianRoutes.ebooks),
    );
    void done(String message) => context.go(LibrarianRoutes.ebooks, extra: message);

    if (!_isEdit) {
      return LibrarianPage(maxWidth: 760, children: [header, EbookForm(onSaved: done)]);
    }

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final ebook = provider.ebookById(ebookId!);
        return LibrarianPage(
          maxWidth: 760,
          children: [
            header,
            if (ebook != null)
              // Keyed by id so the form is filled once with this e-book.
              EbookForm(key: ValueKey('edit-${ebook.id}'), initial: ebook, onSaved: done)
            else if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              const LibrarianEmptyState(
                icon: Icons.search_off,
                title: 'E-book not found',
                message: 'It may have been deleted.',
              ),
          ],
        );
      },
    );
  }
}
