import 'package:equatable/equatable.dart';

import '../enums.dart';
import '../utils/enum_helper.dart';

class Message extends Equatable {
  Message({
    this.type,
    this.id,
    this.text,
    this.url,
    this.urls,
    this.options,
    this.createdAt,
    this.isSelf = false,
    this.arrayActionEnded = false,
    this.data,
  });

  final MessageType type;
  final String id;
  final String text;
  final String url;
  final List<String> urls;
  final List<Option> options;
  final DateTime createdAt;
  final bool isSelf;
  final bool arrayActionEnded;
  final Map<String, dynamic> data;

  Message copyWith({
    MessageType type,
    String id,
    String text,
    String url,
    List<String> urls,
    List<Option> options,
    DateTime createdAt,
    bool isSelf,
    bool arrayActionEnded,
    Map<String, dynamic> data,
  }) {
    return Message(
      type: type ?? this.type,
      id: id ?? this.id,
      text: text ?? this.text,
      url: url ?? this.url,
      urls: urls ?? this.urls,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      isSelf: isSelf ?? this.isSelf,
      arrayActionEnded: arrayActionEnded ?? this.arrayActionEnded,
      data: data ?? this.data,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final attachment = json['message']['attachment'];
    final attachments = json['message']['attachments'];
    var optElements;

    MessageType type = MessageType.text;
    if (attachment != null) {
      type = EnumHelper.getEnum(attachment['type'], MessageType.values);
    } else if (attachments != null) {
      type = MessageType.gallery;
    }

    if (type == MessageType.option) {
      optElements = attachment['payload']['elements'];
    }

    final createdAt =
        DateTime.tryParse(json['message']['createdAt'] ?? '') ?? DateTime.now();

    return Message(
      type: type,
      id: json['msg_id'] as String,
      text: json['message']['text'] as String,
      url: attachment != null ? attachment['payload']['url'] as String : null,
      urls: attachments != null
          ? (attachments as List)
              .map<String>((ele) => ele['payload']['url'] as String)
              .toList()
          : null,
      options: optElements != null
          ? (optElements as List).map<Option>((opt) {
              return Option(
                label: opt['label'] as String,
                value: opt['value'] as String,
              );
            }).toList()
          : null,
      createdAt: createdAt,
      data: json,
    );
  }

  @override
  List<Object> get props => [
        type,
        id,
        text,
        url,
        urls,
        options,
        createdAt,
        isSelf,
        arrayActionEnded,
        data
      ];

  @override
  String toString() => '''
  Message {
    type: $type,
    text: $text,
  }''';
}

class Option {
  Option({this.label, this.value});

  final String label;
  final String value;
}
