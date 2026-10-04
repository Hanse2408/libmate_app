import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/book_reservation.dart';
import '../providers/book_reservation_provider.dart';

class ReserveBookScreen extends StatefulWidget {
  const ReserveBookScreen({super.key});

  @override
  State<ReserveBookScreen> createState() => _ReserveBookScreenState();
}

class _ReserveBookScreenState extends State<ReserveBookScreen> {
  final BookReservationProvider _reservationProvider =
    BookReservationProvider();

  DateTime _pickupDate = DateTime(2025, 9, 15);
  int _loanPeriod = 14;
  String _pickupLocation = 'Main Desk (Floor 1)';

  final List<int> _loanPeriods = [7, 14, 21, 30];

  final List<String> _pickupLocations = [
    'Main Desk (Floor 1)',
    'Main Desk (Floor 2)',
    'Library Counter',
  ];

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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookCard(),
                    const SizedBox(height: 22),
                    const Text(
                      'Reservation Details',
                      style: TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReservationDetails(),
                    const SizedBox(height: 20),
                    _buildWarning(),
                    const SizedBox(height: 20),
                    _buildConfirmButton(),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Reserve Book',
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

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
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
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: const Color(0xFF172033),
          size: 19,
        ),
      ),
    );
  }

  Widget _buildBookCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF2B84B),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          _buildBookCover(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clean Code',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Robert C. Martin',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Computer Science',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF7EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(
                      color: Color(0xFF22A06B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover() {
    return Container(
      width: 92,
      height: 126,
      decoration: BoxDecoration(
        color: const Color(0xFF102D4D),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF52718F),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'CLEAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'CODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'A Handbook of Agile\nSoftware Craftsmanship',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD6E4F0),
                    fontSize: 5,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'ROBERT C. MARTIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationDetails() {
    return Container(
      width: double.infinity,
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
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            title: 'Pickup Date',
            value: _formatDate(_pickupDate),
            onTap: _selectPickupDate,
            showDivider: true,
          ),
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            title: 'Loan Period',
            value: '$_loanPeriod Days',
            onTap: _selectLoanPeriod,
            showDivider: true,
          ),
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            title: 'Pickup Location',
            value: _pickupLocation,
            onTap: _selectPickupLocation,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF172033),
                  size: 23,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF2D56B),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF8DE),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Color(0xFFFF9800),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Reserved books must be picked up within 48 '
              'hours of your pickup date, otherwise your '
              'reservation will be cancelled.',
              style: TextStyle(
                color: Color(0xFF8A4B08),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _confirmReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Confirm Reservation',
          style: TextStyle(
            fontSize: 15,
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

  Future<void> _selectPickupDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF172033),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _pickupDate = selectedDate;
      });
    }
  }

  Future<void> _selectLoanPeriod() async {
    final selectedPeriod = await showModalBottomSheet<int>(
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
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Loan Period',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._loanPeriods.map(
                (period) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '$period Days',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 15,
                    ),
                  ),
                  trailing: period == _loanPeriod
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2563EB),
                        )
                      : const Icon(
                          Icons.circle_outlined,
                          color: Color(0xFFCBD5E1),
                        ),
                  onTap: () {
                    Navigator.pop(context, period);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedPeriod != null) {
      setState(() {
        _loanPeriod = selectedPeriod;
      });
    }
  }

  Future<void> _selectPickupLocation() async {
    final selectedLocation = await showModalBottomSheet<String>(
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
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Pickup Location',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._pickupLocations.map(
                (location) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF2563EB),
                  ),
                  title: Text(
                    location,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 15,
                    ),
                  ),
                  trailing: location == _pickupLocation
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2563EB),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context, location);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedLocation != null) {
      setState(() {
        _pickupLocation = selectedLocation;
      });
    }
  }

 Future<void> _confirmReservation() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please sign in to make a reservation.'),
      ),
    );
    return;
  }

  final reservation = BookReservation(
    reservationId: '',
    userId: user.uid,
    bookId: 'CLEAN_CODE',
    pickupDate: _pickupDate,
    loanPeriodDays: _loanPeriod,
    status: 'PENDING',
    receiptCode: 'RC-${DateTime.now().millisecondsSinceEpoch}',
  );

  final reservationId =
      await _reservationProvider.createReservation(reservation);

  if (!mounted) return;

  if (reservationId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to create reservation. Please try again.'),
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Reservation Confirmed',
          style: TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Your Clean Code reservation has been created.\n\n'
          'Pickup: ${_formatDate(_pickupDate)}\n'
          'Loan period: $_loanPeriod days\n'
          'Location: $_pickupLocation\n\n'
          'Receipt Code: ${reservation.receiptCode}',
          style: const TextStyle(
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
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
}