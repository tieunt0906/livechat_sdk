# livechat_sdk

This Flutter plugin supports messaging using live chat service.

## Getting Started

### Add dependency

Add this to your package's pubspec.yaml file, use git dependency with specific branch

```yaml
dependencies:
  livechat_sdk:
    git:
      url: https://github.com/tieunt0906/livechat_sdk.git
      ref: develop
```

then run `flutter pub get` to install package

### Setup API Client
First you need to create chat client to initiate connection with baseUrl and appId parameters

```dart
final client = LivechatClient(
    baseUrl: 'websocket url',
    appId: 'your app id',
);
```

Currently, this package supports you to send 6 message types
1. Text
```dart
client.sendTextMessage('your text message');
```

2. Image
```dart
client.sendImage('imageUrl', text: 'description');
```

3. Audio
```dart
client.sendAudio('audioUrl', text: 'description');
```

4. Video
```dart
client.sendVideo('videoUrl', text: 'description');
```

5. File
```dart
client.sendFile('fileUrl', text: 'description');
```

6. Gallery
```dart
client.sendImages(['imageUrl'], text: 'description');
```
