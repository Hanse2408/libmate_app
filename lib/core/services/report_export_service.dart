import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'report_export_service_web.dart'
    if (dart.library.io) 'report_export_service_stub.dart';

import '../../features/manager/data/manager_mock_data.dart';
import '../../features/manager/data/manager_repository.dart';

class ReportExportService {
  const ReportExportService._();

  static String generateCsv(
    ManagerReportSelection selection, {
    ManagerRepository? repository,
  }) {
    final activeRepository = repository ?? ManagerMockRepository.instance;
    final rows = <List<String>>[];
    final reportType = selection.reportType;

    switch (reportType) {
      case 'Users':
        rows.add(['name', 'email', 'role', 'status', 'id']);
        for (final user in activeRepository.users) {
          rows.add([user.name, user.email, user.role, user.status, user.id]);
        }
        break;
      case 'Reservations':
        rows.add([
          'reservationId',
          'book',
          'student',
          'studentId',
          'date',
          'time',
          'status',
          'seat',
        ]);
        for (final reservation in activeRepository.reservations) {
          rows.add([
            reservation.id,
            reservation.book,
            reservation.student,
            reservation.studentId,
            reservation.date,
            reservation.time,
            reservation.status.name,
            reservation.seat,
          ]);
        }
        break;
      case 'Conflicts':
        rows.add([
          'reservationId',
          'book',
          'student',
          'studentId',
          'date',
          'time',
          'status',
          'seat',
        ]);
        for (final reservation in activeRepository.reservations.where(
          (reservation) =>
              reservation.status == ManagerReservationStatus.conflict,
        )) {
          rows.add([
            reservation.id,
            reservation.book,
            reservation.student,
            reservation.studentId,
            reservation.date,
            reservation.time,
            reservation.status.name,
            reservation.seat,
          ]);
        }
        break;
      case 'Popular Books':
        rows.add(['title', 'reservations']);
        final popular = _popularBooksByReservation(
          activeRepository.reservations,
        );
        if (popular.isEmpty) {
          rows.add(['No live book data', '0 reservations']);
        } else {
          for (final entry in popular) {
            rows.add([entry.key, '${entry.value} reservations']);
          }
        }
        break;
      case 'Overdue Books':
        rows.add(['title', 'details']);
        final attention = _attentionReservations(activeRepository.reservations);
        if (attention.isEmpty) {
          rows.add([
            'No overdue data',
            'No pending or conflicted reservations',
          ]);
        } else {
          for (final item in attention) {
            rows.add([item.$1, item.$2]);
          }
        }
        break;
      default:
        rows.add(['reportType', 'value']);
        rows.add([reportType, 'No live rows available']);
    }

    if (rows.length == 1) {
      rows.add(['No data available', '0']);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }
    return buffer.toString();
  }

  static List<MapEntry<String, int>> _popularBooksByReservation(
    List<ManagerReservation> reservations,
  ) {
    final counts = <String, int>{};
    for (final reservation in reservations) {
      final title = reservation.book.trim();
      if (title.isEmpty) continue;
      counts.update(title, (value) => value + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  static List<(String, String)> _attentionReservations(
    List<ManagerReservation> reservations,
  ) {
    final candidates = reservations.where(
      (reservation) =>
          reservation.status == ManagerReservationStatus.pending ||
          reservation.status == ManagerReservationStatus.conflict,
    );
    final rows = <(String, String)>[];
    for (final reservation in candidates) {
      rows.add((
        reservation.book,
        '${reservation.student} • ${reservation.status.name} • ${reservation.seat}',
      ));
    }
    return rows;
  }

  static String _escapeCsvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  static Future<String?> saveCsv(
    ManagerReportSelection selection, {
    ManagerRepository? repository,
  }) async {
    final csv = generateCsv(selection, repository: repository);
    final suggestedName =
        'libmate_${selection.reportType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      triggerWebCsvDownload(csv, suggestedName);
      return suggestedName;
    }

    final saveLocation = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );

    if (saveLocation == null) {
      return null;
    }

    final file = File(saveLocation.path);
    await file.writeAsString(csv);
    return saveLocation.path;
  }

  static Future<void> openReportUrl(String filePath) async {
    if (kIsWeb) {
      return;
    }
    final file = File(filePath);
    if (!await file.exists()) {
      return;
    }
  }
}
