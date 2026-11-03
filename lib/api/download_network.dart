import 'dart:io';

import 'package:flutter/services.dart';

/// Fail closed when Wi-Fi cannot be verified. No internet requests are used.
abstract final class DownloadNetwork {
  static Future<bool> wifi() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await const MethodChannel('petal/network')
                .invokeMethod<bool>('wifi') ??
            false;
      }
      if (Platform.isLinux) {
        final r = await Process.run('nmcli', [
          '-t',
          '-f',
          'TYPE,STATE',
          'device',
        ]);
        return r.exitCode == 0 &&
            '${r.stdout}'.split('\n').any((s) => s == 'wifi:connected');
      }
      if (Platform.isMacOS) {
        final r = await Process.run('networksetup', ['-listallhardwareports']);
        final match = RegExp(r'Hardware Port: Wi-Fi\s+Device: (\S+)')
            .firstMatch('${r.stdout}');
        if (match == null) return false;
        final status = await Process.run('ipconfig', [
          'getifaddr',
          match.group(1)!,
        ]);
        return status.exitCode == 0 && '${status.stdout}'.trim().isNotEmpty;
      }
      if (Platform.isWindows) {
        final r = await Process.run('powershell.exe', [
          '-NoProfile',
          '-Command',
          'Get-NetAdapter -Physical | Where-Object { \$_.Status -eq "Up" -and \$_.NdisPhysicalMedium -eq 9 } | Select-Object -ExpandProperty Name',
        ]);
        return r.exitCode == 0 && '${r.stdout}'.trim().isNotEmpty;
      }
    } catch (_) {}
    return false;
  }
}
