import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_models.dart';

class CorrectiveChatPage extends StatefulWidget {
  final String ticketId;
  final VoidCallback onFinalize;

  static final Map<String, List<ChatMessage>> allChats = {};

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
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _conversations = [];
  List<ChatMessage> _notes = [];
  int _activeTab = 0; // 0: Chat, 1: Private Notes
  bool _isLoading = false;

  String _userId = "";
  String _userEmail = "";
  String _userName = "";

  WebSocket? _ws;
  bool _isWsConnected = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      _loadHistory();
      _initWebSocket();
    });
  }

  @override
  void dispose() {
    _closeWebSocket();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- LOAD USER INFO FROM SHARED PREFERENCES ---
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userId = prefs.get('user_id')?.toString() ?? '';
          _userEmail = prefs.get('user_email')?.toString() ?? '';
          _userName = prefs.get('user_name')?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading user info: $e");
    }
  }

  // --- WEBSOCKET CONNECTION ---
  void _initWebSocket() {
    _closeWebSocket();
    _connectWebSocket();
  }

  void _closeWebSocket() {
    if (_ws != null) {
      _ws!.close();
      _ws = null;
    }
    _isWsConnected = false;
  }

  String _lastWsError = "";

  Future<void> _connectWebSocket() async {
    try {
      final baseUri = Uri.parse(ApiService.baseUrl);
      // final wsHost = baseUri.host.isNotEmpty ? baseUri.host : "192.168.60.132";
      final wsUrl =
          "ws://$baseUri:8008/ws/tickets/conversations?ticket_id=${widget.ticketId}";

      debugPrint("Connecting to WS: $wsUrl");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('session_token') ?? '';
      final headers = token.isNotEmpty
          ? {"Authorization": "Bearer $token"}
          : null;

      _ws = await WebSocket.connect(
        wsUrl,
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      _isWsConnected = true;
      _lastWsError = "";
      if (mounted) setState(() {});

      _ws!.listen(
        (data) {
          debugPrint("WS Received data: $data");
          try {
            final decoded = jsonDecode(data);
            _handleIncomingWsMessage(decoded);
          } catch (e) {
            debugPrint("WS decode error: $e");
          }
        },
        onError: (err) {
          debugPrint("WS Error: $err");
          _isWsConnected = false;
          _lastWsError = err.toString();
          if (mounted) setState(() {});
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint("WS Connection closed");
          _isWsConnected = false;
          if (mounted) setState(() {});
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint("WS connection failed: $e");
      _isWsConnected = false;
      _lastWsError = e.toString();
      if (mounted) setState(() {});
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isWsConnected) {
        _connectWebSocket();
      }
    });
  }

  void _handleIncomingWsMessage(dynamic decoded) {
    if (decoded == null) return;
    Map<String, dynamic> msgMap = {};
    if (decoded is Map) {
      msgMap = Map<String, dynamic>.from(decoded);
    } else {
      return;
    }

    var chatMsg = ChatMessage.fromJson(msgMap);
    if (chatMsg.id.isEmpty) return;

    // Safety: if the message is from me, ensure it has my sender info
    if (chatMsg.senderId == _userId && _userId.isNotEmpty) {
      if (chatMsg.senderName == 'Ekipa' || chatMsg.senderName.isEmpty) {
        chatMsg = chatMsg.copyWith(
          senderName: _userName.isNotEmpty ? _userName : "Ha'u",
        );
      }
      if (chatMsg.senderEmail.isEmpty) {
        chatMsg = chatMsg.copyWith(senderEmail: _userEmail);
      }
    }

    // Check if message is already in list (avoid duplicates)
    final exists = _conversations.any((m) => m.id == chatMsg.id);
    if (exists) return;

    if (mounted) {
      setState(() {
        _conversations.add(chatMsg);
        _sortMessages(_conversations);
      });
    }
  }

  // --- LOAD DATA HUSI BACKEND ---
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final endpoint = _activeTab == 0
          ? "/api/v1/tickets/${widget.ticketId}/conversations"
          : "/api/v1/tickets/${widget.ticketId}/notes";

      final response = await ApiService().get(endpoint);
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

        setState(() {
          if (_activeTab == 0) {
            _conversations = fetchedList
                .map((x) => ChatMessage.fromJson(Map<String, dynamic>.from(x)))
                .toList();
            _sortMessages(_conversations);
          } else {
            _notes = fetchedList
                .map((x) => ChatMessage.fromJson(Map<String, dynamic>.from(x)))
                .toList();
            _sortMessages(_notes);
          }
        });
      } else {
        _showSnackBarError("Erro foti istória: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
      _showSnackBarError("Erro koneksaun: Network is unreachable");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortMessages(List<ChatMessage> list) {
    list.sort((a, b) {
      var idA = int.tryParse(a.id) ?? 0;
      var idB = int.tryParse(b.id) ?? 0;
      if (idA != 0 && idB != 0) {
        return idA.compareTo(idB);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  bool _isMe(ChatMessage msg) {
    if (msg.senderId == _userId && _userId.isNotEmpty) return true;
    if (msg.senderEmail == _userEmail && _userEmail.isNotEmpty) return true;
    if (msg.senderName == _userName && _userName.isNotEmpty) return true;
    if (msg.senderName == 'Me' || msg.senderName == 'Ha\'u') return true;
    return false;
  }

  String _stripHtmlTags(String htmlText) {
    if (htmlText.isEmpty) return htmlText;
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    String stripped = htmlText.replaceAll(exp, '');
    stripped = stripped
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return stripped.trim();
  }

  void _showSnackBarError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- TAKE PHOTO & SEND IMAGE ---
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
    );

    if (photo == null) return;

    final tempMsg = ChatMessage(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      senderId: _userId,
      senderName: "Ha'u",
      senderEmail: _userEmail,
      message: "[Photo]",
      imageUrl: "",
      type: "image",
      createdAt: DateTime.now().toIso8601String(),
      isSending: true,
      localImageFile: File(photo.path),
    );

    setState(() {
      if (_activeTab == 0) {
        _conversations.add(tempMsg);
      } else {
        _notes.add(tempMsg);
      }
    });

    try {
      final endpoint = _activeTab == 0
          ? "/api/v1/tickets/${widget.ticketId}/conversations?ticket_id=${widget.ticketId}"
          : "/api/v1/tickets/${widget.ticketId}/notes?ticket_id=${widget.ticketId}";

      final streamedResponse = await ApiService().multipartPost(
        endpoint,
        fields: {"body": "[Photo]"},
        imageFile: File(photo.path),
        imageField: "image",
      );

      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        setState(() {
          if (_activeTab == 0) {
            _conversations.removeWhere((m) => m.id == tempMsg.id);
            ChatMessage newMsg = decoded is Map
                ? ChatMessage.fromJson(Map<String, dynamic>.from(decoded))
                : tempMsg.copyWith(isSending: false);
            final newId = newMsg.id;
            if (newId.isNotEmpty && !_conversations.any((m) => m.id == newId)) {
              _conversations.add(newMsg);
            }
            _sortMessages(_conversations);
          } else {
            _notes.removeWhere((m) => m.id == tempMsg.id);
            ChatMessage newMsg = decoded is Map
                ? ChatMessage.fromJson(Map<String, dynamic>.from(decoded))
                : tempMsg.copyWith(isSending: false);
            final newId = newMsg.id;
            if (newId.isNotEmpty && !_notes.any((m) => m.id == newId)) {
              _notes.add(newMsg);
            }
            _sortMessages(_notes);
          }
        });
      } else {
        _showSnackBarError("Erro upload imajen: ${response.statusCode}");
        setState(() {
          if (_activeTab == 0) {
            _conversations.removeWhere((m) => m.id == tempMsg.id);
          } else {
            _notes.removeWhere((m) => m.id == tempMsg.id);
          }
        });
      }
    } catch (e) {
      debugPrint("Error sending image: $e");
      _showSnackBarError("Erro upload imajen: Network error");
      setState(() {
        if (_activeTab == 0) {
          _conversations.removeWhere((m) => m.id == tempMsg.id);
        } else {
          _notes.removeWhere((m) => m.id == tempMsg.id);
        }
      });
    }
  }

  // --- SEND TEXT MESSAGE ---
  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    final tempMsg = ChatMessage(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      senderId: _userId,
      senderName: "Ha'u",
      senderEmail: _userEmail,
      message: text,
      imageUrl: "",
      type: "text",
      createdAt: DateTime.now().toIso8601String(),
      isSending: true,
    );

    setState(() {
      if (_activeTab == 0) {
        _conversations.add(tempMsg);
      } else {
        _notes.add(tempMsg);
      }
    });

    try {
      final endpoint = _activeTab == 0
          ? "/api/v1/tickets/${widget.ticketId}/conversations?ticket_id=${widget.ticketId}"
          : "/api/v1/tickets/${widget.ticketId}/notes?ticket_id=${widget.ticketId}";

      final body = {"body": text};

      final response = await ApiService().post(endpoint, body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        setState(() {
          if (_activeTab == 0) {
            _conversations.removeWhere((m) => m.id == tempMsg.id);
            ChatMessage newMsg = decoded is Map
                ? ChatMessage.fromJson(Map<String, dynamic>.from(decoded))
                : tempMsg.copyWith(isSending: false);

            // Safety: if the message was sent by me, ensure it has my sender info
            if (newMsg.senderId.isEmpty) {
              newMsg = newMsg.copyWith(senderId: _userId);
            }
            if (newMsg.senderName == 'Ekipa' || newMsg.senderName.isEmpty) {
              newMsg = newMsg.copyWith(
                senderName: _userName.isNotEmpty ? _userName : "Ha'u",
              );
            }
            if (newMsg.senderEmail.isEmpty) {
              newMsg = newMsg.copyWith(senderEmail: _userEmail);
            }

            final newId = newMsg.id;
            if (newId.isNotEmpty && !_conversations.any((m) => m.id == newId)) {
              _conversations.add(newMsg);
            }
            _sortMessages(_conversations);
          } else {
            _notes.removeWhere((m) => m.id == tempMsg.id);
            ChatMessage newMsg = decoded is Map
                ? ChatMessage.fromJson(Map<String, dynamic>.from(decoded))
                : tempMsg.copyWith(isSending: false);

            if (newMsg.senderId.isEmpty) {
              newMsg = newMsg.copyWith(senderId: _userId);
            }
            if (newMsg.senderName == 'Ekipa' || newMsg.senderName.isEmpty) {
              newMsg = newMsg.copyWith(
                senderName: _userName.isNotEmpty ? _userName : "Ha'u",
              );
            }
            if (newMsg.senderEmail.isEmpty) {
              newMsg = newMsg.copyWith(senderEmail: _userEmail);
            }

            final newId = newMsg.id;
            if (newId.isNotEmpty && !_notes.any((m) => m.id == newId)) {
              _notes.add(newMsg);
            }
            _sortMessages(_notes);
          }
        });
      } else {
        // Extract exact error payload from server for better troubleshooting
        String errorDetail = "";
        try {
          final decodedError = jsonDecode(response.body);
          if (decodedError is Map) {
            errorDetail =
                decodedError['message']?.toString() ??
                decodedError['error']?.toString() ??
                response.body;
          } else {
            errorDetail = response.body;
          }
        } catch (_) {
          errorDetail = response.body;
        }

        final showMsg = errorDetail.isNotEmpty
            ? "Erro ${response.statusCode}: $errorDetail"
            : "Erro haruka mensajen: ${response.statusCode}";

        _showSnackBarError(showMsg);

        setState(() {
          if (_activeTab == 0) {
            _conversations.removeWhere((m) => m.id == tempMsg.id);
          } else {
            _notes.removeWhere((m) => m.id == tempMsg.id);
          }
        });
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      _showSnackBarError("Erro haruka mensajen: Network error ($e)");
      setState(() {
        if (_activeTab == 0) {
          _conversations.removeWhere((m) => m.id == tempMsg.id);
        } else {
          _notes.removeWhere((m) => m.id == tempMsg.id);
        }
      });
    }
  }

  void _switchTab(int index) {
    if (_activeTab == index) return;
    setState(() {
      _activeTab = index;
    });
    _loadHistory();
  }

  // --- FINALIZE TICKET PROCESS ---
  Future<void> _finalizeTicket() async {
    try {
      final response = await ApiService().post(
        "/api/v1/tickets/${widget.ticketId}/solve",
        {"status": "SOLVED"},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ticket Finalize Ho Ita-nia Ekipa"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onFinalize();
        Navigator.pop(context); // Pop back to detail
      } else {
        _showSnackBarError("Erro finaliza ticket: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error finalizing ticket: $e");
      _showSnackBarError("Erro koneksaun: Network is unreachable");
    }
  }

  void _handleFinalize() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Finalize Ticket?"),
          ],
        ),
        content: const Text(
          "Ita Fiar duni atu finaliza ticket ne?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Kansela", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeTicket();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _activeTab == 0 ? _conversations : _notes;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chat: ${widget.ticketId}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_activeTab == 0)
              GestureDetector(
                onTap: () {
                  if (!_isWsConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "WebSocket Error: ${_lastWsError.isNotEmpty ? _lastWsError : 'La bele kria ligasaun'}",
                        ),
                        backgroundColor: Colors.redAccent,
                        action: SnackBarAction(
                          label: "Tenta Fali",
                          textColor: Colors.white,
                          onPressed: _initWebSocket,
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isWsConnected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isWsConnected
                          ? "Real-time Ligadu"
                          : "Online (Harek Detallu)",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: _handleFinalize,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                "FINALIZA",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // CUSTOM TAB SELECTOR WITH PREMIUM DESIGN
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchTab(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 0
                            ? Colors.redAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          "💬 Chat Ekipa",
                          style: TextStyle(
                            color: _activeTab == 0
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchTab(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 1
                            ? Colors.amber[700]
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          "🔒 Nota Privadi",
                          style: TextStyle(
                            color: _activeTab == 1
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MESSAGE LIST WITH PULL TO REFRESH
          Expanded(
            child: _isLoading && messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: Colors.redAccent,
                    child: messages.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      _activeTab == 0
                                          ? Icons.chat_bubble_outline
                                          : Icons.lock_outline,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _activeTab == 0
                                          ? "Seidauk iha chat..."
                                          : "Seidauk iha note...",
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              var m = messages.reversed.toList()[index];
                              return _buildChatBubble(m);
                            },
                          ),
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildImageWidget(File? localImageFile, String imageUrl) {
    if (localImageFile != null) {
      return Image.file(localImageFile, width: 220, fit: BoxFit.cover);
    }

    if (imageUrl.isNotEmpty) {
      String fullUrl = imageUrl;
      if (!imageUrl.startsWith("http://") && !imageUrl.startsWith("https://")) {
        fullUrl = "${ApiService.baseUrl}$imageUrl";
      }
      return Image.network(
        fullUrl,
        width: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            width: 220,
            height: 150,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 220,
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey, size: 30),
                SizedBox(height: 5),
                Text(
                  "Erro karga imajen",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChatBubble(ChatMessage m) {
    final isMe = _isMe(m);
    final isImage =
        m.type == 'image' || m.imageUrl.isNotEmpty || m.localImageFile != null;
    final messageText = _stripHtmlTags(m.message);
    final imageUrl = m.imageUrl;
    final isSending = m.isSending;
    final timeStr = m.createdAt.split('T')[1].substring(0, 5);
    final senderName = m.senderName;
    final isNote = _activeTab == 1;

    final Color bubbleColor;
    final Color textColor;
    if (isNote) {
      bubbleColor = isMe ? Colors.amber[800]! : Colors.amber[50]!;
      textColor = isMe ? Colors.white : Colors.black87;
    } else {
      bubbleColor = isMe ? Colors.redAccent : Colors.grey[200]!;
      textColor = isMe ? Colors.white : Colors.black87;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe || isNote) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNote)
                    Icon(
                      Icons.lock,
                      size: 11,
                      color: isMe ? Colors.amber[200] : Colors.amber[700],
                    ),
                  if (isNote) const SizedBox(width: 4),
                  Text(
                    isMe
                        ? "(Private Note)"
                        : (isNote ? "$senderName (Internal)" : senderName),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe
                          ? Colors.amber[100]
                          : (isNote ? Colors.amber[950] : Colors.red[800]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImageWidget(m.localImageFile, imageUrl),
              )
            else
              Text(
                messageText,
                style: TextStyle(color: textColor, fontSize: 14.5, height: 1.3),
              ),

            const SizedBox(height: 6),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                  ),
                ),
                if (isMe && isSending) ...[
                  const SizedBox(width: 5),
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    final isNote = _activeTab == 1;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.grey),
              onPressed: _takePhoto,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgController,
                  decoration: InputDecoration(
                    hintText: isNote
                        ? "Hakerek private note..."
                        : "Hakerek mensajen...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: isNote ? Colors.amber[700] : Colors.redAccent,
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
