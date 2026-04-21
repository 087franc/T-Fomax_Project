import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CorrectiveChatPage extends StatefulWidget {
  final String ticketId;
  final VoidCallback onFinalize;

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

  // --- KI'IK MAIBÉ IMPORTANTE: STATIC LIST ---
  // Static halo lista ne'e labele lakon maske ó Navigator.pop()
  static final Map<String, List<Map<String, dynamic>>> _allChats = {};

  @override
  void initState() {
    super.initState();
    // Se ticket ne'e seidauk iha istória chat, kria lista foun ida
    if (!_allChats.containsKey(widget.ticketId)) {
      _allChats[widget.ticketId] = [];
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
    );

    if (photo != null) {
      setState(() {
        _allChats[widget.ticketId]!.add({
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
        _allChats[widget.ticketId]!.add({
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
    final messages = _allChats[widget.ticketId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat: ${widget.ticketId}",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.blue),
            onPressed: () {
              widget.onFinalize();
              // Se hakarak hamoos chat wainhira finalize:
              // _allChats.remove(widget.ticketId);
              Navigator.pop(context);
            },
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
