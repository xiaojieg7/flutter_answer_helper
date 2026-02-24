import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'platform_database_services/android_database_service.dart';
import 'platform_database_services/web_database_service.dart';

class DatabaseServiceFactory {
  static DatabaseService? _instance;

  static DatabaseService getInstance() {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = WebDatabaseService();
      } else {
        _instance = AndroidDatabaseService();
      }
    }
    return _instance!;
  }
}
