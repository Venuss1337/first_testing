class ChatMessage {
  String message;
  DateTime timestamp;
  bool isUsers;

  ChatMessage({
    required this.message,
    required this.timestamp,
    required this.isUsers,
  });
}