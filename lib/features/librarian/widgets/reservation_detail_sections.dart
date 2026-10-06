import 'package:flutter/material.dart';

import '../models/reservation_record.dart';
import '../theme/librarian_theme.dart';
import 'info_grid.dart';
import 'info_section_card.dart';

/// Sections shared by the Book and Seat Reservation Details screens.

/// The "#RSV-1001" reference line under the page header.
class ReservationReference extends StatelessWidget {
  const ReservationReference({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LibrarianSpacing.sm + 4),
      child: Text(
        '#$reservationId',
        style: TextStyle(
          color: LibrarianColors.secondaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StudentInfoCard extends StatelessWidget {
  const StudentInfoCard({
    super.key,
    required this.name,
    required this.studentId,
    required this.email,
    this.title = 'Student Information',
    this.onViewMember,
  });

  StudentInfoCard.fromReservation(ReservationRecord reservation, {Key? key, VoidCallback? onViewMember})
    : this(
        key: key,
        name: reservation.studentName,
        studentId: reservation.studentId,
        email: reservation.studentEmail,
        onViewMember: onViewMember,
      );

  final String name;
  final String studentId;
  final String email;
  final String title;

  /// Shows a "View member" link to Member Details when set.
  final VoidCallback? onViewMember;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: title,
      children: [
        InfoGrid(
          items: [
            InfoItem('Name', name),
            InfoItem('Student ID', studentId),
            InfoItem('Contact', email, wide: true),
          ],
        ),
        if (onViewMember != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onViewMember,
              icon: const Icon(Icons.person_outline),
              label: const Text('View member'),
            ),
          ),
      ],
    );
  }
}

class AdditionalInfoCard extends StatelessWidget {
  const AdditionalInfoCard({super.key, required this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note!.trim().isNotEmpty;

    return InfoSectionCard(
      title: 'Additional Information',
      children: [
        Text(
          hasNote ? note! : 'No additional notes from the student.',
          style: TextStyle(
            color: LibrarianColors.secondaryText,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
