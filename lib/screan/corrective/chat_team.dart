import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'corective.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class CorrectiveChatPage extends StatefulWidget {
  final String ticketId;
  final VoidCallback onFinalize;

  static final Map<String, List<Map<String, dynamic>>> allChats = {};

  const CorrectiveChatPage({
    super.key,
    required this.ticketId,
    required this.onFinalize,
  });

  @override
  State<CorrectiveChatPage> createState() => _CorrectiveChatPageState();
}

class _CorrectiveChatPageState extends State<CorrectiveChatPage> {
  final TextEditingController _msgController = TextEditingController();

  final String myTeamId = "TEAM-FRANS-01"; // Id Team ne'ebe 'Login'
  List<dynamic> _ticketList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (!CorrectiveChatPage.allChats.containsKey(widget.ticketId)) {
      CorrectiveChatPage.allChats[widget.ticketId] = [];
    }
  }

  // --- 1. LOAD DATA HO BACKEND ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get("/api/v1/ticket");
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        setState(() {
          if (decoded is List) {
            _ticketList = decoded;
          } else if (decoded is Map) {
            var dataVal = decoded['data'];
            if (dataVal is List) {
              _ticketList = dataVal;
            } else if (dataVal is Map && dataVal.containsKey('data')) {
              var innerData = dataVal['data'];
              if (innerData is List) {
                _ticketList = innerData;
              } else {
                _ticketList = [];
              }
            } else {
              _ticketList = [];
            }
          } else {
            _ticketList = [];
          }
        });
      } else {
        _showSnackBarError("Erro foti dadus chat: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error loading chat ticket: $e");
      _showSnackBarError("Erro koneksaun: Network is unreachable");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBarError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // --- KI'IK MAIBÉ IMPORTANTE: STATIC LIST ---
  // Static halo lista ne'e labele lakon maske ó Navigator.pop()

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
    );

    if (photo != null) {
      setState(() {
        CorrectiveChatPage.allChats[widget.ticketId]!.add({
          "user": "Me",
          "type": "image",
          "content": File(photo.path),
          "time": DateTime.now().toString().substring(11, 16),
        });
      });
    }
  }

  void _sendMessage() {
    if (_msgController.text.isNotEmpty) {
      setState(() {
        CorrectiveChatPage.allChats[widget.ticketId]!.add({
          "user": "Me",
          "type": "text",
          "content": _msgController.text,
          "time": DateTime.now().toString().substring(11, 16),
        });
      });
      _msgController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Foti chat sira ne'ebé iha ona
    final messages = CorrectiveChatPage.allChats[widget.ticketId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat: ${widget.ticketId}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Finaliza Ticket?"),
                    content: const Text(
                      "Ita hakarak finaliza ticket ne'e?",
                      style: TextStyle(fontSize: 14),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text("Kansela"),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          widget.onFinalize();
                          // Se hakarak hamoos chat wainhira finalize:
                          // _allChats.remove(widget.ticketId);
                          Navigator.pop(context);
                          _navigateBackToList();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("FINALIZA"),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text("FINALIZA"),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Chat foun iha okos
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                // Reverse lista hodi hatudu lójika chat nian
                var m = messages.reversed.toList()[index];
                return _buildChatBubble(m);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  void _navigateBackToList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CorrectivePage()),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> m) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            m['type'] == 'text'
                ? Text(m['content'])
                : Image.file(m['content'] as File, width: 200),
            const SizedBox(height: 5),
            Text(
              m['time'].toString(),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.red),
            onPressed: _takePhoto,
          ),
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: const InputDecoration(
                hintText: "Hakerek mensajen...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
