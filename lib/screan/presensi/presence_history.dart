import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String? latClockIn;
  final String? longClockIn;
  final String? latClockOut;
  final String? longClockOut;
  final String? lateReason;
  final String? activityDescription;
  final String health; // "0" or "1"
  final String? activityImage;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.clockIn,
    this.clockOut,
    this.latClockIn,
    this.longClockIn,
    this.latClockOut,
    this.longClockOut,
    this.lateReason,
    this.activityDescription,
    required this.health,
    this.activityImage,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    DateTime ci = DateTime.now();
    if (json['clock_in'] != null) {
      try {
        ci = DateTime.parse(json['clock_in']);
      } catch (_) {
        try {
          ci = DateFormat('yyyy-MM-dd HH:mm:ss').parse(json['clock_in']);
        } catch (_) {}
      }
    }

    DateTime? co;
    if (json['clock_out'] != null) {
      try {
        co = DateTime.parse(json['clock_out']);
      } catch (_) {
        try {
          co = DateFormat('yyyy-MM-dd HH:mm:ss').parse(json['clock_out']);
        } catch (_) {}
      }
    }

    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      clockIn: ci,
      clockOut: co,
      latClockIn: json['lat_clock_in']?.toString(),
      longClockIn: json['long_clock_in']?.toString(),
      latClockOut: json['lat_clock_out']?.toString(),
      longClockOut: json['long_clock_out']?.toString(),
      lateReason: json['late_reason']?.toString(),
      activityDescription:
          json['activity_description']?.toString() ??
          json['service_description']?.toString(),
      health: json['health']?.toString() ?? '0',
      activityImage:
          json['activity_image']?.toString() ?? json['photo']?.toString(),
    );
  }
}

class PresenceHistoryPage extends StatefulWidget {
  const PresenceHistoryPage({super.key});

  @override
  State<PresenceHistoryPage> createState() => _PresenceHistoryPageState();
}

class _PresenceHistoryPageState extends State<PresenceHistoryPage> {
  List<AttendanceRecord> _history = [];
  bool _isLoading = true;
  String _error = '';
  bool _showSimulated = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _showSimulated = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      var response = await ApiService().get(
        "/api/v1/attendance?user_id=$userId",
      );
      if (response.statusCode != 200) {
        response = await ApiService().get("/api/v1/attendance");
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> fetchedList = [];
        if (decoded is List) {
          fetchedList = decoded;
        } else if (decoded is Map) {
          var data = decoded['data'];
          if (data is List) {
            fetchedList = data;
          } else if (data is Map && data.containsKey('data')) {
            var innerData = data['data'];
            if (innerData is List) {
              fetchedList = innerData;
            }
          }
        }

        final parsedHistory = fetchedList
            .map((x) => AttendanceRecord.fromJson(x))
            .toList();

        // Sort history by date descending
        parsedHistory.sort((a, b) => b.clockIn.compareTo(a.clockIn));

        setState(() {
          _history = parsedHistory;
          _isLoading = false;
          if (_history.isEmpty) {
            _loadSimulatedData();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadSimulatedData(errorMsg: "Status ${response.statusCode}");
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadSimulatedData(errorMsg: e.toString());
      });
    }
  }

