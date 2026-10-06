import 'package:flutter/material.dart';
import 'modify_book_reservation_screen.dart';
import '../../../../models/reservation.dart' as shared;
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_book_cover.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import '../../common/screens/profile_screen.dart';
import 'find_books_screen.dart';

/// The student's own book and seat reservations, read live from Firestore.
/// A librarian's approval or rejection appears here straight away.
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({
    super.key,
    required this.library,
    this.showSeats = false,
  });

  final StudentLibraryRepository library;

  /// Open on the Seats tab instead of Books.
  final bool showSeats;

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  late bool _showSeats = widget.showSeats;
  String? _cancellingId;

  /// The student's reservations of the selected type, as display cards.
  List<BookReservation> get _reservations {
    final type = _showSeats ? shared.ReservationType.seat : shared.ReservationType.book;
    return [
      for (final r in widget.library.myReservations)
        if (r.type == type) _toCard(r),
    ];
  }

  BookReservation _toCard(shared.ReservationRecord r) {
    final book = r.type == shared.ReservationType.book
        ? widget.library.bookById(r.itemId)
        : null;
    final (label, type) = switch (r.status) {
      shared.ReservationStatus.pending => ('Pending', ReservationStatus.pending),
      shared.ReservationStatus.approved => r.type == shared.ReservationType.book
          ? ('Ready for Pickup', ReservationStatus.ready)
          : ('Confirmed', ReservationStatus.ready),
      shared.ReservationStatus.completed =>
        r.type == shared.ReservationType.book
            ? ('Collected', ReservationStatus.reserved)
            : ('Completed', ReservationStatus.reserved),
      shared.ReservationStatus.rejected => ('Rejected', ReservationStatus.closed),
      shared.ReservationStatus.cancelled => ('Cancelled', ReservationStatus.closed),
    };
    final date = _formatDate(r.date);
    final dateLabel = switch (r.status) {
      shared.ReservationStatus.rejected => r.rejectionReason ?? 'Rejected by the library',
      _ when r.type == shared.ReservationType.seat => '$date • ${r.timeSlot ?? ''}',
      shared.ReservationStatus.approved => 'Collect from $date',
      _ => 'Pickup date: $date',
    };
    return BookReservation(
      id: r.id,
      title: r.itemName,
      author: r.type == shared.ReservationType.book
          ? (book?.author ?? '')
          : 'Reading Room',
      status: label,
      statusType: type,
      dateLabel: dateLabel,
      coverImageUrl: book?.coverAsset,
      isSeat: r.type == shared.ReservationType.seat,
      canCancel: r.isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildToggle(),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.library,
                builder: (context, _) => _buildReservationList(),
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
          _buildBackButton(),
          const Expanded(
            child: Center(
              child: Text(
                'My Reservations',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: () {
          Navigator.of(context).maybePop();
        },
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF17356D),
          size: 21,
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFD5E2F4),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: _buildToggleOption('Books', selected: !_showSeats)),
            Expanded(child: _buildToggleOption('Seats', selected: _showSeats)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, {required bool selected}) {
    return InkWell(
      onTap: () => setState(() => _showSeats = label == 'Seats'),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFBFD6F7),
                borderRadius: BorderRadius.circular(13),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1267D9) : const Color(0xFF17356D),
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReservationList() {
    final reservations = _reservations;
    if (widget.library.isLoading && reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.library.loadError ??
                (_showSeats
                    ? 'You have no seat bookings yet.'
                    : 'You have no book reservations yet.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildReservationCard(reservations[index]);
      },
    );
  }

  Widget _buildReservationCard(BookReservation reservation) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFD6E3F2),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookCover(reservation),
              const SizedBox(width: 13),
              Expanded(
                child: _buildBookInformation(reservation),
              ),
              const SizedBox(width: 5),
              _buildStatusBadge(reservation),
            ],
          ),
          const SizedBox(height: 7),
          const Divider(
            height: 1,
            color: Color(0xFFE6ECF3),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Modify',
                  backgroundColor: const Color(0xFFEAF3FF),
                  textColor: const Color(0xFF1267D9),
                  onPressed: reservation.canCancel
    ? () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ModifyBookReservationScreen(
              library: widget.library,
              reservationId: reservation.id,
            ),
          ),
        );
      }
    : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildActionButton(
                  label: _cancellingId == reservation.id ? 'Cancelling…' : 'Cancel',
                  backgroundColor: const Color(0xFFFFE6E6),
                  textColor: const Color(0xFFE53935),
                  onPressed: reservation.canCancel && _cancellingId == null
                      ? () => _confirmCancellation(reservation)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookInformation(BookReservation reservation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reservation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF17356D),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          reservation.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF536987),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF164B99),
              size: 21,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                reservation.dateLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF536987),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BookReservation reservation) {
    final (backgroundColor, textColor) = switch (reservation.statusType) {
      ReservationStatus.reserved => (const Color(0xFFEAF3FF), const Color(0xFF1267D9)),
      ReservationStatus.ready => (const Color(0xFFDDF6E6), const Color(0xFF159447)),
      ReservationStatus.pending => (const Color(0xFFFFEEDB), const Color(0xFFE78A00)),
      ReservationStatus.closed => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        reservation.status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBookCover(BookReservation reservation) {
    if (reservation.isSeat) {
      return Container(
        width: 68,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D8),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(
          Icons.event_seat_rounded,
          color: Color(0xFFFFA500),
          size: 32,
        ),
      );
    }
    return StudentBookCover(
      title: reservation.title,
      author: reservation.author,
      imageUrl: reservation.coverImageUrl,
      width: 68,
      height: 76,
      color: const Color(0xFF111B2D),
      radius: 7,
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: enabled ? backgroundColor : const Color(0xFFF1F5F9),
          foregroundColor: textColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? textColor : const Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  

  void _confirmCancellation(BookReservation reservation) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Cancel Reservation?',
            style: TextStyle(
              color: Color(0xFF172033),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your reservation for '
            '${reservation.title}?',
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Keep',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _cancel(reservation);
              },
              child: const Text(
                'Cancel Reservation',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Cancels in Firestore; the message reflects the real result.
  Future<void> _cancel(BookReservation reservation) async {
    setState(() => _cancellingId = reservation.id);
    final result = await widget.library.cancelReservation(reservation.id);
    if (!mounted) return;
    setState(() => _cancellingId = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '${reservation.title} reservation cancelled.'
                : result.message!,
          ),
        ),
      );
  }

 Widget _buildBottomNavigationBar() {
  return StudentBottomNavigation(
    selectedIndex: 2,
    onHome: () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    },
    onSearch: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FindBooksScreen(
            library: widget.library,
          ),
        ),
      );
    },
    onReservations: () {
      // Already on Reservations.
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

 

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Badge colour group used on the reservation cards.
enum ReservationStatus {
  reserved,
  ready,
  pending,

  /// Rejected or cancelled.
  closed,
}

/// What one reservation card shows.
class BookReservation {
  const BookReservation({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.statusType,
    required this.dateLabel,
    this.coverImageUrl,
    this.isSeat = false,
    this.canCancel = false,
  });

  final String id;
  final String title;
  final String author;
  final String status;
  final ReservationStatus statusType;
  final String dateLabel;
  final String? coverImageUrl;
  final bool isSeat;
  final bool canCancel;
}
