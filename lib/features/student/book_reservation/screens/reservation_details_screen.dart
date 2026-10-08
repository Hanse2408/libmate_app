import '../../common/widgets/loan_period_field.dart';
import '../../../../models/reservation_display_reference.dart';
import '../../common/widgets/student_palette.dart';
import '../../../../core/constants/book_pickup_locations.dart';
import '../widgets/reservation_notice.dart';
import '../widgets/reservation_progress_card.dart';
import '../../../../models/book.dart';
import '../../common/widgets/student_book_cover.dart';
import 'my_reservations_screen.dart' show MyReservationsScreen;
import 'find_books_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';

import 'package:flutter/material.dart';

import '../../common/data/student_library_repository.dart';
import '../../../../models/reservation.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({
    super.key,
    required this.library,
    required this.reservationId,
  });

  final StudentLibraryRepository library;
  final String reservationId;

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  ReservationRecord? get _reservation {
    for (final reservation in widget.library.myReservations) {
      if (reservation.id == widget.reservationId) {
        return reservation;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    widget.library.addListener(_refreshReservation);
  }

  void _refreshReservation() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.library.removeListener(_refreshReservation);
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _cancelledLocally = false;
  bool get _cancelled =>
      _cancelledLocally || _reservation?.status == ReservationStatus.cancelled;
  bool _cancelling = false;

  BookRecord? get _book {
    final reservation = _reservation;
    return reservation == null
        ? null
        : widget.library.bookById(reservation.itemId);
  }

  String get author => _book?.author.trim().isNotEmpty == true
      ? _book!.author
      : 'Author unavailable';
  String get category => _book?.category.trim().isNotEmpty == true
      ? _book!.category
      : 'Category unavailable';
  static const String pickupDesk = 'Book Collection Desk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    _buildBookCard(),
                    if (_reservation != null &&
                        _reservation!.type == ReservationType.book) ...[
                      const SizedBox(height: 16),
                      ReservationProgressCard(
                        reservation: _reservation!,
                        loan: widget.library.loanProgressForReservation(
                          widget.reservationId,
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    _buildReservationInformation(),
                    SizedBox(height: 16),
                    _buildNotes(),
                    SizedBox(height: 16),
                    _buildModifyButton(),
                    SizedBox(height: 12),
                    _buildCancelButton(),
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
      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          _buildBackButton(),
          Expanded(
            child: Center(
              child: Text(
                'Reservation Details',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: StudentPalette.of(context).primary
              .withValues(alpha: StudentPalette.of(context).isDark ? .32 : .22),
        ),
      ),
      child: IconButton(
        onPressed: () {
          Navigator.of(context).maybePop();
        },
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Theme.of(context).colorScheme.onSurface,
          size: 19,
        ),
      ),
    );
  }

  Widget _buildBookCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: StudentPalette.of(context).cardGradient,
        boxShadow: StudentPalette.of(context).cardShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudentPalette.of(context).gold.withValues(alpha: .32),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          _buildBookCover(),
          SizedBox(width: 26),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _book?.title ?? _reservation?.itemName ?? 'Book',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  author,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSmallBadge(
                      label: 'Book',
                      backgroundColor: StudentPalette.of(context).blueTint,
                      textColor: StudentPalette.of(context).primary,
                    ),
                    _buildSmallBadge(
                      label: _book?.stock.label ?? 'Book unavailable',
                      backgroundColor: _book?.isAvailable == true
                          ? StudentPalette.of(context).successTint
                          : StudentPalette.of(context).errorTint,
                      textColor: _book?.isAvailable == true
                          ? StudentPalette.of(context).success
                          : StudentPalette.of(context).error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover() {
    return StudentBookCover(
      title: _book?.title ?? _reservation?.itemName ?? 'Book',
      author: _book?.author ?? '',
      imageUrl: _book?.coverAsset,
      width: 92,
      height: 126,
      radius: 7,
    );
  }

  Widget _buildSmallBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildReservationInformation() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: StudentPalette.of(context).card,
        gradient: StudentPalette.of(context).cardGradient,
        boxShadow: StudentPalette.of(context).cardShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudentPalette.of(context).gold.withValues(alpha: .32),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservation Information',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          _buildInformationRow(
            icon: Icons.bookmark_border_rounded,
            label: 'Reservation Reference',
            value: ReservationDisplayReference.forId(widget.reservationId),
          ),
          _buildInformationDivider(),
          _buildInformationRow(
            icon: Icons.calendar_today_outlined,
            label: 'Reservation Date',
            value: _reservation == null ? '-' : _formatDate(_reservation!.date),
          ),
          _buildInformationDivider(),
          _buildInformationRow(
            icon: Icons.schedule_outlined,
            label: 'Loan Period',
            value: _reservation?.loanPeriodDays == null
                ? '-'
                : '${_reservation!.loanPeriodDays} Days',
          ),
          _buildInformationDivider(),
          _buildLocationRow(),
        ],
      ),
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: StudentPalette.of(context).muted, size: 21),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: StudentPalette.of(context).muted,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: StudentPalette.of(context).text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationDivider() {
    return Divider(height: 1, color: StudentPalette.of(context).border);
  }

  Widget _buildLocationRow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: StudentPalette.of(context).muted,
            size: 21,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Pickup Location',
              style: TextStyle(
                color: StudentPalette.of(context).muted,
                fontSize: 14,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _reservation?.pickupLocation ?? '-',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: StudentPalette.of(context).text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                pickupDesk,
                style: TextStyle(
                  color: StudentPalette.of(context).muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 6, 20, 20),
      decoration: BoxDecoration(
        color: StudentPalette.of(context).card,
        gradient: StudentPalette.of(context).cardGradient,
        boxShadow: StudentPalette.of(context).cardShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudentPalette.of(context).primary.withValues(alpha: .25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Theme.of(context).colorScheme.onSurface,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: StudentPalette.of(context).blueTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: StudentPalette.of(context).primary
                    .withValues(alpha: .25),
              ),
            ),
            child: Text(
              'The book will be held for 3 days from the '
              'reservation date. Please bring your student ID '
              'when collecting the book.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _cancelled ? null : _modifyReservation,
        icon: Icon(Icons.edit_outlined, size: 19),
        label: Text(
          'Modify Reservation',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: StudentPalette.of(context).primary,
          disabledBackgroundColor: StudentPalette.of(context).border,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _cancelled || _cancelling ? null : _showCancelDialog,
        icon: Icon(Icons.delete_outline_rounded, size: 19),
        label: Text(
          _cancelling
              ? 'Cancelling…'
              : _cancelled
              ? 'Reservation Cancelled'
              : 'Cancel Reservation',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: StudentPalette.of(context).error,
          disabledForegroundColor: StudentPalette.of(context).muted,
          backgroundColor: StudentPalette.of(context).card,
          side: BorderSide(
            color: _cancelled
                ? StudentPalette.of(context).border
                : StudentPalette.of(context).error,
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _modifyReservation() async {
    final reservation = _reservation;
    if (reservation == null || !reservation.isPending) {
      showReservationNotice(
        context,
        message: reservation?.status == ReservationStatus.approved
            ? 'Approved book reservations cannot be modified.'
            : 'Only pending book reservations can be modified.',
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = today.add(Duration(days: 30));
    var pickupDate = reservation.date;
    var loanPeriod =
        reservation.loanPeriodDays ?? widget.library.settings.loanPeriodDays;
    var location =
        reservation.pickupLocation ?? BookPickupLocations.defaultLocation;

    final locations = BookPickupLocations.including(location);
    var saving = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text('Modify Reservation'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.calendar_today_outlined),
                      label: Text('Pickup date: ${_formatDate(pickupDate)}'),
                      onPressed: saving
                          ? null
                          : () async {
                              final initialDate = pickupDate.isBefore(today)
                                  ? today
                                  : pickupDate.isAfter(lastDate)
                                  ? lastDate
                                  : pickupDate;
                              final selected = await showDatePicker(
                                context: dialogContext,
                                initialDate: initialDate,
                                firstDate: today,
                                lastDate: lastDate,
                              );
                              if (selected != null && dialogContext.mounted) {
                                updateDialog(() => pickupDate = selected);
                              }
                            },
                    ),
                    SizedBox(height: 16),
                    LoanPeriodField(
                      initialValue: loanPeriod,
                      enabled: !saving,
                      onChanged: (days) => loanPeriod = days,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: location,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Pickup location',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final item in locations)
                          DropdownMenuItem(value: item, child: Text(item)),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null)
                                updateDialog(() => location = value);
                            },
                    ),
                    if (error != null) ...[
                      SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (pickupDate.isBefore(today)) {
                          updateDialog(
                            () =>
                                error = 'Choose today or a future pickup date.',
                          );
                          return;
                        }
                        final latest = _reservation;
                        if (latest == null || !latest.isPending) {
                          updateDialog(
                            () => error = 'Only pending book reservations can be modified. Approved reservations cannot be modified.',
                          );
                          return;
                        }
                        updateDialog(() {
                          saving = true;
                          error = null;
                        });
                        final result = await widget.library
                            .updateBookReservation(
                              reservationId: reservation.id,
                              pickupDate: pickupDate,
                              pickupLocation: location,
                              loanPeriodDays: loanPeriod,
                            );
                        if (!dialogContext.mounted) return;
                        if (!result.success) {
                          updateDialog(() {
                            saving = false;
                            error = result.message ?? 'Unable to update reservation. Please try again.';
                          });
                          return;
                        }
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reservation updated.')),
                        );
                      },
                child: Text(saving ? 'Saving...' : 'OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog() {
    if (_reservation?.status == ReservationStatus.approved) {
      showReservationNotice(
        context,
        message: 'Approved book reservations cannot be cancelled.',
      );
      return;
    }
    // Collected / returned books are handled by the librarian.
    if (_reservation?.isCollected == true || _reservation?.isReturned == true) {
      showReservationNotice(
        context,
        message: 'This book has already been ${_reservation!.status.label.toLowerCase()}.',
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: StudentPalette.of(context).card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Cancel Reservation?',
            style: TextStyle(
              color: StudentPalette.of(context).text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this book reservation?',
            style: TextStyle(
              color: StudentPalette.of(context).muted,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Keep Reservation',
                style: TextStyle(
                  color: StudentPalette.of(context).primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final reservation = _reservation;
                if (reservation == null) return;

                setState(() => _cancelling = true);
                final result = await widget.library.cancelReservation(
                  reservation.id,
                );
                if (!mounted) return;

                setState(() {
                  _cancelling = false;
                  if (result.success) _cancelledLocally = true;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? 'Reservation cancelled.'
                          : result.message ?? 'Unable to cancel reservation.',
                    ),
                  ),
                );
              },
              child: Text(
                'Cancel Reservation',
                style: TextStyle(
                  color: StudentPalette.of(context).error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
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
            builder: (_) => FindBooksScreen(library: widget.library),
          ),
        );
      },
      onReservations: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MyReservationsScreen(library: widget.library),
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
}
