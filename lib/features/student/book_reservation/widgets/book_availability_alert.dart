import 'package:flutter/material.dart';
import '../../common/data/student_library_repository.dart';
import 'reservation_notice.dart';

/// Availability updates only: never claims a copy or changes a reservation.
class BookAvailabilityAlert extends StatefulWidget {
  const BookAvailabilityAlert({super.key, required this.library, required this.bookId});
  final StudentLibraryRepository library;
  final String bookId;

  @override
  State<BookAvailabilityAlert> createState() => _BookAvailabilityAlertState();
}

class _BookAvailabilityAlertState extends State<BookAvailabilityAlert> {
  bool _saving = false;

  Future<void> _toggle(bool enabled) async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await widget.library.setAvailabilityWatch(widget.bookId, enabled);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!result.success) {
      await showReservationNotice(context, title: 'Availability alert',
          message: result.message ?? 'Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.library,
    builder: (context, _) {
      final colors = Theme.of(context).colorScheme;
      final enabled = widget.library.isWatchingAvailability(widget.bookId);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [colors.primary.withValues(alpha: enabled ? .16 : .08),
              const Color(0xFFF2B84B).withValues(alpha: .07)]),
          border: Border.all(color: colors.primary.withValues(alpha: enabled ? .4 : .16)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: colors.surface,
                borderRadius: BorderRadius.circular(15)),
              child: Icon(enabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: colors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(enabled ? 'Your next read is on our radar' : 'Worth the wait?',
              style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          const SizedBox(height: 14),
          Text('We check availability while you use LibMate and when you reopen it. Tap your in-app alert to reserve a copy.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.5, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('Notify me when available',
              style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600))),
            if (_saving) const Padding(padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else Switch.adaptive(value: enabled, onChanged: _toggle),
          ]),
          AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: Text(
            enabled ? 'Alert saved ? You can turn it off anytime' : 'One alert per request ? A copy is not held for you',
            key: ValueKey(enabled),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11))),
        ]),
      );
    },
  );
}
