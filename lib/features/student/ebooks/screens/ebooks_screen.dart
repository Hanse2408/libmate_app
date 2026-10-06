import 'package:flutter/material.dart';

import '../../../../models/ebook.dart';
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_book_cover.dart';
import '../widgets/ebook_ui.dart';
import 'ebook_details_screen.dart';

/// E-books (Find Books → eBooks): the published e-books librarians added, live
/// from the shared `ebooks` collection, with search by title, author or
/// category. Shows an empty state while none have been published.
class EbooksScreen extends StatefulWidget {
  const EbooksScreen({super.key, required this.library, this.initialQuery = ''});

  final StudentLibraryRepository library;

  /// Search text carried over from Find Books.
  final String initialQuery;

  @override
  State<EbooksScreen> createState() => _EbooksScreenState();
}

class _EbooksScreenState extends State<EbooksScreen> {
  late final TextEditingController _search = TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    widget.library.ebooks.search(widget.initialQuery);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.library.ebooks;
    final c = EbookColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            final results = provider.visibleEbooks;
            return Column(
              children: [
                const EbookPageHeader(title: 'E-books', subtitle: 'Your library, wherever you are.'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _SearchBar(controller: _search, onChanged: provider.search),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Available e-books',
                              style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (!provider.isLoading && provider.loadError == null)
                            Text(
                              '${results.length} e-book${results.length == 1 ? '' : 's'}',
                              style: TextStyle(color: c.muted, fontSize: 13),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (provider.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (provider.loadError != null)
                        _Message(
                          icon: Icons.cloud_off_rounded,
                          title: 'E-books could not be loaded',
                          message: provider.loadError!,
                          isError: true,
                        )
                      else if (provider.ebooks.isEmpty)
                        const _Message(
                          icon: Icons.menu_book_outlined,
                          title: 'No e-books available yet',
                          message: 'E-books added by the library will appear here.',
                        )
                      else if (results.isEmpty)
                        _Message(
                          icon: Icons.search_off_rounded,
                          title: 'No e-books found',
                          message: 'Nothing matches "${provider.query.trim()}". Try a title, author or category.',
                        )
                      else
                        for (final ebook in results) ...[
                          _EbookCard(
                            key: ValueKey('student-ebook-${ebook.id}'),
                            ebook: ebook,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EbookDetailsScreen(library: widget.library, ebookId: ebook.id),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c.border),
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: c.text),
        decoration: InputDecoration(
          hintText: 'Search e-books by title, author or category',
          hintStyle: TextStyle(color: c.muted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: c.muted),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close_rounded, color: c.muted),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: c.surface,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(borderSide: BorderSide(color: c.primary, width: 1.5)),
        ),
      ),
    );
  }
}

class _EbookCard extends StatelessWidget {
  const _EbookCard({super.key, required this.ebook, required this.onTap});

  final EbookRecord ebook;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    final size = EbookRecord.formatSize(ebook.pdfSizeBytes);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentBookCover(
                title: ebook.title,
                author: ebook.author,
                imageUrl: ebook.coverAsset, // an assets/images/books/ path
                width: 82,
                height: 112,
                radius: 12,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ebook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ebook.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: 13),
                    ),
                    if (ebook.publisher.isNotEmpty)
                      Text(
                        ebook.publisher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: 12),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const EbookBadge(),
                        Text(
                          ebook.category,
                          style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          ebook.hasPdf ? Icons.picture_as_pdf_outlined : Icons.block_rounded,
                          size: 15,
                          color: ebook.hasPdf ? c.success : c.error,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            ebook.hasPdf ? 'PDF${size.isEmpty ? '' : ' · $size'}' : 'PDF unavailable',
                            style: TextStyle(
                              color: ebook.hasPdf ? c.success : c.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty / no-results / error box in the Student card style.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.message, this.isError = false});

  final IconData icon;
  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final c = EbookColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
            child: Icon(icon, color: isError ? c.error : c.primary, size: 32),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
