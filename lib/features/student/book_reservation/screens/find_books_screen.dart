import 'favorite_books_screen.dart';
import '../../common/widgets/student_palette.dart';
import 'my_reservations_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/stored_image.dart';
import '../../common/data/student_library_repository.dart';
import '../../ebooks/screens/ebooks_screen.dart';
import 'book_details_screen.dart';

/// Browse and search the library catalogue. The list is the same Firestore
/// `books` collection the Librarian manages, so new books appear live.

class FindBooksScreen extends StatefulWidget {
  const FindBooksScreen({super.key, required this.library});

  final StudentLibraryRepository library;

  @override
  State<FindBooksScreen> createState() => _FindBooksScreenState();
}

class _FindBooksScreenState extends State<FindBooksScreen> {

  final TextEditingController _searchController = TextEditingController();


  String _selectedCategory = 'All';

  /// The "eBooks" category opens the E-books page (digital books from the
  /// `ebooks` collection) instead of filtering the printed books.
  static const String ebooksCategory = 'eBooks';

  /// "All", the categories of the books in the catalogue, and "eBooks".
  List<String> get _categories => widget.library.catalogueCategories;

  void _selectCategory(String category) {
    if (category == ebooksCategory) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EbooksScreen(
            library: widget.library,
            initialQuery: _searchController.text,
          ),
        ),
      );
      return;
    }
    setState(() {
      _selectedCategory = category;
    });
  }


  /// The books librarians have saved in Firestore (updates live).
  List<Book> get _books {
    return [
      for (final record in widget.library.books)
        Book(
          id: record.id,
          title: record.title,
          author: record.author,
          category: record.category,
          available: record.isAvailable,
          description: record.description,
          color: _coverColors[record.title.length % _coverColors.length],
          coverImageUrl: record.coverAsset,
        ),
    ];
  }

  static const List<Color> _coverColors = [
    Color(0xFF2563EB),
    Color(0xFF1E3A8A),
    Color(0xFF64748B),
    Color(0xFFF2B84B),
  ];


    List<Book> get _filteredBooks {
  final searchText = _searchController.text.toLowerCase().trim();

  return _books.where((book) {
    final matchesCategory =
        _selectedCategory == 'All' ||
        book.category == _selectedCategory;

    final matchesSearch =
        searchText.isEmpty ||
        book.title.toLowerCase().contains(searchText) ||
        book.author.toLowerCase().contains(searchText) ||
        book.category.toLowerCase().contains(searchText);

    return matchesCategory && matchesSearch;
  }).toList();
}

@override
void initState() {
  super.initState();
  _searchController.addListener(_onSearchChanged);
}

  void _onSearchChanged() {
    setState(() {});
  }

 @override
void dispose() {
  _searchController
    ..removeListener(_onSearchChanged)
    ..dispose();

  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.library,
          builder: (context, _) => _buildBody(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    SizedBox(height: 24),
                    _buildCategories(),
                    SizedBox(height: 24),
                    _buildBookSection(),
                  ],
                ),
              ),
            ),
          ],
        );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: StudentPalette.of(context).text,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Find Books',
              style: TextStyle(
                color: StudentPalette.of(context).text,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: StudentPalette.of(context).blueTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: 'My Favourites',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => FavoriteBooksScreen(library: widget.library),
              )),
              icon: Icon(Icons.favorite_rounded, color: StudentPalette.of(context).primary, size: 23),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: StudentPalette.of(context).card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books, authors...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _searchController.clear,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 4,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: StudentPalette.of(context).primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.tune_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

 Widget _buildCategories() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Categories',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 14),
      SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 10),        
        itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;

            return GestureDetector(
              onTap: () => _selectCategory(category),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
  Widget _buildBookSection() {
    final books = _filteredBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Books',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${books.length} books',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        if (widget.library.isLoading && books.isEmpty)
          Center(child: CircularProgressIndicator())
        else if (books.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: books.length,
            separatorBuilder: (_, _) => SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _buildBookCard(books[index]);
            },
          ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookDetailsScreen(library: widget.library, bookId: book.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookCover(book),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      // Long category names are shortened instead of overflowing.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: StudentPalette.of(context).blueTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              book.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: StudentPalette.of(context).primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: book.available
                                  ? StudentPalette.of(context).success
                                  : StudentPalette.of(context).error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            book.available ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: book.available
                                  ? StudentPalette.of(context).success
                                  : StudentPalette.of(context).error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBookCover(Book book) {
    // The librarian's uploaded cover, or the generated one.
    final generated = _buildGeneratedCover(book);
    if (book.coverImageUrl == null) return generated;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 82,
        height: 112,
        child: StoredImage(url: book.coverImageUrl, fallback: generated),
      ),
    );
  }

  Widget _buildGeneratedCover(Book book) {
    return Container(
      width: 82,
      height: 112,
      decoration: BoxDecoration(
        color: book.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: book.color.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

        ),
      
    ),
   
  );
}

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: StudentPalette.of(context).card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: StudentPalette.of(context).border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: StudentPalette.of(context).muted,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No books found',
            style: TextStyle(
              color: StudentPalette.of(context).text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StudentPalette.of(context).muted,
              fontSize: 13,
            ),
          ),
        ],
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
        // Already on Search.
      },
      onReservations: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MyReservationsScreen(library: widget.library)));
      },
      onProfile: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileScreen(library: widget.library)));
      },
    );
  }



  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StudentPalette.of(context).card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: StudentPalette.of(context).border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Filter Books',
                style: TextStyle(
                  color: StudentPalette.of(context).text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 18),
              ..._categories.map(
                (category) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    category,
                    style: TextStyle(
                      color: StudentPalette.of(context).text,
                    ),
                  ),
                  trailing: category == _selectedCategory
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: StudentPalette.of(context).primary,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: StudentPalette.of(context).border,
                        ),
                  onTap: () {
                    Navigator.pop(context);
                    _selectCategory(category);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.available,
    required this.description,
    required this.color,
    this.coverImageUrl,
  });

  final String id;
  final String? coverImageUrl;

  final String title;
  final String author;
  final String category;
  final bool available;
  final String description;
  final Color color;
}

