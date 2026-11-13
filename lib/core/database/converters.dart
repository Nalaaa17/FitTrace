import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores `List<int>` metrics (split paces, HR zone durations, thresholds)
/// as compact JSON strings in SQLite text columns.
class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const <int>[];
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded.map((item) => (item as num).toInt()).toList(growable: false);
  }

  @override
  String toSql(List<int> value) => jsonEncode(value);
}

