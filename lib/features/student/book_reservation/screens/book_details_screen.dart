import '../../common/widgets/favorite_button.dart';
import '../../common/widgets/student_palette.dart';
import 'my_reservations_screen.dart';
import 'find_books_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import 'package:flutter/material.dart';

import '../../../../models/book.dart';
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_book_cover.dart';
import 'reserve_book_screen.dart';

/// Details of one catalogue book, read live from Firestore (via the shared
/// library repository), so a librarian's changes show up immediately.
class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({
    super.key,
    required this.library,
    required this.bookId,
  });

  final StudentLibraryRepository library;
  final String bookId;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {


  /// The book as currently saved (updated by the ListenableBuilder in build).
  late BookRecord _book;

  String get title => _book.title;
  String get author => _book.author;
  String get category => _book.category;
  bool get available => _book.isAvailable;
  String get description =>
      _book.description.isEmpty ? 'No description has been added yet.' : _book.description;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.library,
      builder: (context, _) {
        final book = widget.library.bookById(widget.bookId);
        if (book == null) return _buildMissingBook();
        _book = book;
        return _buildDetails();
      },
    );
  }

  /// The book was deleted by a librarian (or has not loaded).
  Widget _buildMissingBook() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: widget.library.isLoading
                    ? CircularProgressIndicator()
                    : Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'This book is no longer in the catalogue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  children: [
                    _buildBookCover(),
                    SizedBox(height: 20),
                    _buildBookTitle(),
                    SizedBox(height: 8),
                    _buildCategoryAndAvailability(),
                    SizedBox(height: 28),
                    _buildBookInformation(),
                    SizedBox(height: 20),
                    _buildDescription(),
                    SizedBox(height: 26),
                    _buildReserveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                'Book Details',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          FavoriteButton(library: widget.library, itemId: widget.bookId),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: StudentPalette.of(context).border,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          size: 19,
        ),
      ),
    );
  }

  Widget _buildBookCover() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Center(
        child: StudentBookCover(
          title: title,
          author: author,
          imageUrl: _book.coverAsset,
          width: 158,
          height: 218,
          radius: 11,
        ),
      ),
    );
  }

  Widget _buildBookTitle() {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'by $author',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAndAvailability() {
    // Wraps onto two lines when the category name is long.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            category,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: available ? StudentPalette.of(context).successTint : StudentPalette.of(context).errorTint,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            available
                ? '${_book.availableCopies} of ${_book.totalCopies} available'
                : 'Unavailable',
            style: TextStyle(
              color: available
                  ? StudentPalette.of(context).success
                  : StudentPalette.of(context).error,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookInformation() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StudentPalette.of(context).gold,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              label: 'Language',
              value: _book.language,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildInfoItem(
              label: 'Shelf',
              value: _book.shelfLocation,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildInfoItem(
              label: 'ISBN',
              value: _book.isbn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: StudentPalette.of(context).muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 38,
      color: StudentPalette.of(context).border,
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: StudentPalette.of(context).muted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildReserveButton() {
    // Deleted / unavailable books and books already reserved by this
    // student are not offered for a new reservation.
    final blocker = widget.library.bookReservationBlocker(_book);
    return Column(
      children: [
        if (blocker != null)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              blocker,
              textAlign: TextAlign.center,
              style: TextStyle(color: StudentPalette.of(context).error, fontSize: 13),
            ),
          ),
        _buildReserveButtonBox(enabled: blocker == null),
      ],
    );
  }

  Widget _buildReserveButtonBox({required bool enabled}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReserveBookScreen(
                      library: widget.library,
                      bookId: _book.id,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: StudentPalette.of(context).primary,
          disabledBackgroundColor: StudentPalette.of(context).border,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Reserve Book',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return StudentBottomNavigation(
      selectedIndex: 1,
      onHome: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      onSearch: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FindBooksScreen(library: widget.library)));
      },
      onReservations: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MyReservationsScreen(library: widget.library)));
      },
      onProfile: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileScreen(library: widget.library)));
      },
    );
  }


}