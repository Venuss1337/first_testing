import 'package:hive/hive.dart';

import '../models/hive_chat_message.dart';

/// Repository for managing chat data with Hive storage
class ChatRepository {
  /// Constants for Hive box names
  static const String MESSAGE_BOX = 'messages';
  static const String CHAT_BOX = 'chats';

  /// Maximum number of messages to keep in memory per chat
  static const int MESSAGE_LIMIT = 50;

  /// Save a single message to Hive
  Future<void> saveMessage(ChatMessage message) async {
    final box = Hive.box<ChatMessage>(MESSAGE_BOX);
    await box.add(message);
  }

  /// Save multiple messages at once
  Future<void> saveMessages(List<ChatMessage> messages) async {
    final box = Hive.box<ChatMessage>(MESSAGE_BOX);
    for (var message in messages) {
      await box.add(message);
    }
  }

  /// Load paginated messages for a specific chat
  /// [skip] - How many messages to skip from the start
  /// [limit] - Maximum number of messages to return
  Future<List<ChatMessage>> loadMessages(
      String chatId, {
        int skip = 0,
        int limit = MESSAGE_LIMIT
      }) async {
    final box = Hive.box<ChatMessage>(MESSAGE_BOX);

    // Filter messages for this chat and sort by timestamp (newest first)
    final allMessages = box.values
        .where((msg) => msg.chatId == chatId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply pagination
    if (skip >= allMessages.length) {
      return [];
    }

    final end = skip + limit > allMessages.length ? allMessages.length : skip + limit;
    return allMessages.sublist(skip, end);
  }

  /// Save or update chat metadata
  Future<void> saveChat(ActiveChat chat) async {
    final box = Hive.box<ActiveChat>(CHAT_BOX);

    // Find existing chat or add new one
    final existingChats = box.values.where((c) => c.id == chat.id).toList();
    if (existingChats.isNotEmpty) {
      final index = box.values.toList().indexOf(existingChats.first);
      await box.putAt(index, chat);
    } else {
      await box.add(chat);
    }
  }

  /// Load all chats metadata (without messages)
  Future<List<ActiveChat>> loadAllChats() async {
    final box = Hive.box<ActiveChat>(CHAT_BOX);
    return box.values.toList();
  }

  /// Load all chats with their most recent messages
  Future<List<ActiveChat>> loadInitialChats() async {
    final chats = await loadAllChats();

    // Load the most recent messages for each chat
    for (var chat in chats) {
      chat.messages = await loadMessages(chat.id);

      // TODO: Load display names or other metadata if needed
      chat.displayName ??= "Chat ${chat.id}";
    }

    return chats;
  }

  /// Mark a chat as seen
  Future<void> markChatAsSeen(String chatId) async {
    final box = Hive.box<ActiveChat>(CHAT_BOX);
    final chats = box.values.where((c) => c.id == chatId).toList();

    if (chats.isNotEmpty) {
      final chat = chats.first;
      if (!chat.seen) {
        chat.seen = true;
        final index = box.values.toList().indexOf(chat);
        await box.putAt(index, chat);
      }
    }
  }

  /// Delete a message
  Future<void> deleteMessage(ChatMessage message) async {
    // TODO: Implement message deletion logic
    // This would require tracking keys or indices of messages
  }

  /// Delete an entire chat and all its messages
  Future<void> deleteChat(String chatId) async {
    // TODO: Implement chat deletion logic
    // Should delete both chat metadata and all associated messages
  }
}