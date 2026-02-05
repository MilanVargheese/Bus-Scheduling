import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/schedule_result.dart';
import 'api_client.dart';

class PredictionScheduleException implements Exception {
  final String message;

  PredictionScheduleException(this.message);

  @override
  String toString() => message;
}

class PredictionScheduleService {
  static Future<ScheduleResult> uploadAndSchedule(
    File file, {
    int capacity = 100,
    List<int> currentBuses = const [],
  }) async {
    return _uploadForPredictSchedule(
      file,
      capacity: capacity,
      currentBuses: currentBuses,
    );
  }

  static Future<Map<String, dynamic>> uploadAndPredict({
    required String filePath,
    int capacity = 100,
    List<int> currentBuses = const [],
    String? scheduleFilePath,
  }) async {
    try {
      final currentBusesQuery =
          (currentBuses.isNotEmpty &&
              (scheduleFilePath == null || scheduleFilePath.isEmpty))
          ? "&current_buses=${currentBuses.join(',')}"
          : "";
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(
          "${ApiClient.baseUrl}/v1/predict-schedule?capacity=$capacity$currentBusesQuery",
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
          contentType: MediaType("text", "csv"),
        ),
      );

      if (scheduleFilePath != null && scheduleFilePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "schedule_file",
            scheduleFilePath,
            contentType: MediaType("text", "csv"),
          ),
        );
      }

      final response = await ApiClient.sendWithTimeout(request);
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw PredictionScheduleException(
          "Prediction scheduling failed: ${_safeMessage(body)}",
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw PredictionScheduleException(
          "Unexpected prediction scheduling response.",
        );
      }

      return decoded;
    } on TimeoutException {
      throw PredictionScheduleException(
        "Prediction scheduling request timed out.",
      );
    } on FormatException {
      throw PredictionScheduleException(
        "Invalid prediction scheduling response format.",
      );
    } on SocketException {
      throw PredictionScheduleException(
        "Network error during prediction scheduling.",
      );
    }
  }

  static Future<ScheduleResult> _uploadForPredictSchedule(
    File file, {
    required int capacity,
    required List<int> currentBuses,
  }) async {
    try {
      final currentBusesQuery = currentBuses.isNotEmpty
          ? "&current_buses=${currentBuses.join(',')}"
          : "";
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(
          "${ApiClient.baseUrl}/v1/predict-schedule?capacity=$capacity$currentBusesQuery",
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
          contentType: MediaType("text", "csv"),
        ),
      );

      final response = await ApiClient.sendWithTimeout(request);
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw PredictionScheduleException(
          "Prediction scheduling failed: ${_safeMessage(body)}",
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw PredictionScheduleException(
          "Unexpected prediction scheduling response.",
        );
      }

      final scheduleJson = decoded["schedule"];
      if (scheduleJson is! Map<String, dynamic>) {
        throw PredictionScheduleException("Schedule response missing.");
      }

      return ScheduleResult.fromJson(scheduleJson);
    } on TimeoutException {
      throw PredictionScheduleException(
        "Prediction scheduling request timed out.",
      );
    } on FormatException {
      throw PredictionScheduleException(
        "Invalid prediction scheduling response format.",
      );
    } on SocketException {
      throw PredictionScheduleException(
        "Network error during prediction scheduling.",
      );
    }
  }

  static String _safeMessage(String body) {
    if (body.trim().isEmpty) {
      return "No details";
    }

    if (body.length > 300) {
      return "${body.substring(0, 300)}...";
    }

    return body;
  }
}
