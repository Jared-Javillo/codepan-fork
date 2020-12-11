// ignore: sdk_version_extension_methods
import 'package:inflection2/inflection2.dart';

const _true = <String>['true', 'yes', 'on', '1'];
const _false = <String>['false', 'no', 'off', '0'];
const _lower = <String>['of', 'and', 'or', 'is', 'are', 'a', 'with', 'my'];

extension StringUtils on String {
  String capitalize() {
    final space = ' ';
    if (this.contains(space)) {
      final buffer = StringBuffer();
      final words = this.split(space);
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        if (_lower.contains(word) && i != 0) {
          buffer.write(word);
        } else {
          buffer.write('${word[0].toUpperCase()}${word.substring(1)}');
        }
        if (i < words.length - 1) {
          buffer.write(space);
        }
      }
      return buffer.toString();
    }
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }

  String decapitalize() {
    return '${this[0].toLowerCase()}${this.substring(1)}';
  }

  String nullify() {
    if (this != null && (this == 'null' || this.isEmpty)) {
      return null;
    }
    return this;
  }

  String complete(dynamic input) {
    final buffer = StringBuffer();
    final identifier = '\$';
    final separator = ' ';
    final list = <String>[];
    if (input is String) {
      list.add(input);
    } else if (input is List<String>) {
      list.addAll(input);
    }
    final iterator = list.iterator;
    final words = this.split(separator);
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.contains(identifier) && iterator.moveNext()) {
        buffer.write(iterator.current);
      } else {
        buffer.write(word);
      }
      if (i < words.length - 1) {
        buffer.write(separator);
      }
    }
    return buffer.toString();
  }

  String toSnake() {
    return SNAKE_CASE.convert(this);
  }

  String toPast() {
    final dash = '-';
    if (this.contains(dash)) {
      final first = this.split(dash).first;
      final past = PAST.convert(first);
      return this.replaceAll(first, past);
    }
    return PAST.convert(this);
  }

  String toSingular() {
    return SINGULAR.convert(this);
  }

  bool toBool() {
    if (_true.contains(this)) {
      return true;
    } else if (_false.contains(this)) {
      return false;
    }
    return null;
  }
}
