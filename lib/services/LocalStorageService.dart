import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String UserPreferencesKey = 'userPreferences';
  static const String DarkThemeKey = 'darkTheme';
  static const String UseLocationKey = 'useLocationKey';
  static const String LatitudeKey = 'latitudeKey';
  static const String LongitudeKey = 'longitudeKey';

  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;
  static Future<LocalStorageService?> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService();
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    return _instance;
  }

  UserPreferences get userPreferences {
    var userPreferencesJson = _getFromDisk(UserPreferencesKey);
    if (userPreferencesJson == null) {
      return UserPreferences.fromJson(
          json.decode('{"darkTheme":false,"useLocationKey":true}'));
    }
    return UserPreferences.fromJson(json.decode(userPreferencesJson));
  }

  set userPreferences(UserPreferences userPreferencesToSave) {
    saveStringToDisk(
        UserPreferencesKey, json.encode(userPreferencesToSave.toJson()));
  }

  dynamic _getFromDisk(String key) {
    var value = _preferences!.get(key);
    print('(TRACE) LocalStorageService:_getFromDisk. key: $key value: $value');
    return value;
  }

  void saveStringToDisk(String key, String content) {
    print(
        '(TRACE) LocalStorageService:_saveStringToDisk. key: $key value: $content');
    _preferences!.setString(UserPreferencesKey, content);
  }

  bool get darkTheme => _getFromDisk(DarkThemeKey) ?? false;
  set darkTheme(bool value) => _saveToDisk(DarkThemeKey, value);

  bool get useLocation => _getFromDisk(UseLocationKey) ?? true;
  set useLocation(bool value) => _saveToDisk(UseLocationKey, value);

  double get latitude => _getFromDisk(LatitudeKey) ?? 25.424;
  set latitude(double value) => _saveToDisk(LatitudeKey, value);

  double get longitude => _getFromDisk(LongitudeKey) ?? 81.807;
  set longitude(double value) => _saveToDisk(LongitudeKey, value);

  Map<int, int> get lastSearchedPosition =>
      _getFromDisk(UseLocationKey) ?? true;
  set lastSearchedPosition(Map<int, int> value) =>
      _saveToDisk(UseLocationKey, value);

  void _saveToDisk<T>(String key, T content) {
    print(
        '(TRACE) LocalStorageService:_saveStringToDisk. key: $key value: $content');
    if (content is String) {
      _preferences!.setString(key, content);
    }
    if (content is bool) {
      _preferences!.setBool(key, content);
    }
    if (content is int) {
      _preferences!.setInt(key, content);
    }
    if (content is double) {
      _preferences!.setDouble(key, content);
    }
    if (content is List<String>) {
      _preferences!.setStringList(key, content);
    }
  }
}

class UserPreferences {
  final bool? darkTheme;
  final String? useLocationKey;
  final double? latitudeKey;
  final double? longitudeKey;

  UserPreferences(
      {this.darkTheme, this.useLocationKey, this.latitudeKey, this.longitudeKey});

  UserPreferences.fromJson(Map<String, dynamic> json)
      : darkTheme = json['darkTheme'],
        useLocationKey = json['useLocationKey'],
        latitudeKey = json['latitudeKey'],
        longitudeKey = json['longitudeKey'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['darkTheme'] = this.darkTheme;
    data['useLocationKey'] = this.useLocationKey;
    data['latitudeKey'] = this.latitudeKey;
    data['longitudeKey'] = this.longitudeKey;
    return data;
  }
}
