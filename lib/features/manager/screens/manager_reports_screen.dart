import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../data/manager_mock_data.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen> {
  int _tab = 0;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 10, 1),
    end: DateTime(2026, 10, 6),
  );
  static const _tabs = managerReportTypes;

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Reports & Analytics',
      currentIndex: 3,
      body: ManagerPagePadding(
        child: ListView(
          children: [
            FilterChipsRow(
              labels: _tabs,
              selectedIndex: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 17, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live figures from the active manager data source',
                      style: const TextStyle(fontSize: 11, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _chooseDateRange,
              icon: const Icon(Icons.calendar_month_outlined, size: 17),
              label: Text(
                '${_dateLabel(_dateRange.start)} - ${_dateLabel(_dateRange.end)}',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.event_note_outlined,
                    title: _tab == 0 ? 'Reservations' : 'Total Records',
                    value: _reportTotal(context),
                    trend: 'Live',
                    trendColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    title: _reportSecondLabel,
                    value: _reportSecondValue(context),
                    trend: 'Live',
                    trendColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: StatCard(
                    icon: Icons.info_outline,
                    title: _reportThirdLabel,
                    value: _reportThirdValue(context),
                    trend: 'Live',
                    trendColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            SectionHeader(title: _tab == 0 ? 'Reservations Trend' : _tabs[_tab]),
            const SizedBox(height: 9),
            if (_tab == 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 11, 7, 9),
                  child: SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ReservationChartPainter(
                        bars: monthlyReservationCounts,
                        labelColor:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            AppColors.secondaryText,
                        barColor: Theme.of(context).colorScheme.primary,
                        gridColor: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
              )
            else
              _ReportList(tab: _tab),
            const SizedBox(height: 15),
            PrimaryButton(
              label: 'Preview / Export Report',
              icon: Icons.visibility_outlined,
              onPressed: () => context.push(
                AppRoutes.managerReportPreview,
                extra: ManagerReportSelection(
                  reportType: _tabs[_tab],
                  startDate: _dateRange.start,
                  endDate: _dateRange.end,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _reportTotal(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    return switch (_tab) {
      5 => '${repository.users.length}',
      1 => '${popularBooks.length}',
      2 => '${overdueBooks.length}',
      6 => '${repository.reservations.where((reservation) => reservation.status == ManagerReservationStatus.conflict).length}',
      _ => '${repository.reservations.length}',
    };
  }

  String get _reportSecondLabel => switch (_tab) {
    1 => 'Top Book',
    2 => 'Reminder',
    3 || 4 => 'Occupied',
    5 => 'Active',
    6 => 'Pending',
    _ => 'Confirmed',
  };

  String _reportSecondValue(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    return switch (_tab) {
      1 => 'Clean Code',
      2 => '12',
      3 || 4 => '84',
      5 => '${repository.users.where((user) => user.isActive).length}',
      6 => '1',
      _ => '${repository.reservations.where((reservation) => reservation.status == ManagerReservationStatus.confirmed).length}',
    };
  }

  String get _reportThirdLabel => switch (_tab) {
    1 => 'Reservations',
    2 => 'Overdue',
    3 || 4 => 'Available',
    5 => 'Inactive',
    6 => 'Resolved',
    _ => 'Pending',
  };

  String _reportThirdValue(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    return switch (_tab) {
      1 => '128',
      2 => '12',
      3 || 4 => '36',
      5 => '${repository.users.where((user) => !user.isActive).length}',
      6 => '1',
      _ => '${repository.reservations.where((reservation) => reservation.status == ManagerReservationStatus.pending).length}',
    };
  }

  Future<void> _chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _dateRange,
    );
    if (range != null && mounted) setState(() => _dateRange = range);
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
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
  ][month - 1];
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.tab});

  final int tab;

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    final items = switch (tab) {
      1 => popularBooks,
      2 => overdueBooks,
      5 => [
        for (final user in repository.users)
          (user.name, '${user.role} · ${user.status}'),
      ],
      6 => const [
        ('Seat B12 · 10:00 AM', 'Reservation conflict · Pending'),
        ('Seat C04 · 11:00 AM', 'Reservation conflict · Resolved'),
      ],
      3 || 4 => const [
        ('Ground Floor', '84 occupied · 36 available'),
        ('Peak time', '10:00 AM - 12:00 PM'),
      ],
      _ => const <(String, String)>[],
    };
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Card(
            child: ListTile(
              leading: Icon(
                tab == 1
                    ? Icons.menu_book_outlined
                    : tab == 5
                    ? Icons.person_outline
                    : tab == 3 || tab == 4
                    ? Icons.event_seat_outlined
                    : Icons.warning_amber_rounded,
                color: tab == 1
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.gold,
              ),
              title: Text(items[i].$1, style: const TextStyle(fontSize: 12)),
              subtitle: Text(items[i].$2, style: const TextStyle(fontSize: 10)),
              trailing: Text(
                '${i + 1}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReservationChartPainter extends CustomPainter {
  const _ReservationChartPainter({
    required this.bars,
    required this.labelColor,
    required this.barColor,
    required this.gridColor,
  });

  final List<int> bars;
  final Color labelColor;
  final Color barColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0;
    const right = 5.0;
    const top = 8.0;
    const bottom = 30.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 0.7;
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    for (var tick = 0; tick <= 50; tick += 10) {
      final y = top + height - height * tick / 50;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
      _drawLabel(canvas, '$tick', Offset(2, y - 6), 9);
    }

    final slot = width / bars.length;
    final barWidth = slot * 0.58;
    for (var i = 0; i < bars.length; i++) {
      final barHeight = height * bars[i] / 50;
      final x = left + slot * i + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top + height - barHeight, barWidth, barHeight),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }

    const dateLabels = ['1 Oct', '5 Oct', '10 Oct', '15 Oct', '20 Oct', '31 Oct'];
    for (var i = 0; i < dateLabels.length; i++) {
      final x = left + width * i / (dateLabels.length - 1) - 11;
      _drawLabel(canvas, dateLabels[i], Offset(x, size.height - 20), 8);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ReservationChartPainter oldDelegate) =>
      oldDelegate.bars != bars ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.barColor != barColor ||
      oldDelegate.gridColor != gridColor;
}
