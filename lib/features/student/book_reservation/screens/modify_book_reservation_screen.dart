import '../../common/widgets/student_palette.dart';
import '../../../../core/constants/book_pickup_locations.dart';
import '../widgets/reservation_notice.dart';
import '../../../../models/book.dart';
import '../../../../models/reservation.dart' as shared;
import '../../common/widgets/student_book_cover.dart';
import 'package:flutter/material.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/widgets/student_bottom_navigation.dart';
import '../../common/data/student_library_repository.dart';
import 'find_books_screen.dart';
import 'my_reservations_screen.dart';
class ModifyBookReservationScreen extends StatefulWidget {
const ModifyBookReservationScreen({
  super.key,
  required this.library,
  required this.reservationId,
});

final StudentLibraryRepository library;
final String reservationId;

  @override
  State<ModifyBookReservationScreen> createState() =>
      _ModifyBookReservationScreenState();
}

class _ModifyBookReservationScreenState
    extends State<ModifyBookReservationScreen> {
late DateTime _reservationDate;
late String _pickupLocation;
late int _loanPeriodDays;

  final TextEditingController _notesController = TextEditingController();

  shared.ReservationRecord? get _reservation {
    for (final reservation in widget.library.myReservations) {
      if (reservation.id == widget.reservationId) return reservation;
    }
    return null;
  }

  BookRecord? get _book {
    final reservation = _reservation;
    return reservation == null ? null : widget.library.bookById(reservation.itemId);
  }

  void _refreshBookData() {
    if (mounted) setState(() {});
  }
  List<String> get _pickupLocations => BookPickupLocations.including(_pickupLocation);

  @override
void initState() {
  super.initState();

  final reservation = widget.library.myReservations.firstWhere(
    (r) => r.id == widget.reservationId,
  );

  _notesController.text = reservation.note ?? '';
  widget.library.addListener(_refreshBookData);
  _reservationDate = reservation.date;
  _loanPeriodDays = reservation.loanPeriodDays ?? widget.library.settings.loanPeriodDays;
  _pickupLocation =
      reservation.pickupLocation ?? BookPickupLocations.defaultLocation;
}

  @override
  void dispose() {
    widget.library.removeListener(_refreshBookData);
    _notesController.dispose();
    super.dispose();
  }

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
                    SizedBox(height: 16),
                    _buildChangeSchedule(),
                    SizedBox(height: 16),
                    _buildImportantNotice(),
                    SizedBox(height: 16),
                    _buildConfirmButton(),
                    SizedBox(height: 12),
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
      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          _buildBackButton(),
          Expanded(
            child: Center(
              child: Text(
                'Modify Reservation',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
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
          color: StudentPalette.of(context).border,
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
      padding: EdgeInsets.fromLTRB(24, 7, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: StudentPalette.of(context).cardGradient,
        boxShadow: StudentPalette.of(context).cardShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudentPalette.of(context).goldBorder,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _book?.author.trim().isNotEmpty == true ? _book!.author : 'Author unavailable',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _book?.category.trim().isNotEmpty == true ? _book!.category : 'Category unavailable',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 7),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: StudentPalette.of(context).blueTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _book?.stock.label ?? 'Book unavailable',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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
    return StudentBookCover(
      title: _book?.title ?? _reservation?.itemName ?? 'Book',
      author: _book?.author ?? '',
      imageUrl: _book?.coverAsset,
      width: 92,
      height: 126,
      radius: 7,
    );
  }
  Widget _buildChangeSchedule() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 17, 16, 10),
      decoration: BoxDecoration(
        color: StudentPalette.of(context).card,
        gradient: StudentPalette.of(context).cardGradient,
        boxShadow: StudentPalette.of(context).cardShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudentPalette.of(context).blueBorder,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Schedule',
            style: TextStyle(
              color: StudentPalette.of(context).text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Reservation Date',
            style: TextStyle(
              color: StudentPalette.of(context).muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          _buildDateField(),
          SizedBox(height: 14),
          Text(
            'Pickup Location',
            style: TextStyle(
              color: StudentPalette.of(context).muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          _buildLocationField(),
          SizedBox(height: 14),
          Text(
            'Loan Period',
            style: TextStyle(
              color: StudentPalette.of(context).muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          _buildLoanPeriodField(),
          SizedBox(height: 14),
          Text(
            'Additional Notes',
            style: TextStyle(
              color: StudentPalette.of(context).muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
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
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: StudentPalette.of(context).field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: StudentPalette.of(context).border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: StudentPalette.of(context).muted,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatDate(_reservationDate),
                style: TextStyle(
                  color: StudentPalette.of(context).text,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: StudentPalette.of(context).muted,
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
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: StudentPalette.of(context).field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: StudentPalette.of(context).border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: StudentPalette.of(context).muted,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _pickupLocation,
                style: TextStyle(
                  color: StudentPalette.of(context).text,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: StudentPalette.of(context).muted,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanPeriodField() {
    final periods = {7, 14, 21, 30, _loanPeriodDays}.toList()..sort();
    return DropdownButtonFormField<int>(
      initialValue: _loanPeriodDays,
      isExpanded: true,
      style: TextStyle(color: StudentPalette.of(context).text, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.schedule_outlined, color: StudentPalette.of(context).muted),
        filled: true,
        fillColor: StudentPalette.of(context).field,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: StudentPalette.of(context).border),
        ),
      ),
      items: [
        for (final days in periods)
          DropdownMenuItem(value: days, child: Text('$days Days')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _loanPeriodDays = value);
      },
    );
  }
  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      style: TextStyle(
        color: StudentPalette.of(context).text,
        fontSize: 13,
        height: 1.4,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: StudentPalette.of(context).field,
        contentPadding: EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: StudentPalette.of(context).border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: StudentPalette.of(context).border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: StudentPalette.of(context).primary,
          ),
        ),
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: StudentPalette.of(context).blueTint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: StudentPalette.of(context).blueBorder,
        ),
      ),
      child: Text(
        'Important: Holds are limited to 3 days maximum from the '
        'selected pickup date.',
        style: TextStyle(
          color: StudentPalette.of(context).muted,
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
        icon: Icon(
          Icons.check_rounded,
          size: 19,
        ),
        label: Text(
          'Confirm & Update',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: StudentPalette.of(context).primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: StudentPalette.of(context).error,
          side: BorderSide(
            color: StudentPalette.of(context).error,
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(
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
          data: Theme.of(context),
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
      backgroundColor: StudentPalette.of(context).card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: StudentPalette.of(context).border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Select Pickup Location',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              ..._pickupLocations.map(
                (location) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    location,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  trailing: location == _pickupLocation
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
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

  Future<void> _confirmUpdate() async {
  if (_reservation?.status == shared.ReservationStatus.approved) {
    showReservationNotice(context, message: 'Approved book reservations cannot be modified.');
    return;
  }
  final result = await widget.library.updateBookReservation(
    reservationId: widget.reservationId,
    pickupDate: _reservationDate,
    pickupLocation: _pickupLocation,
    loanPeriodDays: _loanPeriodDays,
    notes: _notesController.text,
  );

  if (!mounted) return;

  if (!result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message!),
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'Reservation Updated',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Your reservation has been updated.\n\n'
          'Date: ${_formatDate(_reservationDate)}\n'
          'Pickup: $_pickupLocation\n'
          'Notes: ${_notesController.text}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: StudentPalette.of(context).primary,
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