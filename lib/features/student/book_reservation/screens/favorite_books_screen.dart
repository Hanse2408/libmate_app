import 'package:flutter/material.dart';
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/favorite_button.dart';
import '../../common/widgets/student_book_cover.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import '../../common/widgets/student_palette.dart';
import '../../common/screens/profile_screen.dart';
import '../../ebooks/screens/ebook_details_screen.dart';
import 'book_details_screen.dart';
import 'find_books_screen.dart';
import 'my_reservations_screen.dart';
import 'reserve_book_screen.dart';

class FavoriteBooksScreen extends StatefulWidget {
  const FavoriteBooksScreen({super.key, required this.library});
  final StudentLibraryRepository library;
  @override
  State<FavoriteBooksScreen> createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  String _category = 'All';
  String _query = '';
  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final library = widget.library;
    final ebooks = library.ebooks;
    final colors = StudentPalette.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: colors.text),
        ),
        title: Text('My Favourites', style: TextStyle(color: colors.text,
        fontSize: 24, letterSpacing: -.6, fontWeight: FontWeight.w800)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent, elevation: 0),
      body: ListenableBuilder(
        listenable: Listenable.merge([library, ebooks]),
        builder: (context, _) {
          final categories = library.catalogueCategories;
          final selected = categories.contains(_category) ? _category : 'All';
          final items = <({String id, String title, String author, String category, String? cover, bool ebook, String? blocker})>[
            for (final book in library.books)
              if (library.isFavorite(book.id))
                (id: book.id, title: book.title, author: book.author, category: book.category, cover: book.coverAsset, ebook: false, blocker: library.bookReservationBlocker(book)),
            for (final ebook in ebooks.ebooks)
              if (library.isFavorite(ebook.id, ebook: true))
                (id: ebook.id, title: ebook.title, author: ebook.author, category: ebook.category, cover: ebook.coverAsset, ebook: true, blocker: null),
          ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          final visible = items.where((item) =>
            (selected == 'All' || (selected == 'eBooks' ? item.ebook : !item.ebook && item.category == selected)) &&
            ('${item.title} ${item.author} ${item.category}'.toLowerCase().contains(_query.toLowerCase().trim()))).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search your favourites...',
                    filled: true, fillColor: colors.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: colors.primary.withValues(alpha: .22))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: colors.primary, width: 1.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.muted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  for (final category in categories) Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category), selected: selected == category,
                      selectedColor: colors.primary, backgroundColor: colors.card,
                      labelStyle: TextStyle(color: selected == category ? Colors.white : colors.muted, fontWeight: FontWeight.w700),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      side: BorderSide(color: selected == category ? colors.primary : colors.primary.withValues(alpha: .2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: library.isLoading || ebooks.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.favorite_border_rounded, size: 52, color: colors.favorite),
                          const SizedBox(height: 14),
                          Text(library.loadError ?? ebooks.loadError ?? (items.isEmpty
                            ? 'Your favourites belong here. Tap a book\'s heart to save it.'
                            : 'No favourites match this category or search.'), textAlign: TextAlign.center, style: TextStyle(color: colors.muted, fontSize: 12)),
                        ]),
                      ))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = visible[index];
                          void openDetails() => _open(item.ebook
                            ? EbookDetailsScreen(library: library, ebookId: item.id)
                            : BookDetailsScreen(library: library, bookId: item.id));
                          return Material(
                            color: colors.card,
                            elevation: 1,
                            shadowColor: colors.primary.withValues(alpha: .12),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: colors.favorite.withValues(alpha: colors.isDark ? .3 : .18))),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: openDetails,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  StudentBookCover(title: item.title, author: item.author, imageUrl: item.cover, width: 68, height: 96, fit: BoxFit.contain),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -.2)),
                                    const SizedBox(height: 5),
                                    Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.muted, fontSize: 12)),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: colors.blueTint, borderRadius: BorderRadius.circular(7)),
                                      child: Text(item.ebook ? 'eBooks · ${item.category}' : item.category,
                                        style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w700))),
                                    const SizedBox(height: 10),
                                    if (item.ebook)
                                      FilledButton.tonal(onPressed: openDetails,
                                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                                        child: const Text('Read Online'))
                                    else ...[
                                      FilledButton(
                                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                                        onPressed: item.blocker == null ? () => _open(ReserveBookScreen(library: library, bookId: item.id)) : null,
                                        child: const Text('Reserve Book'),
                                      ),
                                      if (item.blocker != null) Text(item.blocker!, style: TextStyle(color: colors.muted, fontSize: 12)),
                                    ],
                                  ])),
                                  FavoriteButton(library: library, itemId: item.id, ebook: item.ebook),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StudentBottomNavigation(
        selectedIndex: 1,
        onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
        onSearch: () => _open(FindBooksScreen(library: library)),
        onReservations: () => _open(MyReservationsScreen(library: library)),
        onProfile: () => _open(ProfileScreen(library: library)),
      ),
    );
  }
}