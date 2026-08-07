import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
NotificationService({
required this.userId,
}) {
_dio = Dio(
BaseOptions(
baseUrl: baseUrl,
connectTimeout: const Duration(
seconds: 20,
),
receiveTimeout: const Duration(
seconds: 20,
),
sendTimeout: const Duration(
seconds: 20,
),
headers: <String, dynamic>{
'Accept': 'application/json',
'Content-Type': 'application/json',
},
validateStatus: (int? status) {
return status != null &&
status >= 200 &&
status < 600;
},
),
);
}

// DeviceService'ten gelen device_id
final String userId;

late final Dio _dio;

// Backend'deki gerçek sayısal users.id
int? _numericUserId;

// =======================================================
// API ADRESİ
// =======================================================

static String get baseUrl {
if (kIsWeb) {
return 'http://localhost:3000';
}

switch (defaultTargetPlatform) {
case TargetPlatform.android:
return 'http://10.0.2.2:3000';

case TargetPlatform.iOS:
case TargetPlatform.windows:
case TargetPlatform.linux:
case TargetPlatform.macOS:
return 'http://localhost:3000';

default:
return 'http://localhost:3000';
}
}

// =======================================================
// DEVICE_ID -> SAYISAL USER_ID
// =======================================================

Future<int?> _resolveNumericUserId() async {
if (_numericUserId != null) {
return _numericUserId;
}

final String deviceId =
userId.trim();

if (deviceId.isEmpty) {
return null;
}

try {
final Response<dynamic> response =
await _dio.post(
'/api/users/check',
data: <String, dynamic>{
'device_id': deviceId,
},
);

final Map<String, dynamic> data =
_convertToMap(
response.data,
);

final int? numericId =
int.tryParse(
data['user_id']?.toString() ??
'',
);

if (numericId == null ||
numericId <= 0) {
return null;
}

_numericUserId =
numericId;

return numericId;
} on DioException catch (error) {
debugPrint(
'Bildirim kullanıcı çözümleme hatası: '
'${error.response?.data ?? error.message}',
);

return null;
} catch (error) {
debugPrint(
'Bildirim kullanıcı çözümleme beklenmeyen hata: '
'$error',
);

return null;
}
}

// =======================================================
// BİLDİRİMLERİ GETİR
// =======================================================

Future<Map<String, dynamic>>
getNotifications({
int page = 1,
int limit = 20,
}) async {
final int? numericUserId =
await _resolveNumericUserId();

if (numericUserId == null) {
return _userResolutionError();
}

return _get(
'/api/notifications/$numericUserId',
queryParameters: <String, dynamic>{
'page': page,
'limit': limit,
},
);
}

// =======================================================
// OKUNMAMIŞ BİLDİRİM SAYISI
// =======================================================

Future<Map<String, dynamic>>
getUnreadCount() async {
final int? numericUserId =
await _resolveNumericUserId();

if (numericUserId == null) {
return _userResolutionError();
}

return _get(
'/api/notifications/'
'$numericUserId'
'/unread-count',
);
}

// =======================================================
// TEK BİLDİRİMİ OKUNDU YAP
// =======================================================

Future<Map<String, dynamic>>
markAsRead(
int notificationId,
) async {
final int? numericUserId =
await _resolveNumericUserId();

if (numericUserId == null) {
return _userResolutionError();
}

return _post(
'/api/notifications/'
'$notificationId'
'/read',
data: <String, dynamic>{
'user_id': numericUserId,
},
);
}

// =======================================================
// TÜM BİLDİRİMLERİ OKUNDU YAP
// =======================================================

Future<Map<String, dynamic>>
markAllAsRead() async {
final int? numericUserId =
await _resolveNumericUserId();

if (numericUserId == null) {
return _userResolutionError();
}

return _post(
'/api/notifications/read-all',
data: <String, dynamic>{
'user_id': numericUserId,
},
);
}
// =======================================================
// CİHAZ KAYDET
// =======================================================

Future<Map<String, dynamic>>
registerDevice({
required String deviceId,
String? fcmToken,
String platform = 'android',
}) async {
final int? numericUserId =
await _resolveNumericUserId();

if (numericUserId == null) {
return _userResolutionError();
}

return _post(
'/api/notifications/device',
data: <String, dynamic>{
'user_id':
numericUserId,
'device_id':
deviceId.trim(),
'fcm_token':
fcmToken?.trim(),
'platform':
platform.trim(),
},
);
}

