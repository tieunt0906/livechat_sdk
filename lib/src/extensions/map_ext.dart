extension MapExt on Map {
  void omitIsNil({bool deep = false}) {
    final keys = List.from(this.keys);
    for (final key in keys) {
      final value = this[key];
      if (value is String) {
        if (value.trim().isEmpty) remove(key);
      } else if (value is Map) {
        if (deep) value.omitIsNil(deep: deep);
      } else if (value == null) remove(key);
    }
  }

  void omitBy(List removeKeys, {bool deep = false}) {
    final keys = List.from(this.keys);
    for (final key in keys) {
      final value = this[key];
      if (removeKeys.contains(key)) {
        remove(key);
      } else if (value is Map) {
        if (deep) value.omitBy(removeKeys, deep: deep);
      }
    }
  }
}
