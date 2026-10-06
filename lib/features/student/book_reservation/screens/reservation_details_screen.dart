import 'package:flutter/material.dart';
import '../../common/data/student_library_repository.dart';
import '../../../../models/reservation.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import 'find_books_screen.dart';
import 'my_reservations_screen.dart';

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

class _ReservationDetailsScreenState
    extends State<ReservationDetailsScreen> {

       ReservationRecord? get _reservation {
    for (final reservation in widget.library.myReservations) {
      if (reservation.id == widget.reservationId) {
        return reservation;
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  bool _cancelled = false;
  bool _cancelling = false;

  static const String author = 'Robert C. Martin';
static const String category = 'Computer Science';
static const String pickupDesk = 'Book Collection Desk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.library,
          builder: (context, _) => Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      _buildBookCard(),
                      const SizedBox(height: 16),
                      _buildReservationInformation(),
                      const SizedBox(height: 16),
                      _buildNotes(),
                      const SizedBox(height: 16),
                      _buildModifyButton(),
                      const SizedBox(height: 12),
                      _buildCancelButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                'Reservation Details',
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
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
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
                Text(
  _reservation?.itemName ?? 'Book',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  author,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  category,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSmallBadge(
                      label: 'Book',
                      backgroundColor: const Color(0xFFEFF6FF),
                      textColor: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    _buildSmallBadge(
                      label: 'Available',
                      backgroundColor: const Color(0xFFE4F5EF),
                      textColor: const Color(0xFF22A06B),
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

  Widget _buildSmallBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReservationInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF2B84B),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reservation Information',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildInformationRow(
            icon: Icons.bookmark_border_rounded,
            label: 'Reservation ID',
            value: widget.reservationId,
          ),
          _buildInformationDivider(),
          _buildInformationRow(
            icon: Icons.calendar_today_outlined,
            label: 'Reservation Date',
            value: _reservation == null
    ? '-'
    : _formatDate(_reservation!.date),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF64748B),
            size: 21,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationDivider() {
    return const Divider(
      height: 1,
      color: Color(0xFFE2E8F0),
    );
  }

  Widget _buildLocationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF64748B),
            size: 21,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Pickup Location',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children:  [
              Text(
                _reservation?.pickupLocation ?? '-',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                pickupDesk,
                style: TextStyle(
                  color: Color(0xFF64748B),
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
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
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
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Color(0xFF172033),
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFB8D3FF),
              ),
            ),
            child: const Text(
              'The book will be held for 3 days from the '
              'reservation date. Please bring your student ID '
              'when collecting the book.',
              style: TextStyle(
                color: Color(0xFF64748B),
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
        icon: const Icon(
          Icons.edit_outlined,
          size: 19,
        ),
        label: const Text(
          'Modify Reservation',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
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
        icon: const Icon(
          Icons.delete_outline_rounded,
          size: 19,
        ),
        label: Text(
          _cancelling
              ? 'Cancelling…'
              : _cancelled
                  ? 'Reservation Cancelled'
                  : 'Cancel Reservation',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE53935),
          disabledForegroundColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: _cancelled
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFE53935),
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Future<void> _modifyReservation() async {
    final reservation = _reservation;
    if (reservation == null) return;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var pickupDate = reservation.date;
        var loanPeriodDays =
            reservation.loanPeriodDays ?? widget.library.settings.loanPeriodDays;
        var pickupLocation =
            reservation.pickupLocation ?? 'Main Library, 3rd Floor';
        const pickupLocations = [
          'Main Library, 3rd Floor',
          'Main Library, 2nd Floor',
          'Main Desk, Floor 1',
          'Main Desk (Floor 1)',
          'Library Collection Desk',
        ];
        if (!pickupLocations.contains(pickupLocation)) {
          pickupLocation = pickupLocations.first;
        }
        var saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDate() async {
              final selected = await showDatePicker(
                context: dialogContext,
                initialDate: pickupDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (selected != null) {
                setDialogState(() => pickupDate = selected);
              }
            }

            Future<void> save() async {
              setDialogState(() => saving = true);
              final result = await widget.library.updateBookReservation(
                reservationId: widget.reservationId,
                pickupDate: pickupDate,
                pickupLocation: pickupLocation,
                loanPeriodDays: loanPeriodDays,
                notes: reservation.note ?? '',
              );
              if (!dialogContext.mounted) return;
              if (result.success) {
                Navigator.of(dialogContext).pop(true);
              } else {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message ?? 'Update failed.')),
                );
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Modify Reservation',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup date',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: saving ? null : selectDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_formatDate(pickupDate)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Loan period',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: loanPeriodDays,
                      items: const [7, 14, 21, 30]
                          .map(
                            (days) => DropdownMenuItem<int>(
                              value: days,
                              child: Text('$days days'),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => loanPeriodDays = value);
                              }
                            },
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pickup location',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: pickupLocation,
                      items: pickupLocations
                          .map(
                            (location) => DropdownMenuItem<String>(
                              value: location,
                              child: Text(location),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => pickupLocation = value);
                              }
                            },
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Updating...' : 'OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
          content: const Text(
            'Are you sure you want to cancel this book reservation?',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Keep Reservation',
                style: TextStyle(
                  color: Color(0xFF2563EB),
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
                final result =
                    await widget.library.cancelReservation(reservation.id);
                if (!mounted) return;

                setState(() {
                  _cancelling = false;
                  if (result.success) _cancelled = true;
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
  return StudentBottomNavigation(
    selectedIndex: 2,
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
}