import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:rxdart/subjects.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'enums.dart';
import 'models/message.dart';
import 'utils/utils.dart';
import 'extensions/map_ext.dart';

const removeKeys = [
  'session_id',
  'asr_expected_data_type',
  'bot_expected_data_type',
  'asr_provider',
  'asr_breaking_time',
  'messages',
];

class LivechatClient {
  LivechatClient({
    @required this.baseUrl,
    @required this.appId,
    this.returnArrayAction = false,
  });

  final String baseUrl;
  final String appId;
  final bool returnArrayAction;

  WebSocketChannel _channel;
  bool _connecting = false;
  bool _reconnecting = false;
  bool _hasError = false;
  String _accessToken;

  final _connectionStatusController = BehaviorSubject<ConnectionStatus>();

  set _connectionStatus(ConnectionStatus status) =>
      _connectionStatusController.add(status);

  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  final _messageController = BehaviorSubject<Message>();

  Stream<Message> get messageStream => _messageController.stream;

  Future<void> connect() async {
    if (_connecting) {
      print('client already connected');
      return;
    }

    _connecting = true;
    _hasError = false;
    _connectionStatus = ConnectionStatus.connecting;

    _channel = IOWebSocketChannel.connect(baseUrl);
    _channel.stream.listen(
      (data) {
        final jsonData = json.decode(data);
        EventType type = EnumHelper.getEnum(jsonData['type'], EventType.values);

        if (jsonData['status'] == 1) {
          _reconnecting = false;
          _onData(jsonData);
        } else {
          final errorMessage = jsonData['error_message'];
          final bool reconnect =
              type == EventType.init || errorMessage == 'Unauthorized';
          _onConnectionErorr(errorMessage, reconnect);
        }
      },
      onError: (error, stacktrace) {
        _hasError = true;
        _reconnecting = false;
        _onConnectionErorr(error);
      },
      onDone: _onDone,
    );

    initConnection();
  }

  void initConnection() {
    _channel.sink.add(json.encode({
      'type': EnumHelper.getName(EventType.init),
      'app_id': appId,
      'return_array_action': returnArrayAction,
    }));
  }

  Future<String> sendTextMessage(String text) async {
    final String msgId = UuidGenerator().generateUUIDByV4();

    _channel.sink.add(json.encode({
      'type': EnumHelper.getName(EventType.chat),
      'app_id': appId,
      'access_token': _accessToken,
      'message': {
        'msgId': msgId,
        'text': text,
      },
    }));

    return msgId;
  }

  Future<String> sendImage(String imageUrl, {String text}) {
    return _sendFile(type: MessageType.image, url: imageUrl, text: text);
  }

  Future<String> sendAudio(String audioUrl, {String text}) {
    return _sendFile(type: MessageType.audio, url: audioUrl, text: text);
  }

  Future<String> sendVideo(String videoUrl, {String text}) {
    return _sendFile(type: MessageType.video, url: videoUrl, text: text);
  }

  Future<String> sendFile(String fileUrl, {String text}) {
    return _sendFile(type: MessageType.file, url: fileUrl, text: text);
  }

  Future<String> sendImages(List<String> imageUrls, {String text}) async {
    final String msgId = UuidGenerator().generateUUIDByV4();

    _channel.sink.add(json.encode({
      'type': EnumHelper.getName(EventType.chat),
      'app_id': appId,
      'access_token': _accessToken,
      'message': {
        'msgId': msgId,
        'text': text ?? '',
        'attachments': imageUrls.map((url) {
          return {
            'type': EnumHelper.getName(MessageType.image),
            'payload': {
              'url': url,
            },
          };
        }).toList(),
      },
    }));

    return msgId;
  }

  Future<String> _sendFile({
    @required MessageType type,
    @required String url,
    String text,
  }) async {
    final String msgId = UuidGenerator().generateUUIDByV4();

    _channel.sink.add(json.encode({
      'type': EnumHelper.getName(EventType.chat),
      'app_id': appId,
      'access_token': _accessToken,
      'message': {
        'msgId': msgId,
        'text': text ?? '',
        'attachment': {
          'type': EnumHelper.getName(type),
          'payload': {
            'url': url,
          }
        }
      },
    }));

    return msgId;
  }

  Future<void> _onData(jsonData) async {
    EventType type = EnumHelper.getEnum(jsonData['type'], EventType.values);

    if (type == EventType.init) {
      _connectionStatus = ConnectionStatus.connected;
      _accessToken = jsonData['access_token'];
    } else if (type == EventType.chat) {
      Map<String, dynamic> data = jsonData['data'] as Map<String, dynamic>;

      if (returnArrayAction) {
        final messages =
            (data['messages'] as List).cast<Map<String, dynamic>>();
        final length = messages.length;

        data.omitBy(removeKeys);

        for (int i = 0; i < length; i++) {
          final jsonMessage = messages[i];
          final action = jsonMessage['action'] as Map<String, dynamic>;
          jsonMessage.remove('action');

          data['action'] = action;
          data['message'] = jsonMessage;

          final newData = Map<String, dynamic>.from(data);
          Message message = Message.fromJson(newData);
          message = message.copyWith(arrayActionEnded: i == length - 1);
          _messageController.add(message);
        }
      } else {
        final Message message = Message.fromJson(data);
        _messageController.add(message);
      }
    }
  }

  Future<void> _onConnectionErorr(error, [bool reconnect = false]) async {
    print('connection error: $error');

    _connecting = false;

    if (!reconnect) {
      _connectionStatus = ConnectionStatus.disconnected;
    } else if (!_reconnecting) {
      _connectionStatus = ConnectionStatus.disconnected;
      await _reconnect();
    }
  }

  void _onDone() {
    _connecting = false;

    if (_hasError) return;

    if (!_reconnecting) {
      _reconnect();
    }
  }

  Future<void> _reconnect() async {
    if (!_reconnecting) {
      _reconnecting = true;
      _connectionStatus = ConnectionStatus.connecting;
    }

    await _channel.sink.close();
    await connect();
  }

  Future<void> disconnect() async {
    _connecting = false;
    print('disconnecting');
    _reconnecting = false;
    _connectionStatus = ConnectionStatus.disconnected;
    await Future.wait([
      _connectionStatusController.close(),
      _messageController.close(),
    ]);
    return _channel.sink.close();
  }
}
