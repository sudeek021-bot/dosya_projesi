import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  // =========================================================
  // TEST KULLANICI AYARI
  // =========================================================

  static const String _testUserKey =
      'cadion_selected_test_user';

  // Bunlar users.id DEĞİL.
  // Backend'deki users.device_id değerleridir.

  // user_id = 1
  // Satıcı test kullanıcısı
  static const String userOne =
      'test_cihaz_id';

  // user_id = 2
  // Alıcı test kullanıcısı
  static const String userTwo =
      'UE1A.230829.050';

  // user_id = 6
  // Ek test kullanıcısı
  static const String userThree =
      'test_cihaz_1';

  // =========================================================
  // AKTİF CİHAZ / TEST KULLANICI KİMLİĞİNİ GETİR
  // =========================================================

  static Future<String> getDeviceId() async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    final String? selectedTestUser =
    preferences.getString(
      _testUserKey,
    );

    // Test kullanıcısı seçilmişse gerçek cihaz
    // kimliği yerine seçilen test device_id kullanılır.
    if (selectedTestUser != null &&
        selectedTestUser.trim().isNotEmpty) {
      return selectedTestUser.trim();
    }

    return _getRealDeviceId();
  }

  // =========================================================
  // TEST KULLANICISI SEÇ
  // =========================================================

  static Future<void> setTestUser(
      String deviceId,
      ) async {
    final String normalizedDeviceId =
    deviceId.trim();

    if (normalizedDeviceId.isEmpty) {
      throw ArgumentError(
        'Cihaz kimliği boş olamaz.',
      );
    }

    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    await preferences.setString(
      _testUserKey,
      normalizedDeviceId,
    );
  }

  // =========================================================
  // 1. TEST KULLANICISI
  // user_id = 1 / SATICI
  // =========================================================

  static Future<void>
  useFirstTestUser() async {
    await setTestUser(
      userOne,
    );
  }

  // =========================================================
  // 2. TEST KULLANICISI
  // user_id = 2 / ALICI
  // =========================================================

  static Future<void>
  useSecondTestUser() async {
    await setTestUser(
      userTwo,
    );
  }

  // =========================================================
  // 3. TEST KULLANICISI
  // user_id = 6
  // =========================================================

  static Future<void>
  useThirdTestUser() async {
    await setTestUser(
      userThree,
    );
  }

  // =========================================================
  // TEST MODUNU KAPAT
  // =========================================================

  static Future<void>
  clearTestUser() async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    await preferences.remove(
      _testUserKey,
    );
  }

  // =========================================================
  // SEÇİLİ KULLANICI / CİHAZ KİMLİĞİ
  // =========================================================

  static Future<String>
  getSelectedUserId() async {
    return getDeviceId();
  }

  // =========================================================
  // GERÇEK CİHAZ KİMLİĞİ
  // =========================================================

  static Future<String>
  _getRealDeviceId() async {
    final DeviceInfoPlugin deviceInfo =
    DeviceInfoPlugin();

    if (kIsWeb) {
      return 'web_test_user';
    }

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo =
      await deviceInfo.androidInfo;

      return androidInfo.id;
    }

    if (Platform.isIOS) {
      final IosDeviceInfo iosInfo =
      await deviceInfo.iosInfo;

      return iosInfo.identifierForVendor ??
          'unknown_ios';
    }

    return 'unknown_device';
  }
}