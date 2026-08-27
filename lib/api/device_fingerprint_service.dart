import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceFingerprintService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceData() async {
    if (kIsWeb) {
      return _getWebFingerprint();
    } else {
      return _getMobileFingerprint();
    }
  }

  static Future<Map<String, dynamic>> _getMobileFingerprint() async {
    final deviceInfo = await _deviceInfo.deviceInfo;
    String macAddress = '';
    String deviceName = '';
    String platform = '';

    if (deviceInfo is AndroidDeviceInfo) {
      macAddress = _generateId(deviceInfo.id, deviceInfo.device);
      deviceName = '${deviceInfo.manufacturer} ${deviceInfo.model}';
      platform = 'android';
    } else if (deviceInfo is IosDeviceInfo) {
      macAddress = _generateId(deviceInfo.identifierForVendor ?? '', deviceInfo.name);
      deviceName = deviceInfo.name;
      platform = 'ios';
    }

    return {
      'deviceFingerprint': {
        'macAddress': macAddress,
        'deviceName': deviceName,
      },
      'platform': platform,
    };
  }

  static Future<Map<String, dynamic>> _getWebFingerprint() async {
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
      'browserFingerprint': {
        'browser_fingerprint': hash.toString(),
      },
      'platform': 'web',
    };
  }

  static String _generateId(String seed1, String seed2) {
    final bytes = utf8.encode('$seed1$seed2');
    final hash = sha256.convert(bytes);
    return hash.toString().toUpperCase().substring(0, 18);
  }
}
