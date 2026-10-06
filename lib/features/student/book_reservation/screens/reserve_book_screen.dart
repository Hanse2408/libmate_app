import 'package:flutter/material.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import 'find_books_screen.dart';
import 'my_reservations_screen.dart';
import '../../../../models/book.dart';
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_book_cover.dart';
import 'booking_confirmation_screen.dart';

/// Reserve a catalogue book: pickup date, loan period and location. The
/// request is saved in Firestore as "pending" for a librarian to approve.
class ReserveBookScreen extends StatefulWidget {
  const ReserveBookScreen({
    super.key,
    required this.library,
    required this.bookId,
  });

  final StudentLibraryRepository library;
  final String bookId;

  @override
  State<ReserveBookScreen> createState() => _ReserveBookScreenState();
}

class _ReserveBookScreenState extends State<ReserveBookScreen> {
  DateTime _pickupDate = _today().add(const Duration(days: 1));

  late int _loanPeriod =
      _loanPeriods.contains(widget.library.settings.loanPeriodDays)
          ? widget.library.settings.loanPeriodDays
          : 14;

  bool _saving = false;

  late BookRecord _book;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _pickupLocation = 'Main Desk (Floor 1)';

  final List<int> _loanPeriods = [7, 14, 21, 30];

  final List<String> _pickupLocations = [
    'Main Desk (Floor 1)',
    'Main Desk (Floor 2)',
    'Library Counter',
  ];

  @override
  Widget build(BuildContext context) {
    final book = widget.library.bookById(widget.bookId);

    if (book == null) {
      return const Scaffold(
        body: Center(
          child: Text('This book is no longer in the catalogue.'),
        ),
      );
    }

    _book = book;

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
                Text(
                  _book.title,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _book.author,
                  style: const TextStyle(
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
                  child: Text(
                    _book.category,
                    style: const TextStyle(
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
                  child: Text(
                    '${_book.availableCopies} of ${_book.totalCopies} available',
                    style: const TextStyle(
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
    return StudentBookCover(
      title: _book.title,
      author: _book.author,
      imageUrl: _book.coverAsset,
      width: 92,
      height: 126,
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
        onPressed: _saving ? null : _confirmReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _saving ? 'Sending request…' : 'Confirm Reservation',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
  return StudentBottomNavigation(
    selectedIndex: 1,
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
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MyReservationsScreen(
            library: widget.library,
          ),
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
  Future<void> _selectPickupDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: _today(),
      lastDate: _today().add(const Duration(days: 30)),
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

  /// Saves the reservation in Firestore. Success is only shown after the
  /// save is confirmed; otherwise the reason is shown and nothing changes.
  Future<void> _confirmReservation() async {
    if (_saving) return;

    setState(() => _saving = true);

    final result = await widget.library.reserveBook(
      book: _book,
      pickupDate: _pickupDate,
      loanPeriodDays: _loanPeriod,
      pickupLocation: _pickupLocation,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.message!),
          ),
        );
      return;
    }

    // The reservation was successfully created.
    // Pass its real Firestore ID to the confirmation screen.
    final reservationId = result.reservationId;

    if (reservationId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Reservation was created, but its ID could not be found.',
            ),
          ),
        );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BookingConfirmationScreen(
          library: widget.library,
          bookTitle: _book.title,
          pickupDate: _formatDate(_pickupDate),
          loanPeriod: '$_loanPeriod Days',
          pickupLocation: _pickupLocation,
          reservationId: reservationId,
        ),
      ),
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