import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class MessageInput extends StatefulWidget {
  final Function(ChatMessage) onSendMessage;

  const MessageInput({super.key, required this.onSendMessage});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();

  void _handleSend() {
    if (_textController.text.trim().isNotEmpty) {
      // Create and send the message
      final message = ChatMessage(
        message: _textController.text.trim(),
        timestamp: DateTime.now(),
        isUsers: true,
      );

      widget.onSendMessage(message);

      // TODO: Add server communication here
      // Example: apiService.sendMessage(message);

      // Clear the input field
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button (15%)
          Container(
            width: MediaQuery.of(context).size.width * 0.15,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.attach_file),
          ),

          const SizedBox(width: 8.0),

          // Microphone button (15%)
          Container(
            width: MediaQuery.of(context).size.width * 0.15,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.mic),
          ),

          const SizedBox(width: 8.0),

          // Text input field (50%)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Colors.grey[200],
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type here...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8.0),

          // Send button (15%)
          Container(
            width: MediaQuery.of(context).size.width * 0.15,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.blue,
            ),
            child: InkWell(
              onTap: _handleSend,
              child: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}