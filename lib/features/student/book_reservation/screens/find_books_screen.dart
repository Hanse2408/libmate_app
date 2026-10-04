import 'package:flutter/material.dart';

import '../../../../models/book.dart';
import '../providers/book_provider.dart';

class FindBooksScreen extends StatefulWidget {
  const FindBooksScreen({super.key});

  @override
  State<FindBooksScreen> createState() => _FindBooksScreenState();
}

class _FindBooksScreenState extends State<FindBooksScreen> {
  final BookProvider _bookProvider = BookProvider();
  final TextEditingController _searchController = TextEditingController();

  void _onProviderChanged() {
  if (mounted) {
    setState(() {});
  }
}

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Programming',
    'Self-Help',
    'Psychology',
    'Business',
    'Fiction',
  ];


    List<Book> get _filteredBooks {
    final searchText = _searchController.text.toLowerCase().trim();

    return _bookProvider.books.where((book) {
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
  _bookProvider.addListener(_onProviderChanged);
  _bookProvider.loadBooks();
}

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    _bookProvider.removeListener(_onProviderChanged);
    _bookProvider.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
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
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
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
        if (books.isEmpty)
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
        _showBookDetails(book);
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
                      Container(
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
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
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
  return Container(
    width: 82,
    height: 112,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        book.coverAsset,
        width: 82,
        height: 112,
        fit: BoxFit.cover,
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
          height: 70,
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
                icon: Icons.bookmark_border_rounded,
                label: 'Reservations',
                selected: false,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
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
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
              size: 23,
            ),
            const SizedBox(height: 4),
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
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookDetails(Book book) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              _buildBookCover(book),
              const SizedBox(height: 18),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                book.author,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                book.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: book.available
                      ? const Color(0xFFEAF8F1)
                      : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  book.available ? 'Available for reservation' : 'Currently unavailable',
                  style: TextStyle(
                    color: book.available
                        ? const Color(0xFF22A06B)
                        : const Color(0xFFDC4C4C),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

