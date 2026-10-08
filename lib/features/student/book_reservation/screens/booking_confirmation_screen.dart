import '../../../../models/reservation_display_reference.dart';
import '../../common/widgets/student_palette.dart';
import 'my_reservations_screen.dart';
import 'find_books_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import 'package:flutter/material.dart';

import '../../common/data/student_library_repository.dart';
import 'reservation_details_screen.dart';


/// Shown after a book reservation request was saved in Firestore. The
/// request is pending until a librarian approves it.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
  super.key,
  required this.library,
  required this.bookTitle,
  required this.pickupDate,
  required this.loanPeriod,
  required this.pickupLocation,
  required this.reservationId,
});

  final StudentLibraryRepository library;
  final String bookTitle;
  final String pickupDate;
  final String loanPeriod;
  final String pickupLocation;
  final String reservationId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    _buildSuccessIcon(context),
                    SizedBox(height: 24),
                    _buildSuccessMessage(context),
                    SizedBox(height: 24),
                    _buildReceipt(context),
                    SizedBox(height: 20),
                    _buildPickupInformation(context),
                    SizedBox(height: 24),
                    _buildViewReservationsButton(context),
                    SizedBox(height: 12),
                    _buildBackHomeButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          _buildBackButton(context),
          Expanded(
            child: Center(
              child: Text(
                'Booking Confirmation',
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

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: StudentPalette.of(context).primary.withValues(alpha: StudentPalette.of(context).isDark ? .32 : .22),
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

  Widget _buildSuccessIcon(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 145,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative circles
          Positioned(
            top: 18,
            right: 24,
            child: _buildDecorationCircle(
              color: StudentPalette.of(context).gold,
              size: 13,
            ),
          ),
          Positioned(
            top: 48,
            left: 8,
            child: _buildDecorationCircle(
              color: StudentPalette.of(context).gold,
              size: 13,
            ),
          ),
          Positioned(
            top: 40,
            right: 0,
            child: _buildDecorationCircle(
              color: StudentPalette.of(context).gold,
              size: 13,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 35,
            child: _buildDecorationCircle(
              color: StudentPalette.of(context).gold,
              size: 9,
            ),
          ),
          Positioned(
            bottom: 6,
            right: 32,
            child: _buildDecorationCircle(
              color: const Color(0xFF3B82F6),
              size: 13,
            ),
          ),
          Positioned(
            bottom: 2,
            left: 67,
            child: _buildDecorationCircle(
              color: StudentPalette.of(context).gold,
              size: 8,
            ),
          ),

          // Decorative curved strokes
          Positioned(
            top: 8,
            left: 28,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 8,
                height: 25,
                decoration: BoxDecoration(
                  color: StudentPalette.of(context).gold,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 15,
            child: Transform.rotate(
              angle: 0.55,
              child: Container(
                width: 8,
                height: 23,
                decoration: BoxDecoration(
                  color: StudentPalette.of(context).gold,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Main green success circle
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Color(0xFF22D39A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorationCircle({
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'Reservation Requested!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Your request was sent to the library. You can collect\n'
          'the book once a librarian approves it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildReceipt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: StudentPalette.of(context).cardGradient,
        boxShadow: StudentPalette.of(context).cardShadow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: StudentPalette.of(context).gold.withValues(alpha: .32),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reservation Receipt',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(
            height: 1,
            color: StudentPalette.of(context).primary.withValues(alpha: StudentPalette.of(context).isDark ? .32 : .22),
          ),
          SizedBox(height: 5),
          _buildReceiptRow(
            context: context,
            icon: Icons.receipt_long_outlined,
            label: 'Reservation Reference',
            value: ReservationDisplayReference.forId(reservationId),
          ),
          _buildReceiptRow(
          context: context,
            icon: Icons.menu_book_outlined,
            label: 'Book Title',
            value: bookTitle,
          ),
          _buildReceiptRow(
          context: context,
            icon: Icons.calendar_today_outlined,
            label: 'Pickup Date',
            value: pickupDate,
          ),
          _buildReceiptRow(
          context: context,
            icon: Icons.access_time_rounded,
            label: 'Loan Period',
            value: loanPeriod,
          ),
          _buildReceiptRow(
          context: context,
            icon: Icons.location_on_outlined,
            label: 'Pickup Location',
            value: pickupLocation,
          ),
          _buildReceiptRow(
          context: context,
            icon: Icons.hourglass_top_rounded,
            label: 'Status',
            value: 'Pending approval',
            valueColor: StudentPalette.of(context).primary,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupInformation(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: StudentPalette.of(context).blueTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: StudentPalette.of(context).primary.withValues(alpha: .25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: StudentPalette.of(context).primary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Show this screen or the receipt code at $pickupLocation '
              'to complete your pickup.',
              style: TextStyle(
                color: StudentPalette.of(context).muted,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewReservationsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: () {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ReservationDetailsScreen(
  library: library,
  reservationId: reservationId,
),
    ),
  );
},
        style: ElevatedButton.styleFrom(
          backgroundColor: StudentPalette.of(context).primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'View My Reservations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBackHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).popUntil(
            (route) => route.isFirst,
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: StudentPalette.of(context).gold,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Back to Home',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return StudentBottomNavigation(
      selectedIndex: 2,
      onHome: () { Navigator.of(context).popUntil((route) => route.isFirst); },
      onSearch: () { Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FindBooksScreen(library: library))); },
      onReservations: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MyReservationsScreen(library: library)));
      },
      onProfile: () { Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileScreen(library: library))); },
    );
  }


}