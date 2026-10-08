import 'package:flutter/material.dart';
import '../data/student_library_repository.dart';
import '../../notifications/screens/student_notifications_screen.dart';

class StudentNotificationButton extends StatelessWidget {
  const StudentNotificationButton({super.key, required this.library, this.color});
  final StudentLibraryRepository library;
  final Color? color;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => StudentNotificationsScreen(library: library))),
      icon: Badge(isLabelVisible: library.unreadNotificationCount > 0,
        backgroundColor: const Color(0xFFDC4C4C),
        label: Text(library.unreadNotificationCount > 99 ? '99+' : '${library.unreadNotificationCount}'),
        child: Icon(Icons.notifications_none_rounded, size: 27,
          color: color ?? Theme.of(context).colorScheme.onSurface)),
    ),
  );
}
