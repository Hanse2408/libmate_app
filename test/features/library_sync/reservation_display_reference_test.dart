import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/models/reservation.dart';
import 'package:libmate_app/models/reservation_display_reference.dart';
import 'package:libmate_app/features/librarian/providers/reservation_filter.dart';

void main() {
  test('reference is stable across loading and status changes without changing database identity', () {
    final record = ReservationRecord.fromMap('aB3dE5fG7hI9jK1lM2nO', {});
    final reference = record.displayReference;
    expect(reference, matches(RegExp(r'^LIB-[2-9A-HJ-NP-Z]{8}$')));
    expect(record.copyWith(status: ReservationStatus.cancelled).displayReference, reference);
    expect(ReservationRecord.fromMap(record.id, record.toMap()..remove('requestedAt')..remove('updatedAt')).displayReference, reference);
    expect(record.id, 'aB3dE5fG7hI9jK1lM2nO');
    expect(ReservationDisplayReference.forId(record.id.toLowerCase()), isNot(reference));
    expect(ReservationDisplayReference.forId('RSV-1001'), 'RSV-1001');
    expect(ReservationDisplayReference.forId(''), '-');
  });

  test('librarian finds the original record using displayed, unformatted or original reference', () {
    final records = [
      ReservationRecord.fromMap('aB3dE5fG7hI9jK1lM2nO', {}),
      ReservationRecord.fromMap('different-document-id', {}),
    ];
    for (final query in [records.first.displayReference, ReservationDisplayReference.legacyForId(records.first.id),
      records.first.displayReference.toLowerCase().replaceAll('-', ''),
      '#${records.first.displayReference}', records.first.id]) {
      expect(ReservationFilter(query: query).apply(records).map((r) => r.id), [records.first.id]);
    }
  });
}