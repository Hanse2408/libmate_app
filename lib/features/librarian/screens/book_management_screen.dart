import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../models/book_record.dart';
import '../providers/book_filter.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/filter_pill.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_message_banner.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/librarian_search_field.dart';

/// Book Management (Figma): Add New Book, feedback banner, search, filters
/// and the catalogue list.
class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key, this.message});

  /// Success message to show on arrival, e.g. after saving a book.
  final String? message;

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  late String? _message = widget.message;

  @override
  void didUpdateWidget(BookManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Returning from the add form reuses this page, so pick up the new message.
    if (widget.message != null && widget.message != oldWidget.message) {
      _message = widget.message;
    }
  }
  String _query = '';
  BookStock? _stock;
  String? _category;
  String? _author;

  static const List<BookStock?> _stockOptions = [null, ...BookStock.values];

  @override
  Widget build(BuildContext context) {
    final repository = LibrarianScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final books = repository.books;
        final results = BookFilter(
          query: _query,
          stock: _stock,
          category: _category,
          author: _author,
        ).apply(books);
        final categories = <String?>[null, ...BookFilter.categoriesOf(books)];
        final authors = <String?>[null, ...BookFilter.authorsOf(books)];

        return LibrarianPage(
          children: [
            const LibrarianPageHeader(
              title: 'Book Management',
              subtitle: 'Search, add and update the library catalogue.',
            ),
            FilledButton.icon(
              onPressed: () => context.go(LibrarianRoutes.addBook),
              icon: const Icon(Icons.add),
              label: const Text('Add New Book'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LibrarianSpacing.radius + 4),
                ),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: LibrarianSpacing.md + 4),
            if (_message != null)
              LibrarianMessageBanner(
                message: _message!,
                onClose: () => setState(() => _message = null),
              ),
            LibrarianSearchField(
              hint: 'Search title, author or ISBN',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: LibrarianSpacing.md),
            Wrap(
              spacing: LibrarianSpacing.sm,
              runSpacing: LibrarianSpacing.sm,
              children: [
                FilterPill(
                  label: 'Availability',
                  options: [for (final s in _stockOptions) s?.label ?? 'All'],
                  selectedIndex: _stockOptions.indexOf(_stock),
                  onSelected: (i) => setState(() => _stock = _stockOptions[i]),
                ),
                FilterPill(
                  label: 'Category',
                  options: [for (final c in categories) c ?? 'All'],
                  selectedIndex: categories.indexOf(_category).clamp(0, categories.length - 1),
                  onSelected: (i) => setState(() => _category = categories[i]),
                ),
                FilterPill(
                  label: 'Author',
                  options: [for (final a in authors) a ?? 'All'],
                  selectedIndex: authors.indexOf(_author).clamp(0, authors.length - 1),
                  onSelected: (i) => setState(() => _author = authors[i]),
                ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.lg),
            if (repository.isLoading && books.isEmpty)
              const _Loading(label: 'Loading books…')
            else if (repository.loadError != null && books.isEmpty)
              LibrarianEmptyState(
                icon: Icons.cloud_off,
                title: 'Books could not be loaded',
                message: repository.loadError!,
              )
            else if (results.isEmpty)
              _emptyState(hasBooks: books.isNotEmpty)
            else
              _BookList(books: results),
          ],
        );
      },
    );
  }

  Widget _emptyState({required bool hasBooks}) {
    if (!hasBooks) {
      return const LibrarianEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No books in the catalogue',
        message: 'Use "Add New Book" to add the first book.',
      );
    }
    return LibrarianEmptyState(
      icon: Icons.search_off,
      title: _query.trim().isEmpty
          ? 'No books match these filters'
          : 'No results for "${_query.trim()}"',
      message: 'Try a different title, author, ISBN or filter.',
    );
  }
}

/// One column on phones, two columns on wide screens.
class _BookList extends StatelessWidget {
  const _BookList({required this.books});

  final List<BookRecord> books;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = LibrarianSpacing.md;
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final book in books)
              SizedBox(
                width: width,
                child: BookListTile(
                  book: book,
                  onEdit: () => context.go(LibrarianRoutes.editBook(book.id)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LibrarianSpacing.lg),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: LibrarianSpacing.md),
          Text(label, style: const TextStyle(color: LibrarianColors.secondaryText)),
        ],
      ),
    );
  }
}
