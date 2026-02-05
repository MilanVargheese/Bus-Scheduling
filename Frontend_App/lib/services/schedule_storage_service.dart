import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ScheduleStorageService {
  static const String _scheduleKey = 'current_schedule_upload';

  Future<void> saveScheduleUpload({
    required String fileName,
    required String filePath,
    required List<Map<String, dynamic>> rows,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'fileName': fileName,
      'filePath': filePath,
      'uploadedAt': DateTime.now().toIso8601String(),
      'rows': rows,
    };
    await prefs.setString(_scheduleKey, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> loadLastScheduleUpload() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scheduleKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  List<int> extractCurrentBuses(Map<String, dynamic>? payload) {
    if (payload == null) return [];
    final rows = payload['rows'];
    if (rows is! List) return [];

    final List<int> buses = [];
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        final normalized = <String, dynamic>{};
        for (final entry in row.entries) {
          final key = entry.key.toString().toLowerCase().replaceAll(' ', '_');
          normalized[key] = entry.value;
        }

        final value =
            normalized['current_buses'] ??
            normalized['current_bus'] ??
            normalized['bus_count'] ??
            normalized['num_buses'] ??
            normalized['buses_required'] ??
            normalized['buses'] ??
            normalized['buses_assigned'];
        final parsed = int.tryParse(value?.toString() ?? '');
        if (parsed != null) {
          buses.add(parsed);
        }
      }
    }

    return buses;
  }
}