// =======================================================
// TEST BİLDİRİMİ OLUŞTUR
// =======================================================

Future<Map<String, dynamic>>
createTestNotification() async {
final int? numericUserId =
await _resolveNumericUserId();

if (numericUserId == null) {
return _userResolutionError();
}

return _post(
'/api/notifications/test',
data: <String, dynamic>{
'user_id':
numericUserId,
},
);
}

// =======================================================
// GET İSTEĞİ
// =======================================================

Future<Map<String, dynamic>> _get(
String endpoint, {
Map<String, dynamic>?
queryParameters,
}) async {
try {
final Response<dynamic> response =
await _dio.get(
endpoint,
queryParameters:
queryParameters,
);

return _parseResponse(
response,
);
} on DioException catch (error) {
debugPrint(
'Bildirim GET hatası: '
'${error.response?.data ?? error.message}',
);

return _handleDioException(
error,
);
} catch (error) {
debugPrint(
'Bildirim GET beklenmeyen hata: '
'$error',
);

return _connectionError();
}
}

// =======================================================
// POST İSTEĞİ
// =======================================================

Future<Map<String, dynamic>> _post(
String endpoint, {
Map<String, dynamic>? data,
}) async {
try {
final Response<dynamic> response =
await _dio.post(
endpoint,
data:
data ??
<String, dynamic>{},
);

return _parseResponse(
response,
);
} on DioException catch (error) {
debugPrint(
'Bildirim POST hatası: '
'${error.response?.data ?? error.message}',
);

return _handleDioException(
error,
);
} catch (error) {
debugPrint(
'Bildirim POST beklenmeyen hata: '
'$error',
);

return _connectionError();
}
}

// =======================================================
// CEVABI DÖNÜŞTÜR
// =======================================================

Map<String, dynamic> _parseResponse(
Response<dynamic> response,
) {
final int statusCode =
response.statusCode ?? 0;

final Map<String, dynamic> data =
_convertToMap(
response.data,
);

if (
statusCode >= 200 &&
statusCode < 300
) {
data.putIfAbsent(
'success',
() => true,
);

data['status_code'] =
statusCode;

return data;
}

return <String, dynamic>{
...data,
'success':
false,
'status_code':
statusCode,
'error':
data['error']
?.toString() ??
'İşlem gerçekleştirilemedi.',
};
}
  // =======================================================
  // DIO HATASI
  // =======================================================

  Map<String, dynamic>
  _handleDioException(
      DioException error,
      ) {
    final Response<dynamic>? response =
        error.response;

    if (response != null) {
      return _parseResponse(
        response,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return <String, dynamic>{
          'success': false,
          'error':
          'Bildirim sunucusu zaman aşımına uğradı.',
        };

      case DioExceptionType.connectionError:
        return <String, dynamic>{
          'success': false,
          'error':
          'Bildirim sunucusuna bağlanılamadı. Backend sunucusunun açık olduğundan emin olun.',
        };

      case DioExceptionType.cancel:
        return <String, dynamic>{
          'success': false,
          'error':
          'Bildirim isteği iptal edildi.',
        };

      case DioExceptionType.badCertificate:
        return <String, dynamic>{
          'success': false,
          'error':
          'Sunucu güvenlik sertifikası geçersiz.',
        };

      case DioExceptionType.badResponse:
        return <String, dynamic>{
          'success': false,
          'error':
          'Bildirim sunucusundan hatalı cevap alındı.',
        };

      case DioExceptionType.unknown:
        return _connectionError();
    }
  }

  // =======================================================
  // VERİYİ MAP YAP
  // =======================================================

  Map<String, dynamic> _convertToMap(
      dynamic value,
      ) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    if (value is Map) {
      return value.map(
            (
            dynamic key,
            dynamic item,
            ) {
          return MapEntry<String, dynamic>(
            key.toString(),
            item,
          );
        },
      );
    }

    return <String, dynamic>{
      'data': value,
    };
  }

  // =======================================================
  // KULLANICI ID ÇÖZÜMLEME HATASI
  // =======================================================

  Map<String, dynamic>
  _userResolutionError() {
    return <String, dynamic>{
      'success': false,
      'error':
      'Kullanıcı bilgisi çözümlenemedi.',
    };
  }

  // =======================================================
  // BAĞLANTI HATASI
  // =======================================================

  Map<String, dynamic>
  _connectionError() {
    return <String, dynamic>{
      'success': false,
      'error':
      'Bildirim sunucusuna bağlanılamadı.',
    };
  }
}