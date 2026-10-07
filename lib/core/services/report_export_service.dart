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
          rows.add([
            user.name,
            user.email,
            user.role,
            user.status,
            user.id,
          ]);
        }
        break;
      case 'Reservations':
        rows.add(['reservationId', 'book', 'student', 'studentId', 'date', 'time', 'status', 'seat']);
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
        rows.add(['reservationId', 'book', 'student', 'studentId', 'date', 'time', 'status', 'seat']);
        for (final reservation in activeRepository.reservations.where(
          (reservation) => reservation.status == ManagerReservationStatus.conflict,
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
        for (final book in popularBooks) {
          rows.add([book.$1, book.$2]);
        }
        break;
      case 'Overdue Books':
        rows.add(['title', 'details']);
        for (final book in overdueBooks) {
          rows.add([book.$1, book.$2]);
        }
        break;
      default:
        rows.add(['reportType', 'value']);
        rows.add([reportType, 'No rows available']);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }
    return buffer.toString();
  }

  static String _escapeCsvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
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
