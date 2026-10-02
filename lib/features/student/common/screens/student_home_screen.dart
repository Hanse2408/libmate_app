/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';*/
import 'package:flutter/material.dart';
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // LibMate colour palette
  static const Color primaryBlue = Color(0xFF2563EB);
  //static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF172033);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color accentGold = Color(0xFFF2B84B);
  static const Color availableGreen = Color(0xFF22A06B);

  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 26),
              _buildGreeting(),
              const SizedBox(height: 18),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildActionCards(),
              const SizedBox(height: 26),
              _buildReservationHeader(),
              const SizedBox(height: 12),
              _buildSeatReservationCard(),
              const SizedBox(height: 12),
              _buildBookReservationCard(),
              const SizedBox(height: 20),
              _buildReminderCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LibMate',
                style: TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: textDark,
              size: 28,
            ),
            Positioned(
              right: -4,
              top: -5,
              child: Container(
                width: 17,
                height: 17,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC4C4C),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: textDark,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'ND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning,',
          style: TextStyle(
            color: Color(0xFF4B5F80),
            fontSize: 15,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Nilumi!',
          style: TextStyle(
            color: textDark,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'What would you like to do today?',
          style: TextStyle(
            color: secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF8BB4FF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: secondaryText,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search for books, authors, or topics...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: const Icon(
              Icons.tune_rounded,
              color: secondaryText,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Find Books',
            subtitle: 'Check availability',
            icon: Icons.menu_book_rounded,
            iconBackground: primaryBlue,
            backgroundColor: lightBlue,
            borderColor: const Color(0xFFB5D2FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            title: 'Book a Seat',
            subtitle: 'Reserve your study space',
            icon: Icons.event_seat_rounded,
            iconBackground: Color(0xFFFFA500),
            backgroundColor: const Color(0xFFFFF1C7),
            borderColor: const Color(0xFFFFD65C),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBackground,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      height: 111,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Your Current Reservation',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See all',
            style: TextStyle(
              color: primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatReservationCard() {
    return _buildReservationCard(
      icon: Icons.event_seat_rounded,
      iconColor: const Color(0xFFFFA500),
      iconBackground: const Color(0xFFFFF4D8),
      title: 'Reading Room Seat',
      status: 'Confirmed',
      details: const [
        '12 Sep 2025 • 2:00 PM - 4:00 PM',
        'Seat A12',
      ],
    );
  }

  Widget _buildBookReservationCard() {
    return _buildReservationCard(
      icon: Icons.menu_book_rounded,
      iconColor: primaryBlue,
      iconBackground: lightBlue,
      title: 'Book Reservation',
      status: 'Confirmed',
      details: const [
        'Clean code',
        'pick up by 15th Oct 2026',
        'Book ID: LB001234',
      ],
    );
  }

  Widget _buildReservationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String status,
    required List<String> details,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9CC0FF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Confirmed',
                        style: TextStyle(
                          color: availableGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...details.map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      detail,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
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

  Widget _buildReminderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD65C),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8A3),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentGold,
              ),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFFE09B00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'A quieter tomorrow starts with you. Always remember to check-out of your seat.',
              style: TextStyle(
                color: Color(0xFF8A4B08),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: cardWhite,
      selectedItemColor: primaryBlue,
      unselectedItemColor: const Color(0xFF94A8C4),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.manage_search_outlined),
          activeIcon: Icon(Icons.manage_search_rounded),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month_rounded),
          label: 'Reservations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}