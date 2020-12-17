import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:codepan/extensions/extensions.dart';
import 'package:codepan/models/date_time.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inflection2/inflection2.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

const _urlPattern =
    r'(https?|http)://([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?';
const printError = _printError;
const printLarge = _printLarge;

void _printError(dynamic error, StackTrace stacktrace) {
  debugPrint('${error?.toString()}: ${stacktrace?.toString()}');
}

void _printLarge(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

class PanUtils {
  static DateTimeData now() {
    final now = DateTime.now();
    return DateTimeData.format(now);
  }

  static DateTimeData splitDateTime(String input, {String pattern = ' '}) {
    if (input != null) {
      final data = input.split(pattern);
      if (data != null && data.length == 2) {
        return DateTimeData(
          date: data[0],
          time: data[1],
        );
      }
    }
    return null;
  }

  static String formatMoney(double input) {
    if (input == null) return null;
    final nf = NumberFormat('#,###.00', 'en_US');
    return nf.format(input);
  }

  static String formatDouble(String format, double input) {
    if (input == null) return null;
    final nf = NumberFormat(format, 'en_US');
    return nf.format(input);
  }

  static Future<File> getFile({
    String folder,
    @required String fileName,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    if (folder != null) {
      final dir = Directory('${root.path}/$folder');
      if (!await dir.exists()) {
        await dir.create();
      }
      return File('${dir.path}/$fileName');
    } else {
      return File('${root.path}/$fileName');
    }
  }

  static Future<Directory> getDirectory(
    String folder,
  ) async {
    final root = await getApplicationDocumentsDirectory();
    if (folder != null) {
      final dir = Directory('${root.path}/$folder');
      if (!await dir.exists()) {
        await dir.create();
      }
      return dir;
    }
    return root;
  }

  static Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile;
  }

  static bool isValidUrl(String url) {
    final match = RegExp(
      _urlPattern,
      caseSensitive: false,
    ).firstMatch(url);
    return match != null;
  }

  static void bindIsolatePort(SendPort sp, String name) {
    final result = IsolateNameServer.registerPortWithName(sp, name);
    if (!result) {
      IsolateNameServer.removePortNameMapping(name);
      bindIsolatePort(sp, name);
    }
  }

  static int parseInt(dynamic input) {
    return input is int ? input : int.tryParse(input.toString());
  }

  static double parseDouble(dynamic input) {
    return input is double ? input : double.tryParse(input.toString());
  }

  static bool parseBool(dynamic input) {
    if (input is bool) {
      return input;
    } else if (input is int) {
      final binary = parseInt(input);
      return binary.toBool();
    } else if (input is String) {
      return input.toBool();
    }
    return false;
  }

  static String camelToSnake(String text) {
    final buffer = StringBuffer();
    text?.runes?.forEach((code) {
      final character = String.fromCharCode(code);
      if (character == character.toUpperCase()) {
        buffer.write('_');
      }
      buffer.write(character.toLowerCase());
    });
    return buffer.toString();
  }

  static String getPercentage(int progress, int max) {
    final percentage = ((progress / max) * 100);
    if (!percentage.isNaN && !percentage.isInfinite) {
      return '${percentage.round()}%';
    }
    return '0%';
  }

  static bool isEnum(dynamic data) {
    final array = data.toString().split('.');
    return array.length == 2 && array[0] == data.runtimeType.toString();
  }

  static String enumValue(dynamic data) {
    return data.toString().split('.').last;
  }

  static String toPast(String word) {
    final dash = '-';
    if (word.contains(dash)) {
      final first = word.split(dash).first;
      final past = PAST.convert(first);
      return word.replaceAll(first, past);
    }
    return PAST.convert(word);
  }
}
