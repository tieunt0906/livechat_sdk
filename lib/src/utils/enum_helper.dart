import 'package:recase/recase.dart';

class EnumHelper {
  EnumHelper._();

  static String getName<T>(T enumValue,
      {String Function(String value) rescase = recase}) {
    final String name = enumValue.toString();
    final int period = name.indexOf('.');

    return recase(name.substring(period + 1));
  }

  static String recase(String value) {
    return ReCase(value).constantCase;
  }

  static T getEnum<T>(String enumName, List<T> values) {
    final String cleanedName = recase(enumName);
    return values.firstWhere(
      (ele) => cleanedName == getName<T>(ele),
      orElse: () => null,
    );
  }
}
