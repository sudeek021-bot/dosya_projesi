import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _testUserKey =
      'cadion_selected_test_user';

  static const String userOne =
      'test_cihaz_id';

  static const String userTwo =
      '2';
  static const String userThree = '3';

  static Future<String> getDeviceId() async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    final String? selectedTestUser =
    preferences.getString(
      _testUserKey,
    );

    if (
    selectedTestUser != null &&
        selectedTestUser.trim().isNotEmpty
    ) {
      return selectedTestUser.trim();
    }

    return _getRealDeviceId();
  }

  static Future<void> setTestUser(
      String userId,
      ) async {
    final String normalizedUserId =
    userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'Kullanıcı kimliği boş olamaz.',
      );
    }

    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    await preferences.setString(
      _testUserKey,
      normalizedUserId,
    );
  }

  static Future<void>
  useFirstTestUser() async {
    await setTestUser(
      userOne,
    );
  }

  static Future<void>
  useSecondTestUser() async {
    await setTestUser(
      userTwo,
    );
  }
  static Future<void> useThirdTestUser() async {
    await setTestUser(userThree);
  }
  static Future<void>
  clearTestUser() async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    await preferences.remove(
      _testUserKey,
    );
  }

  static Future<String>
  getSelectedUserId() async {
    return getDeviceId();
  }

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

