import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path_lib;

/// Static helper class for determining platform's app data path.
///
/// Does not require [AppData] to work, can be standalone.
/// Paths for MacOS and Linux were choosen based on popular
/// StackOverflow answers. Submit a PR if you believe these are
/// wrong.
class Locator {
  static Future<String> getPlatformSpecificCachePath() async {
    var os = Platform.operatingSystem;
    switch (os) {
      case 'windows':
        return _verify(await _findWindows());
      case 'linux':
        return _verify(_findLinux());
      case 'macos':
        throw const LocatorException('App caches are not supported for Mac OS');
      case 'android':
      case 'ios':
        throw const LocatorException(
            'App caches are not supported for mobile devices');
    }
    throw LocatorException(
        'Platform-specific cache path for platform "$os" was not found');
  }

  static String _verify(String path) {
    if (Directory(path).existsSync()) {
      return path;
    }
    throw LocatorException(
        'The user application path for this platform ("$path") does not exist on this system');
  }

  static Future<String> _findWindows() async {
    ProcessResult regResult = await Process.run(
      'cmd',
      [
        '/C',
        'chcp',
        '65001',
        '&',
        'reg',
        'query',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders',
        '/v',
        'Personal',
      ],
      stdoutEncoding: null,
    );
    String rawResult = utf8.decode(regResult.stdout);
    String result = '';
    bool isParsingVariable = false;
    String curVar = '';
    for (int i = 0; i != rawResult.length; i++) {
      String char = rawResult[i];
      if (char == '%') {
        if (isParsingVariable) {
          isParsingVariable = false;
          result += Platform.environment[curVar] ?? curVar;
          curVar = '';
          continue;
        }
        isParsingVariable = true;
        continue;
      }
      if (isParsingVariable) {
        curVar += char;
        continue;
      }
      result += char;
    }
    List<String> resultSplit = result.split(':\\');
    return resultSplit[0][resultSplit[0].length - 1] +
        ':\\' +
        resultSplit[1].replaceAll('\r', '').replaceAll('\n', '');
  }

  static String _findLinux() {
    String? snapHome = Platform.environment['SNAP_REAL_HOME'];
    if (snapHome == null) {
      return '${Platform.environment['HOME']}/Documents';
    }
    return '$snapHome/Documents';
  }
}

class LocatorException implements Exception {
  final String message;

  const LocatorException(this.message);

  @override
  String toString() => 'LocatorException: $message';
}

/// Represents a custom folder in the platform's AppData folder equivalence.
///
/// Use [name] to define the name of the folder. It will automatically be created
/// if it does not exist already. Access the path of the cache using [path] or
/// directly access the directory by using [directory].
class AppData {
  final String name;

  String get path => _path;
  Directory get directory => _directory;

  late String _path;
  late Directory _directory;

  AppData._(this.name);
  static Future<AppData> findOrCreate(String name) async {
    AppData appdata = AppData._(name);
    await appdata._findOrCreate();
    return appdata;
  }

  Future<void> _findOrCreate() async {
    final cachePath = await Locator.getPlatformSpecificCachePath();
    _path = path_lib.join(cachePath, name);

    _directory = Directory(_path);

    if (!_directory.existsSync()) {
      _directory.createSync();
    }
  }

  void delete() {
    _directory.delete(recursive: true);
  }

  void clear() {
    _directory.list(recursive: true).listen((FileSystemEntity entity) {
      entity.delete(recursive: true);
    });
  }
}
