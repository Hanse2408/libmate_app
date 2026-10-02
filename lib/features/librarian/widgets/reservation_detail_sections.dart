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
        style: const TextStyle(
          color: LibrarianColors.secondaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StudentInfoCard extends StatelessWidget {
  const StudentInfoCard({super.key, required this.reservation});

  final ReservationRecord reservation;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: 'Student Information',
      children: [
        InfoGrid(
          items: [
            InfoItem('Name', reservation.studentName),
            InfoItem('Student ID', reservation.studentId),
            InfoItem('Contact', reservation.studentEmail, wide: true),
          ],
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
          style: const TextStyle(
            color: LibrarianColors.secondaryText,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
