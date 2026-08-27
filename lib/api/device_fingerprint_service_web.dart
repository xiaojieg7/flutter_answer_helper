// Web implementation of device fingerprint service
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceFingerprintService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceData() async {
    final webInfo = await _deviceInfo.webBrowserInfo;
    
    final fingerprintData = {
      'userAgent': webInfo.userAgent ?? '',
      'platform': webInfo.platform ?? '',
      'vendor': webInfo.vendor ?? '',
      'language': webInfo.language ?? '',
      'hardwareConcurrency': webInfo.hardwareConcurrency ?? 0,
      'deviceMemory': webInfo.deviceMemory ?? 0,
    };

    final fingerprintString = jsonEncode(fingerprintData);
    final bytes = utf8.encode(fingerprintString);
    final hash = sha256.convert(bytes);

    return {
      'deviceFingerprint': {
        'browser_fingerprint': hash.toString(),
      },
      'platform': 'web',
    };
  }
}
