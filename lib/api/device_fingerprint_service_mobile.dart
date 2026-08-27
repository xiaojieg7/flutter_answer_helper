// Mobile implementation (Android/iOS)
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceFingerprintService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceData() async {
    String macAddress = '';
    String deviceName = '';
    String platform = '';

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      macAddress = _generateId(androidInfo.id, androidInfo.device);
      deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      platform = 'android';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      macAddress = _generateId(iosInfo.identifierForVendor ?? '', iosInfo.name);
      deviceName = iosInfo.name;
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

  static String _generateId(String seed1, String seed2) {
    final bytes = utf8.encode('$seed1$seed2');
    final hash = sha256.convert(bytes);
    return hash.toString().toUpperCase().substring(0, 18);
  }
}
