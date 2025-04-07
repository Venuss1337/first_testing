import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/hive_chat_message.dart';
import './chat_repository.dart';
import '../services/mqtt_service.dart';
import '../services/encryption_service.dart';

/// State class for ChatCubit
class ChatState {
  /// List of all active chats with their cached messages
  final List<ActiveChat> chats;

  /// Flag to show if data is currently loading
  final bool isLoading;

  /// Error message if something went wrong
  final String? error;

  ChatState({
    required this.chats,
    this.isLoading = false,
    this.error,
  });

  /// Create a copy of this state with some fields changed
  ChatState copyWith({
    List<ActiveChat>? chats,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Cubit to manage chat state
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;
  final MqttService mqttService;
  final MessageEncryptionService encryptionService;

  ChatCubit({
    required this.repository,
    required this.mqttService,
    required this.encryptionService,
  }) : super(ChatState(chats: [], isLoading: true)) {
    _init();
  }

  /// Initialize the cubit
  Future<void> _init() async {
    try {
      // Load initial chats with limited messages
      final chats = await repository.loadInitialChats();
      emit(ChatState(chats: chats));

      // Set up MQTT
      await _setupMqtt();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  /// Set up MQTT connection and subscriptions
  Future<void> _setupMqtt() async {
    await mqttService.connect();

    // Subscribe to topics for each chat
    for (var chat in state.chats) {
      mqttService.subscribe('chat/${chat.id}/inbox');
    }

    // Set up message handler
    mqttService.onMessageReceived = _handleMqttMessage;
  }

  /// Handle incoming MQTT messages
  void _handleMqttMessage(String topic, String messageContent) {
    final chatId = mqttService.extractChatIdFromTopic(topic);
    final chatIndex = state.chats.indexWhere((c) => c.id == chatId);

    if (chatIndex >= 0) {
      final newMessage = ChatMessage(
        message: messageContent,
        timestamp: DateTime.now(),
        isUser: false,
        chatId: chatId,
      );

      // Save message to Hive
      repository.saveMessage(newMessage);

      // Update in-memory message list
      final updatedChats = List<ActiveChat>.from(state.chats);
      updatedChats[chatIndex].messages.insert(0, newMessage);
      updatedChats[chatIndex].seen = false;

      // Trim messages if needed
      _trimChatMessages(updatedChats[chatIndex]);

      emit(state.copyWith(chats: updatedChats));
    }
  }

  /// Trim messages in memory for a chat if it exceeds the limit
  void _trimChatMessages(ActiveChat chat) {
    if (chat.messages.length > ChatRepository.MESSAGE_LIMIT + 10) {
      // Keep only the most recent messages in memory
      // We add a buffer of 10 to avoid trimming too frequently
      final messagesToStore = chat.messages.sublist(ChatRepository.MESSAGE_LIMIT);
      chat.messages = chat.messages.sublist(0, ChatRepository.MESSAGE_LIMIT);

      // Save the trimmed messages if not already saved
      repository.saveMessages(messagesToStore);
    }
  }

  /// Load more messages for a specific chat
  /// Returns true if more messages were loaded
  Future<bool> loadMoreMessages(String chatId) async {
    try {
      final chatIndex = state.chats.indexWhere((c) => c.id == chatId);
      if (chatIndex < 0) return false;

      final chat = state.chats[chatIndex];
      final moreMessages = await repository.loadMessages(
        chatId,
        skip: chat.messages.length,
        limit: 20,  // Load 20 more messages
      );

      if (moreMessages.isEmpty) return false;

      final updatedChats = List<ActiveChat>.from(state.chats);
      updatedChats[chatIndex].messages.addAll(moreMessages);

      emit(state.copyWith(chats: updatedChats));
      return true;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Mark a chat as seen
  Future<void> markChatAsSeen(String chatId) async {
    try {
      await repository.markChatAsSeen(chatId);

      final chatIndex = state.chats.indexWhere((c) => c.id == chatId);
      if (chatIndex >= 0) {
        final updatedChats = List<ActiveChat>.from(state.chats);
        updatedChats[chatIndex].seen = true;
        emit(state.copyWith(chats: updatedChats));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Send a message
  Future<void> sendMessage(String chatId, String message) async {
    try {
      final chatIndex = state.chats.indexWhere((c) => c.id == chatId);
      if (chatIndex < 0) return;

      // Create message object
      final newMessage = ChatMessage(
        message: message,
        timestamp: DateTime.now(),
        isUser: true,
        chatId: chatId,
      );

      // Save to Hive
      await repository.saveMessage(newMessage);

      // Update in-memory list
      final updatedChats = List<ActiveChat>.from(state.chats);
      updatedChats[chatIndex].messages.insert(0, newMessage);

      // Trim if needed
      _trimChatMessages(updatedChats[chatIndex]);

      emit(state.copyWith(chats: updatedChats));

      // Send via MQTT
      mqttService.publishMessage('chat/$chatId/outbox', message);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Add a new chat
  /// TODO: Implement this method to create new chats
  Future<void> addChat(String chatId, String avatar) async {
    // Create new chat
    // Save to repository
    // Subscribe to MQTT topic
  }
}