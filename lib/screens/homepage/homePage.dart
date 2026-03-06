import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ChatUser user = ChatUser(id: '2', firstName: 'Haga', lastName: 'Leclerc');

  List<ChatMessage> messages = <ChatMessage>[
    ChatMessage(
      text: 'Hey!',
      user: ChatUser(id: '1', firstName: 'Charles', lastName: 'Leclerc'),
      createdAt: DateTime.now(),
    ),
    ChatMessage(
      text: 'Hey!',
      user: ChatUser(id: '2', firstName: 'Haga', lastName: 'Leclerc'),
      createdAt: DateTime.now(),
    ),
    ChatMessage(
      text: 'Hey!',
      user: ChatUser(id: '1', firstName: 'Charles', lastName: 'Leclerc'),
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic example')),
      body: DashChat(
        currentUser: user,
        onSend: (ChatMessage m) {
          setState(() {
            messages.insert(0, m);
          });
        },
        messages: messages,
      ),
    );
  }
}
