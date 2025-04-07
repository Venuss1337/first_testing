import 'package:hive/hive.dart';

/// Message model to store individual chat messages
@HiveType(typeId: 0)
class ChatMessage {
  /// The actual text content of the message
  @HiveField(0)
  final String message;

  /// When the message was sent/received
  @HiveField(1)
  final DateTime timestamp;

  /// Whether the current user sent this message
  @HiveField(2)
  final bool isUser;

  /// ID of the chat this message belongs to
  @HiveField(3)
  final String chatId;

  ChatMessage({
    required this.message,
    required this.timestamp,
    required this.isUser,
    required this.chatId,
  });
}

/// Model to represent an active chat conversation
@HiveType(typeId: 1)
class ActiveChat {
  /// Unique identifier for the chat
  @HiveField(0)
  final String id;

  /// URL or asset path to the chat avatar
  @HiveField(1)
  final String avatar;

  /// Whether the user has seen the latest messages
  @HiveField(2)
  bool seen;

  /// Display name for the chat (not stored in Hive)
  String? displayName;

  /// In-memory list of messages, not stored directly with Hive
  /// Only the most recent messages are kept here
  List<ChatMessage> messages = [];

  ActiveChat({
    required this.id,
    required this.avatar,
    this.seen = false,
    this.displayName,
    List<ChatMessage>? messages,
  }) {
    this.messages = messages ?? [];
  }
}