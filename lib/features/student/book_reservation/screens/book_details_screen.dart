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
  bool _isFavorite = false;

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
                    ? const CircularProgressIndicator()
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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  children: [
                    _buildBookCover(),
                    const SizedBox(height: 20),
                    _buildBookTitle(),
                    const SizedBox(height: 8),
                    _buildCategoryAndAvailability(),
                    const SizedBox(height: 28),
                    _buildBookInformation(),
                    const SizedBox(height: 20),
                    _buildDescription(),
                    const SizedBox(height: 26),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
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
          _buildCircleButton(
            icon: _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: _isFavorite
                ? const Color(0xFFDC4C4C)
                : const Color(0xFF2563EB),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
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
          color: const Color(0xFFE2E8F0),
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
        const SizedBox(height: 5),
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
          padding: const EdgeInsets.symmetric(
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
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: available ? const Color(0xFFDDF7EB) : const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            available
                ? '${_book.availableCopies} of ${_book.totalCopies} available'
                : 'Unavailable',
            style: TextStyle(
              color: available
                  ? const Color(0xFF22A06B)
                  : const Color(0xFFDC4C4C),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF2B84B),
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
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF475569),
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
      color: const Color(0xFFE2E8F0),
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
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: Color(0xFF475569),
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              blocker,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDC4C4C), fontSize: 13),
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
          backgroundColor: const Color(0xFF2563EB),
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: false,
              ),
              _buildNavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                selected: true,
              ),
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Reservations',
                selected: false,
              ),
              _buildNavItem(
                icon: Icons.account_circle_outlined,
                label: 'Profile',
                selected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}