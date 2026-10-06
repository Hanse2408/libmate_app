import 'package:flutter/material.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import '../../../../core/widgets/stored_image.dart';
import '../../common/data/student_library_repository.dart';
import '../../ebooks/screens/ebooks_screen.dart';
import 'book_details_screen.dart';
import '../../common/screens/profile_screen.dart';
import 'my_reservations_screen.dart';

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
  List<String> get _categories {
    final categories = {
      for (final book in widget.library.books)
        if (book.category != ebooksCategory) book.category,
    }.toList()
      ..sort();
    return ['All', ...categories, ebooksCategory];
  }

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
      backgroundColor: const Color(0xFFF8FAFC),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildCategories(),
                    const SizedBox(height: 24),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Find Books',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF2563EB),
              size: 23,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books, authors...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
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
      const Text(
        'Categories',
        style: TextStyle(
          color: Color(0xFF172033),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),        
        itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;

            return GestureDetector(
              onTap: () => _selectCategory(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF64748B),
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
            const Expanded(
              child: Text(
                'Books',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${books.length} books',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (widget.library.isLoading && books.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (books.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookCover(book),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Long category names are shortened instead of overflowing.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              book.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: book.available
                                  ? const Color(0xFF22A06B)
                                  : const Color(0xFFDC4C4C),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            book.available ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: book.available
                                  ? const Color(0xFF22A06B)
                                  : const Color(0xFFDC4C4C),
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: Color(0xFF94A3B8),
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No books found',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
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
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MyReservationsScreen(
            library: widget.library,
          ),
        ),
      );
    },
    onProfile: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(library: widget.library),
        ),
      );
    },
  );
}
  
  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Filter Books',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ..._categories.map(
                (category) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    category,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                    ),
                  ),
                  trailing: category == _selectedCategory
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2563EB),
                        )
                      : const Icon(
                          Icons.circle_outlined,
                          color: Color(0xFFCBD5E1),
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
