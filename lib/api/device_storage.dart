import 'dart:io';

import 'package:flutter/services.dart';

abstract final class DeviceStorage {
  static Future<int?> freeBytes(String path) async {
    try {
      if (Platform.isAndroid || Platform.isIOS)
        return await const MethodChannel('petal/storage')
            .invokeMethod<int>('freeBytes', {'path': path});
      if (Platform.isWindows) {
        final drive = Directory(path).absolute.path
            .substring(0, 1)
            .toUpperCase();
        if (!RegExp(r'^[A-Z]$').hasMatch(drive)) return null;
        final result = await Process.run('powershell.exe', [
          '-NoProfile',
          '-Command',
          '(Get-PSDrive -Name $drive).Free',
        ]);
        return result.exitCode == 0
            ? int.tryParse('${result.stdout}'.trim())
            : null;
      }
      final result = await Process.run('df', [
        '-Pk',
        Directory(path).absolute.path,
      ]);
      if (result.exitCode != 0) return null;
      final rows = '${result.stdout}'.trim().split('\n');
      final parts = rows.last.trim().split(RegExp(r'\s+'));
      final available = parts.length > 3 ? int.tryParse(parts[3]) : null;
      return available == null ? null : available * 1024;
    } catch (_) {
      return null;
    }
  }
}
