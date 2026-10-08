import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/student_loan.dart';
import '../../../../models/reservation_display_reference.dart';
import '../../common/data/student_library_repository.dart';
import '../../common/widgets/student_palette.dart';
import '../../common/widgets/student_book_cover.dart';
import 'book_details_screen.dart';

/// Current loans from the librarian. Estimates do not represent payment records.
class BorrowedBooksScreen extends StatefulWidget {
  const BorrowedBooksScreen({super.key, required this.library});
  final StudentLibraryRepository library;
  @override
  State<BorrowedBooksScreen> createState() => _BorrowedBooksScreenState();
}

class _BorrowedBooksScreenState extends State<BorrowedBooksScreen>
    with WidgetsBindingObserver {
  Timer? _dayTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _dayTimer?.cancel();
    final now = DateTime.now();
    _dayTimer = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleMidnight();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleMidnight();
    }
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _date(DateTime? date) {
    if (date == null) return 'Unavailable';
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

  @override
  Widget build(BuildContext context) {
    final colors = StudentPalette.of(context);
    final library = widget.library;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Borrowed Books'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final loans = library.borrowedBooks;
          if (library.isLoading && loans.isEmpty)
            return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: colors.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.blueBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loans.length} currently borrowed',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 22,
                        letterSpacing: -.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Overdue rate: Rs. ${library.settings.dailyFineRate} per day',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fines are estimates from the day after the due date. Payments are not tracked here.',
                      style: TextStyle(
                        color: colors.muted,
                        height: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (library.loadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    library.loadError!,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              if (loans.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 48,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'You have no borrowed books right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              for (final loan in loans) ...[
                const SizedBox(height: 16),
                _loanCard(loan, colors),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _loanCard(StudentLoan loan, StudentPalette colors) {
    final now = DateTime.now();
    final days = loan.daysOverdueOn(now);
    final due = loan.dueDate;
    final dueToday =
        due != null &&
        due.year == now.year &&
        due.month == now.month &&
        due.day == now.day;
    final overdue = days != null && days > 0;
    final accent = overdue
        ? colors.error
        : dueToday
        ? colors.goldText
        : colors.primary;
    final status = days == null
        ? 'Due date unavailable'
        : overdue
        ? '$days day${days == 1 ? '' : 's'} overdue'
        : dueToday
        ? 'Due today'
        : 'On loan';
    final book = widget.library.bookById(loan.bookId);
    final fine = loan.estimatedFineOn(
      now,
      dailyRate: widget.library.settings.dailyFineRate,
    );
    return Material(
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withValues(alpha: .3)),
      ),
      child: InkWell(
        onTap: book == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BookDetailsScreen(
                    library: widget.library,
                    bookId: loan.bookId,
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentBookCover(
                    title: loan.bookTitle,
                    author: book?.author ?? '',
                    imageUrl: book?.coverAsset,
                    width: 62,
                    height: 88,
                    fit: BoxFit.contain,
                    radius: 9,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.bookTitle,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (book?.author.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            book!.author,
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detail('Borrowed on', _date(loan.issuedAt), colors),
              _detail('Due date', _date(loan.dueDate), colors),
              if (loan.reservationId?.isNotEmpty == true)
                _detail(
                  'Reservation',
                  ReservationDisplayReference.forId(loan.reservationId!),
                  colors,
                ),
              const SizedBox(height: 8),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Estimated fine',
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                  Text(
                    fine == null ? 'Unavailable' : 'Rs. $fine',
                    style: TextStyle(
                      color: overdue ? colors.error : colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value, StudentPalette colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
