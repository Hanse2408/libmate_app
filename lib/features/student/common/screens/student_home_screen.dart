import '../widgets/student_palette.dart';
import '../../../../core/widgets/libmate_logo.dart';
import '../widgets/student_avatar.dart';
import '../widgets/student_notification_button.dart';
import '../../book_reservation/screens/reservation_details_screen.dart';
import '../../seat_booking/screens/seat_reservation_details_screen.dart';
import '../widgets/student_bottom_navigation.dart';
/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';*/
import 'package:flutter/material.dart';

import '../../../../models/reservation.dart' as shared;
import '../../book_reservation/screens/find_books_screen.dart';
import '../../book_reservation/screens/my_reservations_screen.dart';
import '../../seat_booking/screens/seat_booking_screen.dart';
import '../../../../core/services/push_messaging_client.dart';
import '../../notifications/providers/student_push_controller.dart';
import '../../notifications/widgets/in_app_notification_banner.dart';
import '../data/student_library_repository.dart';
import 'profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.createLibrary,
    this.createPushClient,
  });

  /// Creates the student's live library data (Firestore). The home screen
  /// owns it, so its listeners stop when the student signs out.
  final StudentLibraryRepository Function() createLibrary;

  /// Creates the push (FCM) client; null disables push (tests, web).
  final PushMessagingClient Function()? createPushClient;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get primaryBlue => _dark ? const Color(0xFF2495FF) : const Color(0xFF0866FF);
  Color get textDark => _dark ? const Color(0xFFF5F7FF) : const Color(0xFF101638);
  Color get secondaryText => _dark ? const Color(0xFFBACDED) : const Color(0xFF475A80);
  Color get lightBlue => _dark ? const Color(0xFF102D4D) : const Color(0xFFEAF3FF);
  static const Color accentGold = Color(0xFFF2B84B);
  final int _selectedNavIndex = 0;
  late final StudentLibraryRepository _library = widget.createLibrary();
  late final InAppNotificationBanner _banner;
  StudentPushController? _push;

  @override
  void initState() {
    super.initState();
    _banner = InAppNotificationBanner(context: context, library: _library);
    final createPush = widget.createPushClient;
    if (createPush != null) {
      _push = StudentPushController(
        context: context,
        library: _library,
        client: createPush(),
      );
    }
  }

  @override
  void dispose() {
    _push?.dispose();
    _banner.dispose();
    _library.dispose();
    super.dispose();
  }

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  void _openFindBooks() => _open(FindBooksScreen(library: _library));
  void _openSeatBooking() => _open(SeatBookingScreen(library: _library));
  void _openReservations() => _open(MyReservationsScreen(library: _library));

  String get _firstName {
    final name = _library.student.name.trim();
    return name.isEmpty ? 'Student' : name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _library, builder: (context, _) => _buildHome());

  Widget _buildHome() => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: _dark ? const [Color(0xFF04111E), Color(0xFF071827)]
          : const [Color(0xFFFFFFFF), Color(0xFFF7FBFF)],
      )),
      child: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTopBar(), const SizedBox(height: 30),
          _buildGreeting(), const SizedBox(height: 22),
          _buildSearchBar(), const SizedBox(height: 18),
          _buildActionCards(), const SizedBox(height: 26),
          _buildReservationHeader(), const SizedBox(height: 14),
          ..._buildCurrentReservations(), const SizedBox(height: 18),
          _buildReminderCard(),
        ]),
      )),
    ),
    bottomNavigationBar: Theme(
      data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(
        surface: _dark ? const Color(0xFF081B2D) : const Color(0xFFFBFDFF),
        primary: primaryBlue, onSurfaceVariant: secondaryText)),
      child: _buildBottomNavigationBar()),
  );

  Widget _buildTopBar() => Row(children: [
    const LibMateLogo(size: 48),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LibMate', style: TextStyle(color: textDark, fontFamily: 'Georgia',
        fontFamilyFallback: const ['Times New Roman', 'serif'], fontSize: 29, fontWeight: FontWeight.w700, height: 1.1)),
      const SizedBox(height: 4),
      Text('Learn  \u2022  Reserve  \u2022  Belong', maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(color: secondaryText, fontSize: 11)),
    ])),
    StudentNotificationButton(library: _library, color: textDark),
    const SizedBox(width: 4),
    Tooltip(message: 'Profile', child: InkWell(customBorder: const CircleBorder(),
      onTap: () => _open(ProfileScreen(library: _library)),
      child: StudentAvatar(name: _library.student.name, photoUrl: _library.student.photoUrl, size: 42)),
    ),
  ]);

  Widget _buildGreeting() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Good morning,', style: TextStyle(color: secondaryText, fontSize: 16)),
    const SizedBox(height: 3),
    Text('$_firstName!', style: TextStyle(color: textDark, fontFamily: 'Georgia',
      fontFamilyFallback: const ['Times New Roman', 'serif'], fontSize: 38, fontWeight: FontWeight.w700, height: 1.15)),
    const SizedBox(height: 7),
    Text('What would you like to do today?', style: TextStyle(color: secondaryText, fontSize: 15)),
  ]);

  Widget _buildSearchBar() => InkWell(onTap: _openFindBooks, borderRadius: BorderRadius.circular(18),
    child: Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: _dark ? const [Color(0xFF0B2138), Color(0xFF10263D)]
          : const [Color(0xFFF3F8FF), Color(0xFFEEF5FF)]),
        border: Border.all(color: _dark ? const Color(0xFF1A3B5E) : const Color(0xFFCDDEFF))),
      child: Row(children: [
        Icon(Icons.search_rounded, color: textDark, size: 28), const SizedBox(width: 12),
        Expanded(child: Text('Search for books, authors, or topics...', maxLines: 1,
          overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryText, fontSize: 12))),
        const SizedBox(width: 8), Icon(Icons.tune_rounded, color: textDark, size: 25),
      ])),
  );

  Widget _buildActionCards() => IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Expanded(child: _buildActionCard(onTap: _openFindBooks, title: 'Find Books',
      subtitle: 'Check availability', icon: Icons.menu_book_outlined, gold: false)),
    const SizedBox(width: 14),
    Expanded(child: _buildActionCard(onTap: _openSeatBooking, title: 'Book a Seat',
      subtitle: 'Reserve your study space', icon: Icons.event_seat_rounded, gold: true)),
  ]));

  Widget _buildActionCard({required VoidCallback onTap, required String title,
    required String subtitle, required IconData icon, required bool gold}) {
    final tint = gold ? accentGold : primaryBlue;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: Container(constraints: const BoxConstraints(minHeight: 154), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: gold
              ? (_dark ? const [Color(0xFF352E20), Color(0xFF24251F)] : const [Color(0xFFFFF5DE), Color(0xFFFFF9EB)])
              : (_dark ? const [Color(0xFF0B2948), Color(0xFF0B203B)] : const [Color(0xFFE9F2FF), Color(0xFFF0F6FF)])),
          border: Border.all(color: tint.withValues(alpha: _dark ? .55 : .45), width: 1.2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 52, height: 52, alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: gold ? const [Color(0xFFFFD984), Color(0xFFF2B84B)]
                  : (_dark ? const [Color(0xFF2A9DFF), Color(0xFF1464FF)] : const [Color(0xFFD4E6FF), Color(0xFFBED8FF)]))),
            child: Icon(icon, size: 30, color: gold ? const Color(0xFF85500D) : (_dark ? Colors.white : primaryBlue))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: Text(title, style: TextStyle(color: textDark, fontSize: 16,
            fontWeight: FontWeight.w700))), Icon(Icons.chevron_right_rounded, color: textDark, size: 22)]),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(color: secondaryText, fontSize: 12, height: 1.4)),
        ])),
    );
  }

  Widget _buildReservationHeader() => Row(children: [
    Expanded(child: Text('Your Current Reservation', style: TextStyle(color: textDark,
      fontSize: 17, fontWeight: FontWeight.w700))),
    const SizedBox(width: 8),
    TextButton(onPressed: _openReservations,
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('See all', style: TextStyle(color: primaryBlue, fontSize: 14)),
        Icon(Icons.chevron_right_rounded, color: primaryBlue, size: 21),
      ])),
  ]);

  /// The student's next active seat booking and book reservation (live).
  List<Widget> _buildCurrentReservations() {
    final active = _library.myReservations.where((r) => r.isActive).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final seat = active.where((r) => r.type == shared.ReservationType.seat).firstOrNull;
    final book = active.where((r) => r.type == shared.ReservationType.book).firstOrNull;
    if (seat == null && book == null) {
      return [
        Text(
          _library.isLoading ? 'Loading your reservations…' : 'You have no current reservations.',
          style: TextStyle(color: secondaryText, fontSize: 13),
        ),
      ];
    }
    return [
      if (seat != null)
        _buildReservationCard(
          onTap: () => _open(SeatReservationDetailsScreen(library: _library, reservation: seat)),
          icon: Icons.event_seat_rounded,
          iconColor: primaryBlue,
          iconBackground: lightBlue,
          title: 'Reading Room Seat',
          status: seat.isPending ? 'Pending' : 'Confirmed',
          details: [
            '${_formatDate(seat.date)} • ${seat.timeSlot ?? ''}',
            seat.itemName,
          ],
        ),
      if (seat != null && book != null) SizedBox(height: 12),
      if (book != null)
        _buildReservationCard(
          onTap: () => _open(ReservationDetailsScreen(library: _library, reservationId: book.id)),
          icon: Icons.menu_book_rounded,
          iconColor: primaryBlue,
          iconBackground: lightBlue,
          title: 'Book Reservation',
          status: book.isPending ? 'Pending' : 'Confirmed',
          details: [
            book.itemName,
            'pick up from ${_formatDate(book.date)}',
          ],
        ),
    ];
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildReservationCard({required VoidCallback onTap, required IconData icon,
    required Color iconColor, required Color iconBackground, required String title,
    required String status, required List<String> details}) {
    final pending = status == 'Pending';
    final statusColor = pending ? StudentPalette.of(context).goldText : StudentPalette.of(context).success;
    final badge = Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
        color: pending ? StudentPalette.of(context).goldTint : StudentPalette.of(context).successTint),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(pending ? Icons.schedule_rounded : Icons.check_circle_rounded, size: 13, color: statusColor),
        const SizedBox(width: 4), Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
      ]));
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: _dark ? const [Color(0xFF0E2840), Color(0xFF0B1E33)]
              : const [Color(0xFFFFFFFF), Color(0xFFF9FCFF)]),
          border: Border.all(color: _dark ? const Color(0xFF173650) : const Color(0xFFDCE8FF))),
        child: Row(children: [
          Container(width: 54, height: 68, alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 32)),
          const SizedBox(width: 12),
          Expanded(child: LayoutBuilder(builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (constraints.maxWidth >= 240)
                Row(children: [Expanded(child: Text(title, style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14))), badge])
              else ...[
                Text(title, style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6), badge,
              ],
              const SizedBox(height: 9),
              for (int i = 0; i < details.length; i++) Padding(padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(i == 0 ? Icons.calendar_month_outlined : Icons.location_on_outlined, size: 16, color: secondaryText),
                  const SizedBox(width: 7),
                  Expanded(child: Text(details[i], style: TextStyle(color: secondaryText, fontSize: 11, height: 1.4))),
                ])),
            ]))),
          const SizedBox(width: 4), Icon(Icons.chevron_right_rounded, color: secondaryText, size: 22),
        ])),
    );
  }

  Widget _buildReminderCard() => Tooltip(message: 'Always remember to check out of your seat.',
    child: ClipRRect(borderRadius: BorderRadius.circular(18),
      child: Container(width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: _dark ? const [Color(0xFF352F21), Color(0xFF22231E)]
            : const [Color(0xFFFFF4DC), Color(0xFFFFF9EA)])),
        child: Stack(children: [
          Positioned(right: -25, bottom: -44, child: Container(width: 110, height: 110,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accentGold.withValues(alpha: .09)))),
          Positioned(right: 48, bottom: -42, child: Container(width: 85, height: 85,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accentGold.withValues(alpha: .09)))),
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 54, height: 62, alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: accentGold.withValues(alpha: .10), border: Border.all(color: accentGold.withValues(alpha: .14))),
              child: const Icon(Icons.lightbulb_rounded, color: accentGold, size: 35)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('A quieter tomorrow\nstarts with you.', style: TextStyle(color: textDark, fontSize: 16,
                fontWeight: FontWeight.w600, height: 1.4)),
              const SizedBox(height: 5),
              Text('Remember to check out of your seat.', style: TextStyle(color: secondaryText, fontSize: 10)),
            ])),
          ])),
        ])),
    ));

  Widget _buildBottomNavigationBar() {
    return StudentBottomNavigation(
      selectedIndex: _selectedNavIndex,
      onHome: () {},
      onSearch: _openFindBooks,
      onReservations: _openReservations,
      onProfile: () => _open(ProfileScreen(library: _library)),
    );
  }
}