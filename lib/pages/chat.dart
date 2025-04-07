import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/chat_message.dart';
import '../repository/chat_cubit.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({
    super.key,
    required this.chatId
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;


  @override
  void initState() {
    super.initState();

    // Mark chat as seen when opened
    context.read<ChatCubit>().markChatAsSeen(widget.chatId);

    // setup scroller listener for loading  more messages
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });

        context.read<ChatCubit>().loadMoreMessages(widget.chatId).then((hasMore) {
          setState(() {
            _isLoadingMore = false;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final chatIndex = state.chats.indexWhere((c) => c.id == widget.chatId);

        if (chatIndex < 0) {
          return Scaffold(
            appBar: AppBar(title: Text('chat')),
            body: Center(child: Text('chat has not been found!')),
          );
        }

        final chat = state.chats[chatIndex];

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              padding: const EdgeInsets.only(left: 16.0),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: chat.avatar.startsWith('http')
                      ? NetworkImage(chat.avatar)
                      : AssetImage(chat.avatar) as ImageProvider,
                ),
                const SizedBox(height: 8),
                Text(
                  chat.displayName ?? 'Chat ${chat.id}',
                  style: TextStyle(fontSize: 30, color: Colors.grey[500]),
                ),
              ],
            ),
            toolbarHeight: 100, // Increased height to accommodate avatar and name
          ),
          body: Column(
            children: [
              // Messages list (takes available space)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(
                      message: _messages[index],
                    );
                  },
                ),
              ),

              // Input bar (fixed at bottom)
              MessageInput(onSendMessage: _addMessage),
            ],
          ),
        );
      },
    );
  }
}