  void _loadSimulatedData({String? errorMsg}) {
    // If backend endpoint doesn't exist or is empty, we load mock history to ensure user gets a functional page
    final now = DateTime.now();
    _history = [
      AttendanceRecord(
        id: "1",
        userId: "96",
        clockIn: DateTime(now.year, now.month, now.day, 8, 12, 0),
        clockOut: DateTime(now.year, now.month, now.day, 17, 05, 0),
        health: "0",
        activityDescription:
            "Repara fibra optika iha terminál Telkomcel Colmera.",
        latClockIn: "-8.556877",
        longClockIn: "125.560314",
      ),
      AttendanceRecord(
        id: "2",
        userId: "96",
        clockIn: DateTime(now.year, now.month, now.day - 1, 9, 15, 0),
        clockOut: DateTime(now.year, now.month, now.day - 1, 17, 30, 0),
        health: "0",
        lateReason: "Tránzitu iha área Bidau tanba udan boot.",
        activityDescription: "Manutensaun rotina ba AC server no UPS backup.",
        latClockIn: "-8.557102",
        longClockIn: "125.561405",
      ),
      AttendanceRecord(
        id: "3",
        userId: "96",
        clockIn: DateTime(now.year, now.month, now.day - 2, 8, 05, 0),
        clockOut: DateTime(now.year, now.month, now.day - 2, 17, 00, 0),
        health: "1",
        activityDescription:
            "Monitorizasaun rede corrective iha Sentru Operasaun.",
        latClockIn: "-8.556912",
        longClockIn: "125.560410",
      ),
      AttendanceRecord(
        id: "4",
        userId: "96",
        clockIn: DateTime(now.year, now.month, now.day - 3, 8, 10, 0),
        clockOut: DateTime(now.year, now.month, now.day - 3, 17, 10, 0),
        health: "0",
        activityDescription:
            "Konfigurasaun router foun iha kliente korporativu.",
        latClockIn: "-8.556750",
        longClockIn: "125.560120",
      ),
    ];
    _showSimulated = true;
    if (errorMsg != null) {
      debugPrint("Presence history API error fallback: $errorMsg");
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalDays = _history.length;
    int lateDays = _history
        .where((r) => r.lateReason != null || r.clockIn.hour >= 9)
        .length;
    int healthyDays = _history.where((r) => r.health == "0").length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Istorya Presensa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Aktualiza",
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              color: Colors.redAccent,
              child: CustomScrollView(
                slivers: [
                  // Simulated Mode Banner
                  if (_showSimulated)
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.amber.shade50,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.amber.shade900,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Modu Simulasaun (Labele load husi server)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Top Stats Summary Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Total Loron",
                              "$totalDays",
                              Icons.calendar_month,
                              Colors.blue.shade600,
                              Colors.blue.shade50,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              "Tarde",
                              "$lateDays",
                              Icons.warning_amber_rounded,
                              Colors.orange.shade700,
                              Colors.orange.shade50,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              "Saudável",
                              "$healthyDays",
                              Icons.favorite_rounded,
                              Colors.green.shade600,
                              Colors.green.shade50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // History list
                  _history.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Seidauk iha istorya presensa",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final record = _history[index];
                              return _buildAttendanceCard(record);
                            }, childCount: _history.length),
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final dayStr = DateFormat('dd').format(record.clockIn);
    final monthStr = DateFormat('MMM').format(record.clockIn).toUpperCase();
    final dayName = DateFormat('EEEE').format(record.clockIn);

    final clockInTime = DateFormat('HH:mm').format(record.clockIn);
    final clockOutTime = record.clockOut != null
        ? DateFormat('HH:mm').format(record.clockOut!)
        : '--:--';

    final isLate = record.lateReason != null || record.clockIn.hour >= 9;
    final isHealthy = record.health == "0";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Card Header (Date and Status tags)
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Date bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        Text(
                          monthStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Day Name & Year
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy').format(record.clockIn),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Tags
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLate
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLate ? "Tarde" : "On Time",
                          style: TextStyle(
                            color: isLate
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHealthy
                              ? Colors.blue.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isHealthy ? "Saudável" : "Kondisaun Seluk",
                          style: TextStyle(
                            color: isHealthy
                                ? Colors.blue.shade900
                                : Colors.red.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Time Stamps (Clock In & Clock Out)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.login_rounded,
                            color: Colors.green.shade700,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CLOCK IN",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              clockInTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(height: 35, width: 1, color: Colors.grey.shade200),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "CLOCK OUT",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              clockOutTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: record.clockOut != null
                                ? Colors.red.shade50
                                : Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: record.clockOut != null
                                ? Colors.red.shade700
                                : Colors.grey.shade400,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Additional details if present
            if (record.lateReason != null ||
                record.activityDescription != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.lateReason != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.report_problem_outlined,
                            size: 14,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: "Razaun Tarde: ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                ),
                                children: [
                                  TextSpan(
                                    text: record.lateReason,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (record.activityDescription != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: Colors.blue.shade800,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: "Atividade: ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                                children: [
                                  TextSpan(
                                    text: record.activityDescription,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Map coordinate footer
          ],
        ),
      ),
    );
  }
}
