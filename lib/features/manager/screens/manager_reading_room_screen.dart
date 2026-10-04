import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/manager_mock_data.dart';
import '../widgets/manager_widgets.dart';

class ManagerReadingRoomScreen extends StatefulWidget {
  const ManagerReadingRoomScreen({super.key});

  @override
  State<ManagerReadingRoomScreen> createState() =>
      _ManagerReadingRoomScreenState();
}

class _ManagerReadingRoomScreenState extends State<ManagerReadingRoomScreen> {
  String _floor = 'Floor 1';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final seats = [
      for (final row in ['A', 'B'])
        for (var number = 1; number <= 12; number++)
          '$row${number.toString().padLeft(2, '0')}',
    ];
    return ManagerScaffold(
      title: 'Reading Room',
      currentIndex: 2,
      body: ManagerPagePadding(
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _floor,
              decoration: const InputDecoration(isDense: true),
              items: [
                for (final floor in ['Floor 1', 'Floor 2', 'Floor 3'])
                  DropdownMenuItem(value: floor, child: Text(floor)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _floor = value);
              },
            ),
            const SizedBox(height: 13),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 105,
                      height: 105,
                      child: _OccupancyDonut(),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        children: [
                          const _OccupancyLegend(
                            label: 'Available',
                            value: '38',
                            color: AppColors.success,
                          ),
                          _OccupancyLegend(
                            label: 'Reserved',
                            value: '72',
                            color: primary,
                          ),
                          const _OccupancyLegend(
                            label: 'Conflict',
                            value: '2',
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const SectionHeader(title: 'Seat Map'),
            const SizedBox(height: 9),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: seats.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 7,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    final state = seat == 'B08'
                        ? ManagerSeatState.selected
                        : seat == 'B12'
                        ? ManagerSeatState.conflict
                        : {'A03', 'A10', 'B04', 'B10'}.contains(seat)
                        ? ManagerSeatState.reserved
                        : ManagerSeatState.available;
                    return SeatChip(label: seat, state: state);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 13,
              children: [
                _SeatStatusLegend(color: AppColors.success, label: 'Available'),
                _SeatStatusLegend(color: primary, label: 'Reserved'),
                _SeatStatusLegend(color: AppColors.error, label: 'Conflict'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OccupancyDonut extends StatelessWidget {
  const _OccupancyDonut();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DonutPainter(
      track: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      progress: Theme.of(context).colorScheme.primary,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '68%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        Text(
          'Occupancy',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
        ),
        Text(
          '82 / 120',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
        ),
      ],
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.track, required this.progress});

  final Color track;
  final Color progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    stroke.color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke);
    stroke.color = progress;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.36, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.track != track || oldDelegate.progress != progress;
}

class _OccupancyLegend extends StatelessWidget {
  const _OccupancyLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 10),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _SeatStatusLegend extends StatelessWidget {
  const _SeatStatusLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(radius: 4, backgroundColor: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
      ),
    ],
  );
}
