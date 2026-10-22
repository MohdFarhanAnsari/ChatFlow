import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

enum MessageStatus { sending, sent, read }

/// Represents quoted context when a user replies to another message.
class ReplyContext {
  final String messageId;
  final String text;
  final String senderName;

  const ReplyContext({
    required this.messageId,
    required this.text,
    required this.senderName,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'text': text,
      'senderName': senderName,
    };
  }

  factory ReplyContext.fromMap(Map<String, dynamic> map) {
    return ReplyContext(
      messageId: map['messageId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'User',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplyContext &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId &&
          text == other.text &&
          senderName == other.senderName;

  @override
  int get hashCode => messageId.hashCode ^ text.hashCode ^ senderName.hashCode;
}

/// Represents a single chat message in ChatFlow.
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final DateTime? timestamp;
  final MessageStatus status;
  final List<String> readBy;
  final ReplyContext? replyTo;
  final Map<String, List<String>> reactions;
  final bool isDeleted;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    this.timestamp,
    this.status = MessageStatus.sent,
    this.readBy = const [],
    this.replyTo,
    this.reactions = const {},
    this.isDeleted = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    String? mediaUrl,
    DateTime? timestamp,
    MessageStatus? status,
    List<String>? readBy,
    ReplyContext? replyTo,
    Map<String, List<String>>? reactions,
    bool? isDeleted,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'status': status.name,
      'readBy': readBy,
      'replyTo': replyTo?.toMap(),
      'reactions': reactions,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp?.toIso8601String(),
      'status': status.name,
      'readBy': readBy,
      'replyTo': replyTo?.toMap(),
      'reactions': reactions,
      'isDeleted': isDeleted,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    MessageType parseType(dynamic val) {
      if (val == 'image') return MessageType.image;
      return MessageType.text;
    }

    MessageStatus parseStatus(dynamic val) {
      if (val == 'sending') return MessageStatus.sending;
      if (val == 'read') return MessageStatus.read;
      return MessageStatus.sent;
    }

    // Parse reactions map: emoji -> List of UIDs
    final rawReactions = map['reactions'];
    final Map<String, List<String>> reactionsMap = {};
    if (rawReactions is Map) {
      rawReactions.forEach((key, value) {
        if (value is List) {
          reactionsMap[key.toString()] = value.map((e) => e.toString()).toList();
        }
      });
    }

    final rawReadBy = map['readBy'];
    final List<String> readByList = (rawReadBy is List)
        ? rawReadBy.map((e) => e.toString()).toList()
        : [];

    final rawReply = map['replyTo'];
    final ReplyContext? reply = (rawReply is Map<String, dynamic>)
        ? ReplyContext.fromMap(rawReply)
        : null;

    return Message(
      id: id ?? map['id'] as String? ?? '',
      conversationId: map['conversationId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      type: parseType(map['type']),
      mediaUrl: map['mediaUrl'] as String?,
      timestamp: parseTimestamp(map['timestamp']),
      status: parseStatus(map['status']),
      readBy: readByList,
      replyTo: reply,
      reactions: reactionsMap,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          receiverId == other.receiverId &&
          text == other.text &&
          type == other.type &&
          mediaUrl == other.mediaUrl &&
          status == other.status &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode =>
      id.hashCode ^
      conversationId.hashCode ^
      senderId.hashCode ^
      text.hashCode ^
      type.hashCode ^
      status.hashCode ^
      isDeleted.hashCode;
}
