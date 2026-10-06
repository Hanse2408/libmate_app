import 'package:flutter/material.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import 'find_books_screen.dart';
import 'my_reservations_screen.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    _buildSuccessIcon(),
                    const SizedBox(height: 24),
                    _buildSuccessMessage(),
                    const SizedBox(height: 24),
                    _buildReceipt(),
                    const SizedBox(height: 20),
                    _buildPickupInformation(),
                    const SizedBox(height: 24),
                    _buildViewReservationsButton(context),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          _buildBackButton(context),
          const Expanded(
            child: Center(
              child: Text(
                'Booking Confirmation',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: IconButton(
        onPressed: () {
          Navigator.of(context).maybePop();
        },
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF172033),
          size: 19,
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
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
              color: const Color(0xFFF2B84B),
              size: 13,
            ),
          ),
          Positioned(
            top: 48,
            left: 8,
            child: _buildDecorationCircle(
              color: const Color(0xFFE98955),
              size: 13,
            ),
          ),
          Positioned(
            top: 40,
            right: 0,
            child: _buildDecorationCircle(
              color: const Color(0xFFE98955),
              size: 13,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 35,
            child: _buildDecorationCircle(
              color: const Color(0xFFF2B84B),
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
              color: const Color(0xFFF47BA6),
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
                  color: const Color(0xFF56D9E5),
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
                  color: const Color(0xFFF47BA6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Main green success circle
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Color(0xFF22D39A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
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

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        const Text(
          'Reservation Requested!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Your request was sent to the library. You can collect\n'
          'the book once a librarian approves it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF475569),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildReceipt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF2B84B),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reservation Receipt',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 5),
          _buildReceiptRow(
            icon: Icons.menu_book_outlined,
            label: 'Book Title',
            value: bookTitle,
          ),
          _buildReceiptRow(
            icon: Icons.calendar_today_outlined,
            label: 'Pickup Date',
            value: pickupDate,
          ),
          _buildReceiptRow(
            icon: Icons.access_time_rounded,
            label: 'Loan Period',
            value: loanPeriod,
          ),
          _buildReceiptRow(
            icon: Icons.location_on_outlined,
            label: 'Pickup Location',
            value: pickupLocation,
          ),
          _buildReceiptRow(
            icon: Icons.hourglass_top_rounded,
            label: 'Status',
            value: 'Pending approval',
            valueColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF172033),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(
              icon,
              color: const Color(0xFF172033),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB8D3FF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Show this screen or the receipt code at the Floor 1 main '
              'desk to complete your pickup.',
              style: TextStyle(
                color: Color(0xFF475569),
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
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: const Text(
          'View My Reservations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF172033),
          side: const BorderSide(
            color: Color(0xFFF2B84B),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: const Text(
          'Back to Home',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
Widget _buildBottomNavigationBar(BuildContext context) {
  return StudentBottomNavigation(
    selectedIndex: 2,
    onHome: () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    },
    onSearch: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FindBooksScreen(
            library: library,
          ),
        ),
      );
    },
    onReservations: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MyReservationsScreen(
            library: library,
          ),
        ),
      );
    },
    onProfile: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(library: library),
        ),
      );
    },
  );
}
  
}