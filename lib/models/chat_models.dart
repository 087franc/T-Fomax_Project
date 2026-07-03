import 'dart:io';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String message;
  final String imageUrl;
  final String type; // 'text' or 'image'
  final String createdAt;
  final bool isSending;
  final File? localImageFile;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.message,
    required this.imageUrl,
    required this.type,
    required this.createdAt,
    this.isSending = false,
    this.localImageFile,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> rawJson) {
    Map<String, dynamic> json = rawJson;
    if (rawJson.containsKey('data') && rawJson['data'] is Map) {
      json = Map<String, dynamic>.from(rawJson['data']);
    }

    // Extract sender name
    String sName = 'Ekipa';
    if (json['creator'] is Map) {
      sName = json['creator']['name']?.toString() ?? 'Ekipa';
    } else {
      sName = json['sender_name']?.toString() ?? 
             json['user_name']?.toString() ?? 
             json['sender']?.toString() ?? 
             json['user']?.toString() ?? 
             'Ekipa';
    }
    if (sName == 'Me') sName = 'Ha\'u';

    // Extract sender id
    String sId = '';
    if (json['creator'] is Map) {
      sId = json['creator']['id']?.toString() ?? '';
    }
    if (sId.isEmpty) {
      sId = json['created_by']?.toString() ??
            json['sender_id']?.toString() ?? 
            json['user_id']?.toString() ?? 
            json['sender']?.toString() ?? 
            '';
    }

    // Extract message/content
    var contentVal = json['content'];
    String rawMsg = json['body']?.toString() ??
                    json['message']?.toString() ?? 
                    (contentVal is String ? contentVal : '');
    String msg = _stripHtmlTags(rawMsg);

    // Image URL
    String imgUrl = '';
    if (json['image'] != null && json['image'].toString() != 'null' && json['image'].toString().isNotEmpty) {
      imgUrl = json['image'].toString();
    } else if (json['image_url'] != null && json['image_url'].toString() != 'null' && json['image_url'].toString().isNotEmpty) {
      imgUrl = json['image_url'].toString();
    }

    // Type
    String msgType = json['type']?.toString() ?? 'text';
    if (msgType == 'null' || msgType.isEmpty) {
      msgType = 'text';
    }
    if (imgUrl.isNotEmpty) {
      msgType = 'image';
    }

    // Created At
    String dateStr = json['created_at']?.toString() ?? 
                     json['time']?.toString() ?? 
                     DateTime.now().toIso8601String();

    File? localFile;
    if (contentVal is File) {
      localFile = contentVal;
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: sId,
      senderName: sName,
      senderEmail: json['sender_email']?.toString() ?? json['email']?.toString() ?? '',
      message: msg,
      imageUrl: imgUrl,
      type: msgType,
      createdAt: dateStr,
      isSending: json['isSending'] == true,
      localImageFile: localFile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_email': senderEmail,
      'message': message,
      'image': imageUrl,
      'type': type,
      'created_at': createdAt,
      'isSending': isSending,
    };
  }

  // Helper method to format time string for displaying in bubble
  String get timeFormatted {
    if (createdAt.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(createdAt);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      if (createdAt.length > 16) {
        try {
          DateTime dt = DateTime.parse(createdAt.substring(0, 16));
          return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        } catch (_) {}
      }
      return createdAt;
    }
  }

  static String _stripHtmlTags(String htmlText) {
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

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? message,
    String? imageUrl,
    String? type,
    String? createdAt,
    bool? isSending,
    File? localImageFile,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isSending: isSending ?? this.isSending,
      localImageFile: localImageFile ?? this.localImageFile,
    );
  }
}
