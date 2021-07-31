import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livechat_sdk/livechat_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _textController;

  LivechatClient _client;
  StreamSubscription _connectionStatusSubscription;
  StreamSubscription _messageSubscription;

  String _responseText = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    _client = LivechatClient(
      baseUrl: '',
      appId: '',
    );

    _connectionStatusSubscription =
        _client.connectionStatusStream.listen((status) {
      print('connectionStatus: $status');
    });

    _messageSubscription = _client.messageStream.listen((message) {
      setState(() {
        _responseText = message.text ?? '';
      });
    });

    _client.connect();
  }

  @override
  void dispose() {
    _connectionStatusSubscription.cancel();
    _messageSubscription.cancel();
    super.dispose();
  }

  void _onSendMessage() {
    final text = _textController.text.trim();
    _client.sendTextMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livechat Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type something',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _onSendMessage,
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Text(
              'Bot response: ',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _responseText,
                style: TextStyle(
                  fontSize: 15.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
