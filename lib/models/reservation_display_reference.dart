import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Display/search labels only. Database operations always use the original ID.
class ReservationDisplayReference {
  ReservationDisplayReference._();

  static String forId(String id) {
    if (id.isEmpty) return '-';
    if (RegExp(r'^RSV-\d+$').hasMatch(id)) return id;
    // Eight readable characters, avoiding easily confused I, O, 0 and 1.
    const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    var value = BigInt.parse(sha256.convert(utf8.encode(id)).toString().substring(0, 10), radix: 16);
    var code = '';
    for (var i = 0; i < 8; i++) {
      code = alphabet[(value & BigInt.from(31)).toInt()] + code;
      value = value >> 5;
    }
    return 'LIB-$code';
  }

  /// Keep references from earlier receipts searchable after shortening them.
  static String legacyForId(String id) {
    if (id.isEmpty) return '-';
    if (RegExp(r'^RSV-\d+$').hasMatch(id)) return id;
    final code = sha256.convert(utf8.encode(id)).toString().substring(0, 16).toUpperCase();
    return 'LIB-${code.substring(0, 4)}-${code.substring(4, 8)}-${code.substring(8, 12)}-${code.substring(12)}';
  }

  static String searchKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}