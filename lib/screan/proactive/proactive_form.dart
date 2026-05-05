import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class ProactiveForm extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback onSaved;

  const ProactiveForm({super.key, this.editData, required this.onSaved});

  @override
  State<ProactiveForm> createState() => _ProactiveFormState();
}

class _ProactiveFormState extends State<ProactiveForm> {
  final TextEditingController _deskripsiController = TextEditingController();
  File? _imageFile;
  String? _networkImageUrl;
  bool _isLoading = false;
  String _userId = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.editData != null) {
      _deskripsiController.text = widget.editData!['description'] ?? "";
      if (widget.editData!['imagePath'] != null) {
        _imageFile = File(widget.editData!['imagePath']);
      } else if (widget.editData!['image_url'] != null || widget.editData!['image_profs'] != null) {
        _networkImageUrl = widget.editData!['image_url'] ?? widget.editData!['image_profs'];
      }
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userId = prefs.getString('user_id') ?? "";
      });
    }
  }

  Future<void> _saveAsDraft() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? pendingJson = prefs.getString('pending_proactive');
      List<dynamic> pendingList = pendingJson != null
          ? jsonDecode(pendingJson)
          : [];

      Map<String, dynamic> draft = {
        'id':
            widget.editData?['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'description': _deskripsiController.text,
        'imagePath': _imageFile?.path,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Pending',
      };

      if (widget.editData != null) {
        // Update existing draft
        int index = pendingList.indexWhere(
          (item) => item['id'] == widget.editData!['id'],
        );
        if (index != -1) {
          pendingList[index] = draft;
        } else {
          pendingList.add(draft);
        }
      } else {
        // New draft
        pendingList.add(draft);
      }

      await prefs.setString('pending_proactive', jsonEncode(pendingList));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Proactive saved to pending list"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      debugPrint("Error saving draft: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _networkImageUrl = null; // Clear network image if a new one is picked
        });
      }
    } catch (e) {
      debugPrint("Erru loke kamera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Deskrisaun Proactive",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _deskripsiController,
            maxLines: 4,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Foto Attachment Proactive",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickImage,
            child: Container(
              width: 180,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagePreview(),
              ),
            ),
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFFF0000)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_deskripsiController.text.isEmpty ||
                            _imageFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Favor hatama deskrisaun no foto"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        await _saveAsDraft();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Submete Proactive",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (_networkImageUrl != null && _networkImageUrl!.isNotEmpty) {
      return Image.network(
        _formatImageUrl(_networkImageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    } else {
      return _imagePlaceholder();
    }
  }

  Widget _imagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 80, color: Colors.grey),
        SizedBox(height: 10),
        Text(
          "Aumenta Foun\nFoto Attachment\nProactive",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
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
}
