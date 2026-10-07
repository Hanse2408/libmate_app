import 'package:flutter/material.dart';
import '../data/student_library_repository.dart';
import '../../book_reservation/widgets/reservation_notice.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.library, required this.itemId, this.ebook = false});
  final StudentLibraryRepository library;
  final String itemId;
  final bool ebook;
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.library,
    builder: (context, _) {
      final selected = widget.library.isFavorite(widget.itemId, ebook: widget.ebook);
      final colors = Theme.of(context).colorScheme;
      return IconButton(
        tooltip: selected ? 'Remove from favourites' : 'Add to favourites',
        style: IconButton.styleFrom(backgroundColor: colors.primary.withValues(alpha: 0.10)),
        onPressed: _saving ? null : () async {
          setState(() => _saving = true);
          final result = await widget.library.setFavorite(widget.itemId, favorite: !selected, ebook: widget.ebook);
          if (!mounted || !context.mounted) return;
          setState(() => _saving = false);
          if (!result.success) {
            showReservationNotice(context, title: 'Could not update favourites', message: result.message ?? 'Please try again.');
          }
        },
        icon: _saving
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(selected ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: colors.primary),
      );
    },
  );
}