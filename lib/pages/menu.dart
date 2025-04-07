import 'package:first_testing/pages/chat.dart';
import 'package:first_testing/repository/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../models/hive_chat_message.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Text(
                'Filagram',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24.0, right: 16.0),
              child: Icon(
                Icons.account_circle,
                size: 40.0,
              ),
            ),
          ],
        )
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 24.0, left: 16.0, bottom: 16.0),
            child: CustomSelectBar()
          ),
          Expanded(
            child: ChatListWidget(chats: myChats),
          ),
        ],
      )
    );
  }
}
class CustomSelectBar extends StatefulWidget {
  const CustomSelectBar({super.key});


  @override
  _CustomSelectBarState createState() => _CustomSelectBarState();
}

class _CustomSelectBarState extends State<CustomSelectBar> {
  int _selectedIndex = 0;
  final List<String> options = ['All chats', 'Starred', 'Blocked'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          return Padding(
            padding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedIndex == index ? Colors.grey[600] : null,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  options[index],
                  style: TextStyle(
                    color: _selectedIndex == index ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/*
* This is going to be in the shared preferences, but I don't know exactly, whether its going to be fetched or what yet
* Probably will be different endpoints for all that
* A also need to do all the application synchronized, so some function are not ahead of others..
*/
var uuid = Uuid();
var chatUuid1 = uuid.v7();
var chatUuid2 = uuid.v7();
final List<ActiveChat> myChats = [
  ActiveChat(
    id: chatUuid1,
    avatar: 'https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/avatars/ce/cedde8131a9406a99c0faaa0507fc94e94ff0cd7.jpg', // Replace with Material icon
    seen: false,
    displayName: 'John elter',
    messages: [
      ChatMessage(message: "something", timestamp: DateTime.now(), isUser: false, chatId: chatUuid1 )
    ]
  ),
  ActiveChat(
    id: chatUuid2,
    avatar: 'https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/avatars/00/00ace7b1db06bb151760635aa8814948328fbffb.jpg', // Replace with Material icon
    seen: false,
    displayName: 'John elter',
    messages: [
      ChatMessage(message: "something", timestamp: DateTime.now(), isUser: false, chatId: chatUuid2 ),
      ChatMessage(message: "something more", timestamp: DateTime.now(), isUser: true, chatId: chatUuid2 )
    ]
  ),
];

class ChatListWidget extends StatelessWidget {
  final List<ActiveChat> chats;

  const ChatListWidget({required this.chats, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${state.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Add retry functionality
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, colors: Colors.grey),
                SizedBox(height: 16),
                Text('No chats available'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Start a new chat
                  },
                  child: Text('Start a new chat'))
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: state.chats.length,
          itemBuilder: (context, index) {
            // NOTE: Getting the chat

            final chat = state.chats[index];
            final lastMessage = chat.messages.isNotEmpty ? chat.messages.first : null;

            return ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show dot indicator for unseen messages
                  if (!chat.seen)
                    Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: _getAvatarImage(chat.avatar),
                    child: chat.avatar.isEmpty ? Text(chat.id.substring(0, 1).toUpperCase()) : null,
                  ),
                ],
              ),
              title: Text(
                chat.displayName ?? 'Chat ${chat.id}',
                style: TextStyle(
                  fontWeight: chat.seen ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                lastMessage != null
                    ?
                lastMessage.message
                    :
                "No messages yet",
                style: TextStyle(
                  fontWeight: chat.seen ? FontWeight.normal : FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                lastMessage != null ? _formatTimestamp(lastMessage.timestamp) : '',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      chatId: chat.id
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    );
  }
  /// Get the appropriate image provider for the avatar
  ImageProvider _getAvatarImage(String avatar) {
    if (avatar.isEmpty) {
      return AssetImage('assets/images/default_avatar.png');
    } else if (avatar.startsWith('http')) {
      return NetworkImage(avatar);
    } else {
      return AssetImage(avatar);
    }
  }

  /// Format the timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today, show time
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      // This week, show day name
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older, show date
      return '${timestamp.day}/${timestamp.month}';
    }
  }
  
  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}