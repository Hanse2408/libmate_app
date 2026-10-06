import 'package:flutter/material.dart';

class ModifyBookReservationScreen extends StatefulWidget {
  const ModifyBookReservationScreen({super.key});

  @override
  State<ModifyBookReservationScreen> createState() =>
      _ModifyBookReservationScreenState();
}

class _ModifyBookReservationScreenState
    extends State<ModifyBookReservationScreen> {
  DateTime _reservationDate = DateTime(2025, 9, 15);
  String _pickupLocation = 'Main Library, 3rd Floor';

  final TextEditingController _notesController = TextEditingController(
    text: 'Will collect in the afternoon around 3:00 PM.\nPlease hold.',
  );

  final List<String> _pickupLocations = [
    'Main Library, 3rd Floor',
    'Main Library, 2nd Floor',
    'Main Desk, Floor 1',
    'Library Collection Desk',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    _buildBookCard(),
                    const SizedBox(height: 16),
                    _buildChangeSchedule(),
                    const SizedBox(height: 16),
                    _buildImportantNotice(),
                    const SizedBox(height: 16),
                    _buildConfirmButton(),
                    const SizedBox(height: 12),
                    _buildDiscardButton(),
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
          _buildBackButton(),
          const Expanded(
            child: Center(
              child: Text(
                'Modify Reservation',
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

  Widget _buildBackButton() {
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

  Widget _buildBookCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 7, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF2B84B),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          _buildBookCover(),
          const SizedBox(width: 26),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clean Code',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Robert C. Martin',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'Computer Science',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(7),
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
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CLEAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'CODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

  Widget _buildChangeSchedule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8DB7FF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change Schedule',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Reservation Date',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildDateField(),
          const SizedBox(height: 14),
          const Text(
            'Pickup Location',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildLocationField(),
          const SizedBox(height: 14),
          const Text(
            'Additional Notes',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectReservationDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFD9E2EE),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatDate(_reservationDate),
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return InkWell(
      onTap: _selectPickupLocation,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFD9E2EE),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _pickupLocation,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      style: const TextStyle(
        color: Color(0xFF172033),
        fontSize: 13,
        height: 1.4,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFD9E2EE),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFD9E2EE),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFB8D3FF),
        ),
      ),
      child: const Text(
        'Important: Holds are limited to 3 days maximum from the '
        'selected pickup date.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: ElevatedButton.icon(
        onPressed: _confirmUpdate,
        icon: const Icon(
          Icons.check_rounded,
          size: 19,
        ),
        label: const Text(
          'Confirm & Update',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscardButton() {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: OutlinedButton(
        onPressed: _discardChanges,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE53935),
          side: const BorderSide(
            color: Color(0xFFE53935),
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: const Text(
          'Discard Changes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _selectReservationDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _reservationDate,
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
        _reservationDate = selectedDate;
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

  void _confirmUpdate() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Reservation Updated',
            style: TextStyle(
              color: Color(0xFF172033),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Your reservation has been updated.\n\n'
            'Date: ${_formatDate(_reservationDate)}\n'
            'Pickup: $_pickupLocation\n'
            'Notes: ${_notesController.text}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
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

  void _discardChanges() {
    Navigator.of(context).maybePop();
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