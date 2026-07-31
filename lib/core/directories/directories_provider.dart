import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directories_provider.g.dart';

@Riverpod(keepAlive: true)
class AppDirectories extends _$AppDirectories with InfraLogger {
  final _methodChannel = const MethodChannel("com.hiddify.app/platform");

  @override
  Future<Directories> build() async {
    final Directories dirs;
    if (kIsWeb) {
      return (baseDir: Directory("."), workingDir: Directory("."), tempDir: Directory("."));
    }
    if (PlatformUtils.isIOS) {
      final paths = await _methodChannel.invokeMethod<Map>("get_paths");
      loggy.debug("paths: $paths");
      dirs = (
        baseDir: Directory(paths?["base"]! as String),
        workingDir: Directory(paths?["working"]! as String),
        tempDir: Directory(paths?["temp"]! as String),
      );
    } else if (PlatformUtils.isWindows) {
      // 灯塔：Windows 下统一走 _resolveWindowsBaseDir，
      // 它会避开含非 ASCII（如中文）的路径——原生核心拿到这类路径会启动即崩。
      final baseDir = await _resolveWindowsBaseDir();
      dirs = (baseDir: baseDir, workingDir: baseDir, tempDir: await getTemporaryDirectory());
    } else {
      final baseDir = await getApplicationSupportDirectory();
      final workingDir = Platform.isAndroid ? await _getAndroidWorkingDirectory() : baseDir;
      final tempDir = await getTemporaryDirectory();
      dirs = (baseDir: baseDir, workingDir: workingDir!, tempDir: tempDir);
    }

    if (!dirs.baseDir.existsSync()) {
      await dirs.baseDir.create(recursive: true);
    }
    if (!dirs.workingDir.existsSync()) {
      await dirs.workingDir.create(recursive: true);
    }

    return dirs;
  }

  static Future<Directory> _getAndroidWorkingDirectory() async {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) return getApplicationDocumentsDirectory();
      if (extDir.existsSync()) return extDir;
      await extDir.create(recursive: true);
      return extDir;
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  static Future<Directory> getDatabaseDirectory() async {
    if (kIsWeb) {
      return Directory(".");
    }
    if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
      return await getLibraryDirectory();
    } else if (PlatformUtils.isWindows) {
      return await _resolveWindowsBaseDir();
    } else if (PlatformUtils.isLinux) {
      return await getApplicationSupportDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  static Directory getPortableDirectory() {
    final exeDir = File(Platform.resolvedExecutable).parent;
    return Directory(p.join(exeDir.path, 'hiddify_portable_data'));
  }

  /// 路径是否只含 ASCII 字符。
  ///
  /// 原生核心（hiddify-core.dll）通过 FFI 接收窄字符串路径，
  /// 路径含中文等非 ASCII 字符时会打不开自己的数据文件，
  /// 表现为程序启动几秒后直接崩溃（flutter_windows.dll / 0xc0000409）。
  static bool isPureAscii(String path) => !path.codeUnits.any((c) => c > 127);

  /// 最后兜底的纯英文目录：`<系统盘>\BeaconData`。
  /// 用于「程序放在中文目录」且「Windows 用户名也是中文」的情况。
  static Directory fallbackAsciiDirectory() {
    final drive = Platform.environment['SystemDrive'] ?? 'C:';
    return Directory(p.join('$drive${p.separator}', 'BeaconData'));
  }

  /// Windows 下按优先级挑一个「可写且路径不含中文」的数据目录：
  /// 1) 便携目录（exe 旁边）—— 仅当路径纯 ASCII
  /// 2) 系统的应用数据目录（AppData）—— 仅当路径纯 ASCII
  /// 3) `<系统盘>\BeaconData` 兜底
  static Future<Directory> _resolveWindowsBaseDir() async {
    if (Environment.isPortable) {
      final portableDir = getPortableDirectory();
      if (isPureAscii(portableDir.path) && await checkDirectoryAccess(portableDir)) {
        return portableDir;
      }
    }

    final supportDir = await getApplicationSupportDirectory();
    if (isPureAscii(supportDir.path) && await checkDirectoryAccess(supportDir)) {
      return supportDir;
    }

    final fallbackDir = fallbackAsciiDirectory();
    if (await checkDirectoryAccess(fallbackDir)) {
      return fallbackDir;
    }

    // 三个都不行时仍返回 AppData，至少让上层逻辑照常走。
    return supportDir;
  }

  static Future<bool> checkDirectoryAccess(Directory dir) async {
    final testFile = File(p.join(dir.path, 'access_test.txt'));

    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      await testFile.writeAsString('Testing write permission...');
      await testFile.readAsString();
      await testFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
