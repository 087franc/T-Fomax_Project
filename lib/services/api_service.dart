import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://mw.telkomcel.tl/app/tfomax";

  // Private constructor
  ApiService._internal();

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  // Factory constructor
  factory ApiService() {
    return _instance;
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token') ?? "";
    return {
      "Content-Type": "application/json; charset=UTF-8",
      "Accept": "application/json",
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse("$baseUrl$endpoint");
    return await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    final url = Uri.parse("$baseUrl$endpoint");
    return await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> patch(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    final url = Uri.parse("$baseUrl$endpoint");
    return await http
        .patch(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse("$baseUrl$endpoint");
    return await http
        .delete(url, headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.StreamedResponse> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    File? imageFile,
    String imageField = 'image',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token') ?? "";

    final url = Uri.parse("$baseUrl$endpoint");
    final request = http.MultipartRequest('POST', url);

    if (token.isNotEmpty) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.fields.addAll(fields);

    if (imageFile != null) {
      if (!await imageFile.exists()) {
        throw Exception("Image file not found: ${imageFile.path}");
      }
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        imageField,
        stream,
        length,
        filename: path.basename(imageFile.path),
      );
      request.files.add(multipartFile);
    }

    return await request.send().timeout(const Duration(seconds: 30));
  }

  // Helper to handle response
  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        jsonDecode(response.body)['message'] ??
            'Error occurred: ${response.statusCode}',
      );
    }
  }
}
