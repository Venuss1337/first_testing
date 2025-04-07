import 'dart:ui';

import 'package:first_testing/models/chat_message.dart';

class ActiveChat {
  String id;
  String icon;
  String name;
  String lastMessage;
  DateTime lastMessageTime;
  bool seen;
  List<ChatMessage> recentChatMessages;

  ActiveChat({
    required this.id,
    required this.icon,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.seen,
    required this.recentChatMessages,
  });
}