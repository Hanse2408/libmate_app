import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/librarian_theme.dart';
import 'book_cover.dart';

/// Cover images bundled with the app: the files in the project's
/// assets/images/books/ folder (declared in pubspec.yaml).
///
/// A running app (web / Android) cannot add files to the project folder, so
/// new covers are added by copying the image into assets/images/books/ and
/// restarting the app; it then appears in the cover picker.
class BookCoverAssets {
  const BookCoverAssets._();

  static const String folder = 'assets/images/books/';
  static const List<String> _extensions = ['.jpg', '.jpeg', '.png', '.webp'];

  /// Lists the cover images. Replaceable in widget tests.
  static Future<List<String>> Function() list = _fromAssetManifest;

  static Future<List<String>> _fromAssetManifest() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith(folder) &&
              _extensions.any((ext) => path.toLowerCase().endsWith(ext)),
        )
        .toList()
      ..sort();
  }
}

/// "Cover preview" card of the Add / Edit Book form: shows the chosen cover
/// (or the generated one) and lets the librarian choose a bundled image.
class BookCoverAssetField extends StatelessWidget {
  const BookCoverAssetField({
    super.key,
    required this.title,
    required this.coverAsset,
    required this.onChanged,
    this.enabled = true,
  });

  /// Book title, used for the generated cover.
  final String title;

  /// Chosen cover path, e.g. "assets/images/books/book1.jpg", or null.
  final String? coverAsset;

  /// Called with the new path, or null when the cover is removed.
  final ValueChanged<String?> onChanged;
  final bool enabled;

  Future<void> _choose(BuildContext context) async {
    final chosen = await showBookCoverPicker(context, selected: coverAsset);
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BookCover(
            title: title,
            coverAsset: coverAsset,
            width: 96,
            height: 128,
          ),
        ),
        const SizedBox(height: LibrarianSpacing.md),
        Text(
          'Cover preview',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LibrarianColors.text,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LibrarianSpacing.xs),
        Text(
          coverAsset ??
              'Choose a cover from assets/images/books/. Without one, a cover '
                  'is generated from the title.',
          textAlign: TextAlign.center,
          style: TextStyle(color: LibrarianColors.secondaryText),
        ),
        const SizedBox(height: LibrarianSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: LibrarianSpacing.sm,
          runSpacing: LibrarianSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: enabled ? () => _choose(context) : null,
              icon: const Icon(Icons.image_outlined),
              label: Text(coverAsset == null ? 'Choose Cover' : 'Change Cover'),
            ),
            if (coverAsset != null)
              TextButton.icon(
                onPressed: enabled ? () => onChanged(null) : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove Cover'),
                style: TextButton.styleFrom(
                  foregroundColor: LibrarianColors.unavailable,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Opens the cover grid (images in assets/images/books/) and returns the
/// chosen path, or null if cancelled. Used by the Book and E-book forms.
Future<String?> showBookCoverPicker(BuildContext context, {String? selected}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CoverPickerDialog(selected: selected),
  );
}

/// Grid of the bundled cover images; pops with the chosen path.
class _CoverPickerDialog extends StatelessWidget {
  const _CoverPickerDialog({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a cover'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<String>>(
          future: BookCoverAssets.list(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final covers = snapshot.data ?? const <String>[];
            if (snapshot.hasError || covers.isEmpty) {
              return Text(
                'No cover images found in assets/images/books/.\n\n'
                'To add one, copy a JPG, PNG or WebP image into the project '
                'folder assets/images/books/ (use a unique name, e.g. '
                'book_new_01.jpg), then restart the app.',
                style: TextStyle(color: LibrarianColors.secondaryText),
              );
            }
            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: LibrarianSpacing.sm,
              crossAxisSpacing: LibrarianSpacing.sm,
              childAspectRatio: 0.62,
              children: [
                for (final path in covers)
                  _CoverOption(
                    path: path,
                    isSelected: path == selected,
                    onTap: () => Navigator.of(context).pop(path),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _CoverOption extends StatelessWidget {
  const _CoverOption({
    required this.path,
    required this.isSelected,
    required this.onTap,
  });

  final String path;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = path.substring(path.lastIndexOf('/') + 1);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? LibrarianColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      ColoredBox(color: LibrarianColors.lightBlue),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: LibrarianColors.text),
            ),
          ],
        ),
      ),
    );
  }
}
