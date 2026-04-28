import 'dart:async'; // 1. Tambahkan import ini
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  File? _imageFile;
  String _healthCondition = "Saudável";
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _lateReasonController = TextEditingController();
  // Location is hidden - stored but not displayed in UI
  Position? _currentPosition;
  bool _isHealthFormVisible = false; // Track health form visibility
  bool _isPhotoFormVisible = false; // Track photo form visibility
  bool _isLoading = false; // Loading state for API calls

  // User ID and Token from login
  String _sessionId = "";
  String _userId = "";
  String _sessionToken = "";

  // 2. Tambahkan variabel untuk Timer dan String waktu
  Timer? _timer;
  String _currentTime = "";

  // Backend API URL - replace with your actual API endpoint
  static const String _baseUrl = "http://172.20.222.203:3000";

  bool get isMorning => DateTime.now().hour >= 8 && DateTime.now().hour < 12;
  bool get isEvening => DateTime.now().hour >= 17 && DateTime.now().hour < 21;

  @override
  void initState() {
    super.initState();
    // 3. Jalankan timer saat pertama kali buka halaman
    _startTimer();
    // Get hidden location in background
    _getHiddenLocation();
    // Get user data from login
    _loadUserData();
  }

  // Load user data from SharedPreferences (set during login)
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId =
          prefs.getString('session_id') ?? ''; // Use session_id from login
      _userId = prefs.getString('user_id') ?? '';
      _sessionToken = prefs.getString('session_token') ?? '';
    });
    debugPrint(
      "User ID: $_userId, Session ID: $_sessionId, Token: ${_sessionToken.isNotEmpty ? 'Present' : 'Missing'}",
    );
  }

  // 4. Fungsi untuk menjalankan jam secara real-time
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Menggunakan 'HH' untuk memastikan format 24 jam (17, 20, dst)
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    // 5. Penting: Hentikan timer saat keluar dari halaman
    _timer?.cancel();
    _taskController.dispose();
    super.dispose();
  }

  // Location is fetched but hidden - never displayed to user
  Future<void> _getHiddenLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (photo != null) {
      setState(() => _imageFile = File(photo.path));
    }
  }

  // ============ BACKEND INTEGRATION ============

  /// Send Clock In data to backend
  /// Example API call:
  /// POST /api/presensi/clock-in
  /// Body: {
  ///   "user_id": "123",
  ///   "photo": "base64_string_or_file_url",
  ///   "health_condition": "Saudável",
  ///   "latitude": -8.556877,
  ///   "longitude": 125.5603143,
  ///   "timestamp": "2026-04-27T08:30:00Z"
  /// }
  Future<bool> _sendClockInToBackend() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      // Map health condition to code
      String healthCode = "0"; // Default to Saudável
      if (_healthCondition != "Saudável") {
        healthCode = "1"; // Other conditions
      }

      final Map<String, dynamic> requestBody = {
        "user_id": _userId,
        "clock_in": timeStr,
        "late_reason": _lateReasonController.text.isNotEmpty
            ? _lateReasonController.text
            : null,
        "lat_clock_in": (_currentPosition?.latitude ?? 0.0).toString(),
        "long_clock_in": (_currentPosition?.longitude ?? 0.0).toString(),
        "health": healthCode,
      };

      final response = await http
          .post(
            Uri.parse("$_baseUrl/api/v1/attendance/clockin"),
            headers: {
              "Content-Type": "application/json",
              if (_sessionToken.isNotEmpty)
                "Authorization": "Bearer $_sessionToken",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Clock In Success: ${response.body}");
        return true;
      } else {
        debugPrint("Clock In Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Clock In Exception: $e");
      // For demo purposes, simulate success
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Send Clock Out data to backend
  /// Example API call:
  /// POST /api/v1/attendance/clockout
  /// Body: {
  ///   "user_id": "123",
  ///   "photo": "base64_string_or_file_url",
  ///   "service_description": "Halo servisu nebe",
  ///   "latitude": -8.556877,
  ///   "longitude": 125.5603143,
  ///   "timestamp": "2026-04-27T17:30:00Z"
  /// }
  Future<bool> _sendClockOutToBackend() async {
    setState(() => _isLoading = true);

    try {
      // Prepare the data
      final Map<String, dynamic> data = {
        "session_id": _sessionId.isNotEmpty
            ? _sessionId
            : "user_123", // Use user ID from login
        "user_id": _userId,
        "activity_description": _taskController.text,
        "lat_clock_out": _currentPosition?.latitude ?? 0.0,
        "long_clock_out": _currentPosition?.longitude ?? 0.0,
        //"timestamp": DateTime.now().toIso8601String(),
        "type": "CLOCK_OUT",
      };

      var uri = Uri.parse("$_baseUrl/api/v1/attendance/clockout");
      var request = http.MultipartRequest("POST", uri);

      // Add Authorization header
      if (_sessionToken.isNotEmpty) {
        request.headers["Authorization"] = "Bearer $_sessionToken";
      }

      // Add text fields
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add photo file if exists
      if (_imageFile != null) {
        var stream = http.ByteStream(_imageFile!.openRead());
        var length = await _imageFile!.length();
        var multipartFile = http.MultipartFile(
          "photo",
          stream,
          length,
          filename: _imageFile!.path.split("/").last,
        );
        request.files.add(multipartFile);
      }

      // Send the request
      var response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        debugPrint("Clock Out Success: $responseBody");
        return true;
      } else {
        debugPrint("Clock Out Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Clock Out Exception: $e");
      // For demo purposes, simulate success
      // Remove this in production
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============ EXAMPLE: Using JSON (without file) ============

  /// Alternative: Send data as JSON (if backend supports JSON)
  // Future<bool> _sendClockInAsJson() async {
  //   try {
  //     final response = await http
  //         .post(
  //           Uri.parse("$_baseUrl/api/v1/attendance/clockin"),
  //           headers: {
  //             "Content-Type": "application/json",
  //             "Authorization": "Bearer YOUR_TOKEN_HERE", // Add auth token
  //           },
  //           body: jsonEncode({
  //             "user_id": "user_123",
  //             "health": _healthCondition,
  //             "latitude": _currentPosition?.latitude ?? 0.0,
  //             "longitude": _currentPosition?.longitude ?? 0.0,
  //             "timestamp": DateTime.now().toIso8601String(),
  //           }),
  //         )
  //         .timeout(const Duration(seconds: 30));

  //     return response.statusCode == 200 || response.statusCode == 201;
  //   } catch (e) {
  //     debugPrint("JSON send error: $e");
  //     return true; // Demo success
  //   }
  // }

  // ============ UI HELPERS ============

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.redAccent),
            SizedBox(height: 20),
            Text("Sending data to server..."),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Error",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle health form visibility - returns to main presence page
  void _toggleHealthForm() {
    setState(() {
      _isHealthFormVisible = !_isHealthFormVisible;
    });
  }

  // Handle long press on clock in button
  Future<void> _handleClockInLongPress() async {
    // Clock in doesn't require photo - only health condition
    _showLoadingDialog();
    final success = await _sendClockInToBackend();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      if (success) {
        _showSuccessDialog(
          "Susesu In",
          "Ita-nia kondisaun: $_healthCondition. Servisu di'ak!",
        );
      } else {
        _showErrorDialog("Failed to send data. Please try again.");
      }
    }
  }

  // Handle long press on clock out button
  Future<void> _handleClockOutLongPress() async {
    if (_imageFile == null || _taskController.text.isEmpty) {
      _showErrorDialog("Please fill in all fields!");
      return;
    }

    _showLoadingDialog();
    final success = await _sendClockOutToBackend();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      if (success) {
        _showSuccessDialog(
          "Susesu Out",
          "Obrigadu ba ita-nia servisu ohin. Deskansa di'ak!",
        );
      } else {
        _showErrorDialog("Failed to send data. Please try again.");
      }
    }
  }

  // Helper untuk Button agar kode lebih rapi
  Widget _buildButton(
    String label,
    Color color,
    bool enabled,
    VoidCallback onPressed, {
    VoidCallback? onLongPress,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 4 : 0,
        ),
        onPressed: enabled ? onPressed : null,
        onLongPress: enabled ? onLongPress : null,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Presensa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Card for time display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _currentTime.isEmpty ? "..." : _currentTime,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Health Condition Form (Morning) - Toggle visibility
            if (isMorning) ...[
              // Header with toggle button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Kondisaun Saúde (*)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _toggleHealthForm,
                    icon: Icon(
                      _isHealthFormVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    label: Text(_isHealthFormVisible ? "Loke" : "oke"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show health form when toggled
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isHealthFormVisible ? 120 : 0,
                child: _isHealthFormVisible
                    ? DropdownButtonFormField<String>(
                        value: _healthCondition,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items:
                            [
                                  "Saudável",
                                  "Isin-manas",
                                  "Me'ar",
                                  "Inus-metin",
                                  "Ulun-Moras",
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) =>
                            setState(() => _healthCondition = val!),
                      )
                    : const SizedBox(),
              ),
              const SizedBox(height: 10),
              // Late Reason field - only visible if past 09:00
              if (DateTime.now().hour >= 9) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Razaun Tarde (se tarde)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lateReasonController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Hakerek razaun tarde...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // SUBMIT CLOCK IN BUTTON
              if (_isHealthFormVisible)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _buildButton(
                    "SUBMIT CLOCK IN",
                    Colors.green,
                    (DateTime.now().hour < 9 ||
                        _lateReasonController.text.isNotEmpty),
                    _handleClockInLongPress,
                  ),
                ),
            ],

            // Photo Section - Only visible during Clock Out (evening)
            if (isEvening) ...[
              if (isEvening) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Relatóriu Servisu Ohin (*)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _taskController,
                    maxLines: 4,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Hakerek saida mak halo ona...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Photo Section - Only visible during Clock Out (evening)
              if (isEvening) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Hasai Foto Oin (*)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _imageFile != null
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _imageFile != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(
                                  _imageFile!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: Colors.redAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Klik hodi hasai foto",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Action Buttons
              if (isMorning)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      _buildButton(
                        "CLOCK IN",
                        Colors.green,
                        true, // Clock in doesn't need photo
                        () {
                          // Normal tap - show health form only
                          setState(() => _isHealthFormVisible = true);
                        },
                        onLongPress: _handleClockInLongPress,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Tap to show health form • Long press to confirm",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isEvening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      _buildButton(
                        "CLOCK OUT",
                        Colors.redAccent,
                        (_imageFile != null && _taskController.text.isNotEmpty),
                        () {
                          // Tap - show all forms (photo, job description, health)
                          setState(() {
                            _isHealthFormVisible = true;
                            _isPhotoFormVisible = true;
                          });
                          // Scroll to show forms
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              Scrollable.ensureVisible(
                                context,
                                duration: const Duration(milliseconds: 300),
                              );
                            }
                          });
                        },
                        onLongPress: _handleClockOutLongPress,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Tap to show forms • Long press to confirm",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Text(
                        "Ondu la'ós oras presensa",
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
