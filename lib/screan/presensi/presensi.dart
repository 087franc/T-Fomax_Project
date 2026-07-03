import 'dart:async'; // 1. Tambahkan import ini
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presence_history.dart';

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
  bool _isLoading = false; // Loading state for API calls

  // User ID and Token from login
  String _sessionId = "";
  String _userId = "";
  String _sessionToken = "";
  String _scheduleType = "fixed";
  String _shiftIn = "08:00:00";
  String _shiftOut = "17:00:00";
  bool _hasClockedIn = false;

  // 2. Tambahkan variabel untuk Timer dan String waktu
  Timer? _timer;
  String _currentTime = "";

  bool get isMorning {
    // If already clocked in, don't show the morning/clock-in form
    if (_hasClockedIn) return false;

    if (_scheduleType == 'shift') {
      return true; // Always available for shift until clocked in
    }
    // For fixed, only available during 08:00 - 12:00
    return DateTime.now().hour >= 8 && DateTime.now().hour < 12;
  }

  bool get isEvening {
    // Clock-out form only appears after clock-in is done
    if (!_hasClockedIn) return false;

    if (_scheduleType == 'shift') {
      return true; // Available immediately after clock-in for shift
    }
    // For fixed, must wait until 17:00 - 21:00
    return DateTime.now().hour >= 17 && DateTime.now().hour < 21;
  }

  bool _isWithinWindow(
    String timeStr,
    int startOffsetHours,
    int endOffsetHours,
  ) {
    try {
      final now = DateTime.now();
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final baseTime = DateTime(now.year, now.month, now.day, hour, minute);
      final startTime = baseTime.add(Duration(hours: startOffsetHours));
      final endTime = baseTime.add(Duration(hours: endOffsetHours));

      return now.isAfter(startTime) && now.isBefore(endTime);
    } catch (e) {
      return false;
    }
  }

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
      _scheduleType = prefs.getString('user_schedule_type') ?? 'fixed';
      _shiftIn = prefs.getString('start_shift') ?? '08:00:00';
      _shiftOut = prefs.getString('end_shift') ?? '17:00:00';
      _hasClockedIn = prefs.getBool('has_clocked_in_$_userId') ?? false;
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return;
      }

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
  Future<String?> _sendClockInToBackend() async {
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

      final response = await ApiService().post(
        "/api/v1/attendance/clockin",
        requestBody,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Clock In Success: ${response.body}");
        return null; // Success
      } else {
        debugPrint("Clock In Error: ${response.statusCode} - ${response.body}");
        // Check if backend returned a specific error message
        return data['message'] ?? "Failed to send data. Please try again.";
      }
    } catch (e) {
      debugPrint("Clock In Exception: $e");
      return "Erro: Labele liga ba server";
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
  Future<String?> _sendClockOutToBackend() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      var response = await ApiService().multipartPost(
        "/api/v1/attendance/clockout",
        fields: {
          "session_id": _sessionId,
          "user_id": _userId,
          "clock_out": timeStr,
          "activity_description": _taskController.text,
          "lat_clock_out": (_currentPosition?.latitude ?? 0.0).toString(),
          "long_clock_out": (_currentPosition?.longitude ?? 0.0).toString(),
          "health": _healthCondition == "Saudável" ? "0" : "1",
          "type": "CLOCK_OUT",
        },
        imageFile: _imageFile,
        imageField: "activity_image",
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Clock Out Success: $responseBody");
        return null; // Success
      } else {
        debugPrint("Clock Out Error: ${response.statusCode} - $responseBody");
        try {
          final decoded = jsonDecode(responseBody);
          return decoded['message'] ?? "Failed to send data. Please try again.";
        } catch (e) {
          return "Failed to send data. Status: ${response.statusCode}";
        }
      }
    } catch (e) {
      debugPrint("Clock Out Exception: $e");
      return "Erro: Labele liga ba server";
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

  // Handle long press on clock in button
  Future<void> _handleClockInLongPress() async {
    // 1. Ensure location is available before proceeding
    if (_currentPosition == null) {
      _showLoadingDialog();
      await _getHiddenLocation();
      if (mounted) Navigator.pop(context); // Close loading dialog
    }

    if (_currentPosition == null) {
      _showErrorDialog("Favor Hamoris Ita nia Lokasi Telfone!");
      return;
    }

    // 2. Proceed with backend call
    _showLoadingDialog();
    final errorMessage = await _sendClockInToBackend();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      if (errorMessage == null) {
        // Set clocked in status only on success
        setState(() => _hasClockedIn = true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_clocked_in_$_userId', true);

        _showSuccessDialog(
          "Susesu In",
          "Ita-nia kondisaun: $_healthCondition. Servisu di'ak!",
        );
      } else {
        _showErrorDialog(errorMessage);
      }
    }
  }

  // Handle long press on clock out button
  Future<void> _handleClockOutLongPress() async {
    if (_imageFile == null || _taskController.text.isEmpty) {
      _showErrorDialog("Please fill in all fields!");
      return;
    }

    // Ensure location is available
    if (_currentPosition == null) {
      _showLoadingDialog();
      await _getHiddenLocation();
      if (mounted) Navigator.pop(context); // Close loading dialog
    }

    if (_currentPosition == null) {
      _showErrorDialog("Favor Hamoris Ita nia Lokasi Telfone!");
      return;
    }

    _showLoadingDialog();
    final errorMessage = await _sendClockOutToBackend();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      if (errorMessage == null) {
        // Reset clocked in status after successful clock out
        setState(() => _hasClockedIn = false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_clocked_in_$_userId', false);

        _showSuccessDialog(
          "Susesu Out",
          "Obrigadu ba ita-nia servisu ohin. Deskansa di'ak!",
        );
      } else {
        _showErrorDialog(errorMessage);
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

  bool _isLate() {
    if (_scheduleType == 'shift') {
      final parts = _shiftIn.split(':');
      final shiftHour = int.parse(parts[0]);
      return DateTime.now().hour >= shiftHour + 1; // 1 hour late
    }
    return DateTime.now().hour >= 9;
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
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.history_rounded),
          //   tooltip: "Istorya Presensa",
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const PresenceHistoryPage(),
          //       ),
          //     );
          //   },
          // ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PresenceHistoryPage(),
                ),
              );
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'list',
                child: Text("Hare Historia Presensa"),
              ),
            ],
          ),
        ],
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
            const SizedBox(height: 24),

            // History Button Card
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PresenceHistoryPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                // decoration: BoxDecoration(
                //   color: Colors.white,
                //   borderRadius: BorderRadius.circular(16),
                //   border: Border.all(color: Colors.redAccent.withOpacity(0.12)),
                //   boxShadow: [
                //     BoxShadow(
                //       color: Colors.black.withOpacity(0.02),
                //       blurRadius: 10,
                //       offset: const Offset(0, 4),
                //     ),
                //   ],
                // ),
                // child: Row(
                //   children: [
                //     Container(
                //       padding: const EdgeInsets.all(10),
                //       decoration: BoxDecoration(
                //         color: Colors.red.shade50,
                //         shape: BoxShape.circle,
                //       ),
                //       child: const Icon(
                //         Icons.history_rounded,
                //         color: Colors.redAccent,
                //         size: 22,
                //       ),
                //     ),
                //     const SizedBox(width: 16),
                //     const Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             "Historia Presensa",
                //             style: TextStyle(
                //               fontSize: 15,
                //               fontWeight: FontWeight.bold,
                //               color: Colors.black87,
                //             ),
                //           ),
                //           SizedBox(height: 2),
                //           Text(
                //             "Haree dadus clock in no clock out",
                //             style: TextStyle(fontSize: 12, color: Colors.grey),
                //           ),
                //         ],
                //       ),
                //     ),
                //     const Icon(
                //       Icons.arrow_forward_ios_rounded,
                //       size: 14,
                //       color: Colors.grey,
                //     ),
                //   ],
                // ),
              ),
            ),
            const SizedBox(height: 24),

            // Health Condition Form (Morning) - Permanently visible
            if (isMorning) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Kondisaun Saúde (*)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _healthCondition,
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
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() => _healthCondition = val!),
              ),
              const SizedBox(height: 30),
              // Late Reason field - only visible if past scheduled start time
              if (_isLate()) ...[
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
            ],

            // Photo Section - Only visible during Clock Out (evening)
            if (isEvening) ...[
              // Health Condition Form (Evening) - Same as Morning
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Kondisaun Saúde (*)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _healthCondition,
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
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() => _healthCondition = val!),
              ),
              const SizedBox(height: 10),

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

              // Photo Section - Only visible during Clock Out (evening)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hasai Foto servisu nian (*)",
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
                      (!_isLate() || _lateReasonController.text.isNotEmpty),
                      _handleClockInLongPress,
                      onLongPress: _handleClockInLongPress,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tap or long press to confirm Clock In",
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
                      _handleClockOutLongPress,
                      onLongPress: _handleClockOutLongPress,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tap or long press to confirm Clock Out",
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
                    const Icon(
                      Icons.access_time,
                      color: Color.fromARGB(255, 63, 52, 42),
                    ),
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
        ),
      ),
    );
  }
}
