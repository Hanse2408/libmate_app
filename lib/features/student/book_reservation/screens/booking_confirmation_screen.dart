import 'package:flutter/material.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  // Mock reservation data for now.
  // This will be replaced with real reservation data later.
  static const String bookTitle = 'Clean Code';
  static const String pickupDate = '15 Sep 2025';
  static const String loanPeriod = '14 Days';
  static const String receiptCode = 'LM-4029-X9';

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
      bottomNavigationBar: _buildBottomNavigationBar(),
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
          'Reservation Successful!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Your book is secured and ready for pickup on your\n'
          'selected date.',
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
            icon: Icons.receipt_long_outlined,
            label: 'Receipt Code',
            value: receiptCode,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'My Reservations will be connected next.',
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
          height: 68,
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
                icon: Icons.calendar_today_outlined,
                label: 'Reservations',
                selected: false,
              ),
              _buildNavItem(
                icon: Icons.account_circle_outlined,
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
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
}