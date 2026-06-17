import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProactiveList extends StatefulWidget {
  final Function(Map<String, dynamic>) onEdit;

  const ProactiveList({super.key, required this.onEdit});

  @override
  State<ProactiveList> createState() => _ProactiveListState();
}

class _ProactiveListState extends State<ProactiveList> {
  List<dynamic> _apiList = [];
  List<dynamic> _pendingList = [];
  bool _isLoading = false;
  String _userId = "";

  String _name = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? "";
    _name = prefs.getString('user_name') ?? "";

    await _fetchCombinedList();
  }

  Future<void> _fetchCombinedList() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Load Pending from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? pendingJson = prefs.getString('pending_proactive');
      _pendingList = pendingJson != null ? jsonDecode(pendingJson) : [];

      // 2. Load from API
      final response = await ApiService().get("/api/v1/proactive/list");
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          _apiList = data;
        } else if (data is Map && data.containsKey('data')) {
          _apiList = data['data'] ?? [];
        } else {
          _apiList = [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _pendingList.removeWhere((item) => item['id'] == id);
    await prefs.setString('pending_proactive', jsonEncode(_pendingList));

    setState(() {});
  }

  Future<void> _submitToBackend(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id') ?? _userId;

    final String description = draft['description']?.toString().trim() ?? "";
    final String latitude = draft['latitude']?.toString() ?? "";
    final String longitude = draft['longitude']?.toString() ?? "";
    final String imagePath = draft['imagePath']?.toString() ?? "";
    final String postedBy = draft['posted_by']?.toString().isNotEmpty == true
        ? draft['posted_by'].toString()
        : currentUserId;
    final String timestamp =
        draft['photo_timestamp']?.toString().isNotEmpty == true
        ? draft['photo_timestamp'].toString()
        : draft['timestamp']?.toString().isNotEmpty == true
        ? draft['timestamp'].toString()
        : DateTime.now().toIso8601String();

    if (description.isEmpty) {
      _showErrorDialog("Descrisaun nebee halao fali iha form.");
      return;
    }

    if (postedBy.isEmpty) {
      _showErrorDialog("User ID la hetan halo favor login fila fali!.");
      return;
    }

    if (latitude.isEmpty || longitude.isEmpty) {
      _showErrorDialog(
        "Latitude no longitude la hetan. Favor ativa ita nia Lokasi iha Setting.",
      );
      return;
    }

    if (imagePath.isEmpty) {
      _showErrorDialog("Favor upload foto ho imagem iha draft!.");
      return;
    }

    _showLoadingDialog();
    try {
      final response = await ApiService().multipartPost(
        "/api/v1/proactive",
        fields: {
          "description": description,
          "posted_by": postedBy,
          "latitude": latitude,
          "longitude": longitude,
          "created_at": timestamp,
        },
        imageFile: File(imagePath),
        imageField: 'image_profs',
      );

      final responseBody = await response.stream.bytesToString();
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _deleteDraft(draft['id']);
        _showSuccessDialog("Susesu", "Proactive submete suksesu ba backend");
        _fetchCombinedList();
      } else {
        String message = "Erro submete: ${response.statusCode}";
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map && decoded.containsKey('message')) {
            message = decoded['message'].toString();
          } else if (responseBody.isNotEmpty) {
            message = responseBody;
          }
        } catch (_) {
          if (responseBody.isNotEmpty) {
            message = responseBody;
          }
        }
        _showErrorDialog(message);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog("Erru koneksaun: $e");
    }
  }

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
            Text("Submitting to server..."),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.green)),
        content: Text(msg, style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error", style: TextStyle(color: Colors.redAccent)),
        content: Text(msg, style: const TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combine pending and API items
    List<dynamic> combinedList = [..._pendingList, ..._apiList];

    // Sort by timestamp descending (most recent first)
    combinedList.sort((a, b) {
      DateTime timeA =
          DateTime.tryParse(a['timestamp'] ?? a['created_at'] ?? '') ??
          DateTime(0);
      DateTime timeB =
          DateTime.tryParse(b['timestamp'] ?? b['created_at'] ?? '') ??
          DateTime(0);
      return timeB.compareTo(timeA);
    });

    if (_isLoading && combinedList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (combinedList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchCombinedList,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(child: Text("Seidauk iha dadus proactive")),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCombinedList,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: combinedList.length,
        itemBuilder: (context, index) {
          final item = combinedList[index];
          bool isPending = item['status'] == 'Pending';
          String posterName = isPending
              ? "Ita (Draft)"
              : (item['posted_by'] ?? 'Noname');

          // Check if it's the current user's submitted item (optional visual hint)
          bool isMyPost = !isPending && item['posted_by'] == _userId;

          final String? latStr =
              item['latitude']?.toString() ?? item['lat']?.toString();
          final String? lngStr =
              item['longitude']?.toString() ??
              item['lng']?.toString() ??
              item['long']?.toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Header
                _buildImageHeader(item, isPending),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              posterName + (isMyPost ? " (unknown)" : ""),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(isPending),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Meta info row: Timestamp & Coordinates
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          if (item['timestamp'] != null ||
                              item['created_at'] != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (() {
                                    final dtStr =
                                        item['timestamp'] ?? item['created_at'];
                                    final parsed = DateTime.tryParse(
                                      dtStr ?? '',
                                    );
                                    return parsed != null
                                        ? DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(parsed)
                                        : (dtStr ?? '');
                                  })(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          if (latStr != null &&
                              latStr.isNotEmpty &&
                              lngStr != null &&
                              lngStr.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Lat: $latStr, Lng: $lngStr",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['description'] ?? "",
                        style: const TextStyle(color: Colors.black87),
                      ),

                      if (isPending) ...[
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _actionButton(
                              icon: Icons.edit,
                              label: "Edit",
                              color: Colors.blue,
                              onTap: () => widget.onEdit(item),
                            ),
                            _actionButton(
                              icon: Icons.delete,
                              label: "Delete",
                              color: Colors.red,
                              onTap: () => _deleteDraft(item['id']),
                            ),
                            _actionButton(
                              icon: Icons.cloud_upload,
                              label: "Submit",
                              color: Colors.green,
                              onTap: () => _submitToBackend(item),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageHeader(dynamic item, bool isPending) {
    String? imageUrl;
    File? localFile;

    if (isPending) {
      if (item['imagePath'] != null) {
        localFile = File(item['imagePath']);
      }
    } else {
      imageUrl =
          item['image_url'] ?? item['image_profs']; // Check both common keys
    }

    if (localFile != null || (imageUrl != null && imageUrl.isNotEmpty)) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        child: localFile != null
            ? Image.file(
                localFile,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Image.network(
                _formatImageUrl(imageUrl!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => _imageError(),
              ),
      );
    }

    // Default placeholder if no image
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade400,
        size: 40,
      ),
    );
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http')) return url;

    String baseUrl = ApiService.baseUrl;
    String pathPrefix = "/api/v1/images/proactive/";

    // If the url already contains the prefix, don't add it again
    if (url.contains(pathPrefix)) {
      if (baseUrl.endsWith('/') && url.startsWith('/')) {
        return baseUrl + url.substring(1);
      } else if (!baseUrl.endsWith('/') && !url.startsWith('/')) {
        return "$baseUrl/$url";
      }
      return baseUrl + url;
    }

    // Ensure the filename is appended correctly to the full path
    String fileName = url.startsWith('/') ? url.substring(1) : url;
    if (baseUrl.endsWith('/')) {
      return "${baseUrl}api/v1/images/proactive/$fileName";
    } else {
      return "$baseUrl/api/v1/images/proactive/$fileName";
    }
  }

  Widget _imageError() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 8),
          Text(
            "Labele hatudu imajen",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isPending) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isPending ? "Pending" : "Sent",
        style: TextStyle(
          color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
