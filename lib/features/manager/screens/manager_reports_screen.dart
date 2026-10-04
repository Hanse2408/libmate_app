import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/manager_mock_data.dart';
import '../widgets/manager_widgets.dart';

class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen> {
  int _tab = 0;
  static const _tabs = ['Reservations', 'Popular Books', 'Overdue'];

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
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 17,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('This Month', style: TextStyle(fontSize: 11)),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.event_note_outlined,
                    title: 'Total Reservations',
                    value: '642',
                    trend: '+12%',
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    title: 'Completed',
                    value: '580',
                    trend: '+8%',
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: StatCard(
                    icon: Icons.cancel_outlined,
                    title: 'Cancelled',
                    value: '62',
                    trend: '-5%',
                    trendColor: AppColors.error,
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
              label: 'Export Report',
              icon: Icons.file_download_outlined,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report exported (demo)')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.tab});

  final int tab;

  @override
  Widget build(BuildContext context) {
    final items = tab == 1 ? popularBooks : overdueBooks;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Card(
            child: ListTile(
              leading: Icon(
                tab == 1 ? Icons.menu_book_outlined : Icons.warning_amber_rounded,
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
