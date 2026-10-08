import '../../common/widgets/student_palette.dart';
import 'reservation_details_screen.dart';
import '../widgets/reservation_notice.dart';
import 'find_books_screen.dart';
import '../../common/screens/profile_screen.dart';
import 'package:flutter/material.dart';

import '../../../../models/reservation.dart' as shared;
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_book_cover.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import 'modify_book_reservation_screen.dart';
import '../../seat_booking/screens/modify_seat_reservation_screen.dart';
import '../../seat_booking/screens/seat_reservation_details_screen.dart';
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
  shared.ReservationStatus? _bookFilter;
  shared.ReservationStatus? _seatFilter;

  shared.ReservationStatus? get _statusFilter => _showSeats ? _seatFilter : _bookFilter;

  /// The student's reservations of the selected type, as display cards.
  List<BookReservation> get _reservations {
    final type = _showSeats ? shared.ReservationType.seat : shared.ReservationType.book;
    return [
      for (final r in widget.library.myReservations)
        if (r.type == type && (_statusFilter == null || r.status == _statusFilter)) _toCard(r),
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
      shared.ReservationStatus.rejected => ('Rejected', ReservationStatus.rejected),
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
      canModify: r.type == shared.ReservationType.seat ? r.canModifySeat : r.isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildToggle(),
            _buildStatusFilters(),
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
      padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          _buildBackButton(),
          Expanded(
            child: Center(
              child: Text(
                'My Reservations',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 40),
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
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Theme.of(context).colorScheme.onSurface,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Container(
        height: 50,
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: StudentPalette.of(context).blueTint,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: StudentPalette.of(context).border,
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
                gradient: StudentPalette.of(context).actionGradient,
                boxShadow: StudentPalette.of(context).actionShadow,
                borderRadius: BorderRadius.circular(13),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : StudentPalette.of(context).muted,
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    final options = <(String, shared.ReservationStatus?)>[
      ('All', null),
      if (_showSeats)
        ('Confirmed', shared.ReservationStatus.approved)
      else ...[
        ('Pending', shared.ReservationStatus.pending),
        ('Ready for Pickup', shared.ReservationStatus.approved),
        ('Rejected', shared.ReservationStatus.rejected),
      ],
      ('Cancelled', shared.ReservationStatus.cancelled),
    ];
    final colors = StudentPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (final (label, status) in options)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey('reservation-filter-${status?.name ?? 'all'}'),
                  label: Text(label),
                  selected: _statusFilter == status,
                  showCheckmark: false,
                  selectedColor: colors.primary,
                  backgroundColor: colors.card,
                  labelStyle: TextStyle(
                    color: _statusFilter == status ? Colors.white : colors.muted,
                    fontWeight: _statusFilter == status ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(color: _statusFilter == status ? colors.primary : colors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (_) => setState(() {
                    if (_showSeats) {
                      _seatFilter = status;
                    } else {
                      _bookFilter = status;
                    }
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildReservationList() {
    final reservations = _reservations;
    if (widget.library.isLoading && reservations.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            widget.library.loadError ??
                (_statusFilter != null
                    ? 'No reservations match this status.'
                    : _showSeats
                        ? 'You have no seat bookings yet.'
                        : 'You have no book reservations yet.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: reservations.length,
      separatorBuilder: (_, _) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildReservationCard(reservations[index]);
      },
    );
  }

  Widget _buildReservationCard(BookReservation reservation) {
    final card = _buildCardBody(reservation);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (reservation.isSeat) {
          _openSeatDetails(reservation.id);
        } else {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ReservationDetailsScreen(
              library: widget.library,
              reservationId: reservation.id,
            ),
          ));
        }
      },
      child: card,
    );
  }

  /// Opens H04 for a seat card, with the selected reservation.
  void _openSeatDetails(String reservationId) {
    final selected = widget.library.myReservations
        .where((r) => r.id == reservationId)
        .firstOrNull;
    if (selected == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeatReservationDetailsScreen(
          library: widget.library,
          reservation: selected,
        ),
      ),
    );
  }

  /// Opens H05 to modify a seat booking.
  void _openSeatModify(String reservationId) {
    final selected = widget.library.myReservations
        .where((r) => r.id == reservationId)
        .firstOrNull;
    if (selected == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModifySeatReservationScreen(
          library: widget.library,
          reservation: selected,
        ),
      ),
    );
  }

  bool _blockApprovedBook(String id, String action) {
    final current = widget.library.myReservations.where((r) => r.id == id).firstOrNull;
    if (current?.type != shared.ReservationType.book ||
        current?.status != shared.ReservationStatus.approved) {
      return false;
    }
    showReservationNotice(context, message: 'Approved book reservations cannot be $action.');
    return true;
  }
  Widget _buildCardBody(BookReservation reservation) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: StudentPalette.of(context).cardGradient,
        boxShadow: StudentPalette.of(context).cardShadow,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: StudentPalette.of(context).border,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookCover(reservation),
              SizedBox(width: 13),
              Expanded(
                child: _buildBookInformation(reservation),
              ),
              SizedBox(width: 5),
              _buildStatusBadge(reservation),
            ],
          ),
          SizedBox(height: 7),
          Divider(
            height: 1,
            color: StudentPalette.of(context).border,
          ),
          SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Modify',
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  textColor: StudentPalette.of(context).primary,
                  onPressed: reservation.isSeat
    ? (reservation.canModify ? () => _openSeatModify(reservation.id) : null)
    : reservation.canCancel
    ? () {
        if (_blockApprovedBook(reservation.id, 'modified')) return;
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
              SizedBox(width: 20),
              Expanded(
                child: _buildActionButton(
                  label: _cancellingId == reservation.id ? 'Cancelling…' : 'Cancel',
                  backgroundColor: StudentPalette.of(context).errorTint,
                  textColor: StudentPalette.of(context).error,
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
          style: TextStyle(
            color: StudentPalette.of(context).primary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3),
        Text(
          reservation.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: StudentPalette.of(context).muted,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 7),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: StudentPalette.of(context).primary,
              size: 21,
            ),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                reservation.dateLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: StudentPalette.of(context).muted,
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
      ReservationStatus.reserved => (StudentPalette.of(context).blueTint, StudentPalette.of(context).primary),
      ReservationStatus.ready => (StudentPalette.of(context).successTint, StudentPalette.of(context).success),
      ReservationStatus.pending => (StudentPalette.of(context).goldTint, StudentPalette.of(context).gold),
      ReservationStatus.rejected => (StudentPalette.of(context).errorTint, StudentPalette.of(context).error),
      ReservationStatus.closed => (StudentPalette.of(context).neutralTint, StudentPalette.of(context).muted),
    };
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        reservation.status,
        key: ValueKey('reservation-status-${reservation.id}'),
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
    if (reservation.statusType != ReservationStatus.rejected) return badge;
    return Semantics(
      button: true,
      label: 'View rejection reason',
      child: Tooltip(
        message: 'View rejection reason',
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () {
            final current = widget.library.myReservations
                .where((r) => r.id == reservation.id).firstOrNull;
            final reason = current?.rejectionReason?.trim();
            showReservationNotice(
              context,
              title: 'Reservation rejected',
              message: reason != null && reason.isNotEmpty
                  ? reason
                  : 'No rejection reason was provided. Please contact the library for details.',
            );
          },
          child: badge,
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
          color: StudentPalette.of(context).goldTint,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          Icons.event_seat_rounded,
          color: StudentPalette.of(context).gold,
          size: 32,
        ),
      );
    }
    return StudentBookCover(
      title: reservation.title,
      author: reservation.author,
      imageUrl: reservation.coverImageUrl,
      width: 68,
      height: 96,
      fit: BoxFit.contain,
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
          backgroundColor: enabled ? backgroundColor : StudentPalette.of(context).neutralTint,
          foregroundColor: textColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? textColor : StudentPalette.of(context).muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _confirmCancellation(BookReservation reservation) {
    if (_blockApprovedBook(reservation.id, 'cancelled')) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title:           Text(
            'Cancel Reservation?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your reservation for '
            '${reservation.title}?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Keep',
                style: TextStyle(
                  color: StudentPalette.of(context).primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _cancel(reservation);
              },
              child: Text(
                'Cancel Reservation',
                style: TextStyle(
                  color: StudentPalette.of(context).error,
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
      onHome: () { Navigator.of(context).popUntil((route) => route.isFirst); },
      onSearch: () { Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FindBooksScreen(library: widget.library))); },
      onReservations: () {
        // Already on Reservations.
      },
      onProfile: () { Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileScreen(library: widget.library))); },
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

  rejected,

  /// Cancelled.
  closed,
}

/// What one reservation card shows.
class BookReservation {
  BookReservation({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.statusType,
    required this.dateLabel,
    this.coverImageUrl,
    this.isSeat = false,
    this.canCancel = false,
    this.canModify = false,
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
  final bool canModify;
}
