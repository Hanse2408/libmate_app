import 'package:flutter/material.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final List<BookReservation> _reservations = [
    const BookReservation(
      title: 'Clean Code',
      author: 'Robert C. Martin',
      status: 'Reserved',
      statusType: ReservationStatus.reserved,
      dateLabel: 'Collect by 20 Sep 2025',
      coverType: CoverType.cleanCode,
    ),
    const BookReservation(
      title: 'Atomic Habits',
      author: 'James Clear',
      status: 'Ready for Pickup',
      statusType: ReservationStatus.ready,
      dateLabel: 'Pickup window: 16 Sep 2025',
      coverType: CoverType.atomicHabits,
    ),
    const BookReservation(
      title: 'Deep Work',
      author: 'Cal Newport',
      status: 'Reserved',
      statusType: ReservationStatus.reserved,
      dateLabel: 'Collect by 22 Sep 2025',
      coverType: CoverType.deepWork,
    ),
    const BookReservation(
      title: 'The Design of Everyday Things',
      author: 'Don Norman',
      status: 'Pending',
      statusType: ReservationStatus.pending,
      dateLabel: 'Requested on 15 Sep 2025',
      coverType: CoverType.design,
    ),
  ];

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
              child: _buildReservationList(),
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFBFD6F7),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Books',
                  style: TextStyle(
                    color: Color(0xFF1267D9),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Seat reservations are handled by the seat booking feature.',
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(13),
                child: const Center(
                  child: Text(
                    'Seats',
                    style: TextStyle(
                      color: Color(0xFF17356D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildReservationCard(_reservations[index]);
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
              _buildBookCover(reservation.coverType),
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
                  onPressed: () {
                    _showModifyMessage(reservation);
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildActionButton(
                  label: 'Cancel',
                  backgroundColor: const Color(0xFFFFE6E6),
                  textColor: const Color(0xFFE53935),
                  onPressed: () {
                    _confirmCancellation(reservation);
                  },
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF536987),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF17356D),
              size: 30,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BookReservation reservation) {
    Color backgroundColor;
    Color textColor;

    switch (reservation.statusType) {
      case ReservationStatus.reserved:
        backgroundColor = const Color(0xFFEAF3FF);
        textColor = const Color(0xFF1267D9);
        break;
      case ReservationStatus.ready:
        backgroundColor = const Color(0xFFDDF6E6);
        textColor = const Color(0xFF159447);
        break;
      case ReservationStatus.pending:
        backgroundColor = const Color(0xFFFFEEDB);
        textColor = const Color(0xFFE78A00);
        break;
    }

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

  Widget _buildBookCover(CoverType type) {
    switch (type) {
      case CoverType.cleanCode:
        return Container(
          width: 68,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFF111B2D),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Clean Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF20B6F2),
                size: 24,
              ),
            ],
          ),
        );

      case CoverType.atomicHabits:
        return Container(
          width: 68,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFF4E6C8),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tiny Changes\nRemarkable Results',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF75644D),
                  fontSize: 5,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Atomic\nHabits',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE85C16),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );

      case CoverType.deepWork:
        return Container(
          width: 68,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD72F),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DEEP',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'WORK',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'CAL NEWPORT',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

      case CoverType.design:
        return Container(
          width: 68,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD95A),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'THE DESIGN\nOF EVERYDAY\nTHINGS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFE5532F),
                size: 25,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showModifyMessage(BookReservation reservation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Modify ${reservation.title} will be connected next.',
        ),
      ),
    );
  }

  void _confirmCancellation(BookReservation reservation) {
    showDialog<void>(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
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
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${reservation.title} reservation cancelled.',
                    ),
                  ),
                );
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
                selected: false,
              ),
              _buildNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Reservations',
                selected: true,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
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
                  ? const Color(0xFF1267D9)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1267D9)
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

enum ReservationStatus {
  reserved,
  ready,
  pending,
}

enum CoverType {
  cleanCode,
  atomicHabits,
  deepWork,
  design,
}

class BookReservation {
  const BookReservation({
    required this.title,
    required this.author,
    required this.status,
    required this.statusType,
    required this.dateLabel,
    required this.coverType,
  });

  final String title;
  final String author;
  final String status;
  final ReservationStatus statusType;
  final String dateLabel;
  final CoverType coverType;
}