import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';

class PredictionService {
  static Future<http.StreamedResponse> uploadCsv(File file) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiClient.baseUrl}/v1/predict"),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        "file", // ✅ must match backend
        file.path,
        contentType: MediaType("text", "csv"),
      ),
    );

    return ApiClient.sendWithTimeout(request);
  }
}
