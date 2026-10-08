import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/seat.dart';
import '../providers/manager_scope.dart';
import '../widgets/manager_widgets.dart';

class ManagerReadingRoomScreen extends StatefulWidget {
  const ManagerReadingRoomScreen({super.key});
  @override
  State<ManagerReadingRoomScreen> createState() =>
      _ManagerReadingRoomScreenState();
}

class _ManagerReadingRoomScreenState extends State<ManagerReadingRoomScreen> {
  String _room = 'All rooms';

  @override
  Widget build(BuildContext context) {
    final repository = ManagerScope.of(context).repository;
    if (repository.seatsError != null ||
        repository.seatsLoading ||
        repository.seats.isEmpty) {
      return ManagerScaffold(
        title: 'Reading Room Monitoring',
        currentIndex: 2,
        body: Center(
          child: repository.seatsError != null
              ? Text(repository.seatsError!)
              : repository.seatsLoading
              ? const CircularProgressIndicator()
              : const Text('No seat data available'),
        ),
      );
    }
    final rooms =
        repository.seats
            .map((s) => s.readingRoom)
            .where((r) => r.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final room = rooms.contains(_room) ? _room : 'All rooms';
    final seats = repository.seats
        .where((s) => room == 'All rooms' || s.readingRoom == room)
        .toList();
    final now = repository.monitoringTime;
    final statuses = {
      for (final seat in seats) seat.id: repository.seatStatus(seat, at: now),
    };
    int count(SeatStatus status) =>
        statuses.values.where((s) => s == status).length;
    final available = count(SeatStatus.available);
    final reserved = count(SeatStatus.reserved);
    final occupied = count(SeatStatus.occupied);
    final maintenance = count(SeatStatus.maintenance);
    final total = seats.length;
    final rate = total == 0 ? 0.0 : (reserved + occupied) / total;
    final primary = Theme.of(context).colorScheme.primary;

    return ManagerScaffold(
      title: 'Reading Room Monitoring',
      currentIndex: 2,
      body: ManagerPagePadding(
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(room),
              initialValue: room,
              decoration: const InputDecoration(
                labelText: 'Reading room',
                isDense: true,
              ),
              items: [
                for (final name in ['All rooms', ...rooms])
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _room = value);
              },
            ),
            const SizedBox(height: 13),
            Text(
              'Current availability ? ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 105,
                      height: 105,
                      child: _OccupancyDonut(
                        percent: (rate * 100).round(),
                        value: rate,
                        summaryText: '${reserved + occupied} / $total',
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        children: [
                          _OccupancyLegend(
                            label: 'Total seats',
                            value: '$total',
                            color: primary,
                          ),
                          _OccupancyLegend(
                            label: 'Available',
                            value: '$available',
                            color: AppColors.success,
                          ),
                          _OccupancyLegend(
                            label: 'Reserved',
                            value: '$reserved',
                            color: primary,
                          ),
                          _OccupancyLegend(
                            label: 'Occupied',
                            value: '$occupied',
                            color: AppColors.error,
                          ),
                          if (maintenance > 0)
                            _OccupancyLegend(
                              label: 'Maintenance',
                              value: '$maintenance',
                              color: AppColors.secondaryText,
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
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 7,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    final status = statuses[seat.id]!;
                    final color = switch (status) {
                      SeatStatus.available => AppColors.success,
                      SeatStatus.reserved => primary,
                      SeatStatus.occupied => AppColors.error,
                      SeatStatus.maintenance => AppColors.secondaryText,
                    };
                    return InkWell(
                      onTap: () => _showSeat(context, seat.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              seat.seatNumber.isEmpty
                                  ? seat.id
                                  : seat.seatNumber,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              status.label,
                              style: TextStyle(color: color, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
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
                _SeatStatusLegend(color: AppColors.error, label: 'Occupied'),
                _SeatStatusLegend(
                  color: AppColors.secondaryText,
                  label: 'Maintenance',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSeat(BuildContext context, String id) {
    final repository = ManagerScope.read(context).repository;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final matches = repository.seats.where((seat) => seat.id == id);
          final seat = matches.isEmpty ? null : matches.first;
          return AlertDialog(
            title: Text(
              seat == null
                  ? 'Seat not found'
                  : 'Seat ${seat.seatNumber.isEmpty ? seat.id : seat.seatNumber}',
            ),
            content: Text(
              repository.seatsError ??
                  (seat == null
                      ? 'This seat is no longer available.'
                      : '${seat.readingRoom} ? ${seat.zone} ? ${repository.seatStatus(seat).label}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OccupancyDonut extends StatelessWidget {
  const _OccupancyDonut({
    required this.percent,
    required this.value,
    required this.summaryText,
  });

  final int percent;
  final double value;
  final String summaryText;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DonutPainter(
      track: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      progress: Theme.of(context).colorScheme.primary,
      value: value,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        Text(
          'Occupancy',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
        ),
        Text(
          summaryText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
        ),
      ],
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.track,
    required this.progress,
    required this.value,
  });

  final Color track;
  final Color progress;
  final double value;

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
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.progress != progress ||
      oldDelegate.value != value;
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
