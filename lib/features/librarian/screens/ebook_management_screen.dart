import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';
import '../../../models/ebook.dart';
import '../providers/ebook_provider.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/ebook_pdf_sheet.dart';
import '../widgets/ebook_tile.dart';
import '../widgets/librarian_empty_state.dart';
import '../widgets/librarian_message_banner.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/librarian_search_field.dart';

/// E-book Management (Figma): Add New E-book, published count, search and
/// the e-book list with Edit / PDF / Delete. Adding opens the Add E-book page.
class EbookManagementScreen extends StatefulWidget {
  const EbookManagementScreen({super.key, this.message});

  /// Success message to show on arrival, e.g. after editing an e-book.
  final String? message;

  @override
  State<EbookManagementScreen> createState() => _EbookManagementScreenState();
}

class _EbookManagementScreenState extends State<EbookManagementScreen> {
  late String? _message = widget.message;

  @override
  void didUpdateWidget(EbookManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != null && widget.message != oldWidget.message) {
      _message = widget.message;
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _delete(EbookProvider provider, EbookRecord ebook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this e-book?'),
        content: Text(
          '"${ebook.title}"${ebook.hasPdf ? ' and its PDF' : ''} will be removed. '
          'This cannot be undone.',
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
    final result = await provider.delete(ebook);
    if (!mounted) return;
    if (result.success) {
      setState(() => _message = '"${ebook.title}" was deleted.');
    } else {
      _snack(result.message!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = LibrarianScope.of(context).ebooks();

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final results = provider.visibleEbooks;
        return LibrarianPage(
          children: [
            const LibrarianPageHeader(
              title: 'E-book Management',
              subtitle: 'Manage and publish your digital catalogue.',
            ),
            FilledButton.icon(
              onPressed: () => context.go(LibrarianRoutes.addEbook),
              icon: const Icon(Icons.add),
              label: const Text('Add New E-book'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LibrarianSpacing.radius + 4),
                ),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: LibrarianSpacing.md + 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Manage e-books',
                    style: TextStyle(color: LibrarianColors.text, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${provider.publishedCount} published',
                  style: TextStyle(color: LibrarianColors.secondaryText, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: LibrarianSpacing.sm),
            if (_message != null)
              LibrarianMessageBanner(
                message: _message!,
                onClose: () => setState(() => _message = null),
              ),
            LibrarianSearchField(
              hint: 'Search title, author or ISBN',
              onChanged: provider.search,
            ),
            const SizedBox(height: LibrarianSpacing.md),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: LibrarianSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.loadError != null)
              LibrarianEmptyState(
                icon: Icons.cloud_off,
                title: 'E-books could not be loaded',
                message: provider.loadError!,
              )
            else if (provider.ebooks.isEmpty)
              const LibrarianEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No e-books yet',
                message: 'Use "Add New E-book" to add the first e-book.',
              )
            else if (results.isEmpty)
              LibrarianEmptyState(
                icon: Icons.search_off,
                title: 'No results for "${provider.query.trim()}"',
                message: 'Try a different title, author or ISBN.',
              )
            else
              for (final ebook in results)
                EbookTile(
                  key: ValueKey('ebook-${ebook.id}'),
                  ebook: ebook,
                  onEdit: () => context.go(LibrarianRoutes.editEbook(ebook.id)),
                  onPdf: () => showEbookPdfSheet(context, provider: provider, ebookId: ebook.id),
                  onDelete: () => _delete(provider, ebook),
                ),
          ],
        );
      },
    );
  }
}
