import 'package:uuid/uuid.dart';

class UuidGenerator {
  factory UuidGenerator() {
    return _instance;
  }

  UuidGenerator._() {
    _uuid = Uuid();
  }

  static final UuidGenerator _instance = UuidGenerator._();

  Uuid _uuid;

  String generateUUIDByV4() {
    return _uuid.v4();
  }
}
