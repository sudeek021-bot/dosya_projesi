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

  final String userId;

  late final Dio _dio;

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
  // BİLDİRİMLERİ GETİR
  // =======================================================

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return _get(
      '/api/notifications/'
          '${Uri.encodeComponent(userId)}',
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
    return _get(
      '/api/notifications/'
          '${Uri.encodeComponent(userId)}'
          '/unread-count',
    );
  }

  // =======================================================
  // TEK BİLDİRİMİ OKUNDU YAP
  // =======================================================

  Future<Map<String, dynamic>> markAsRead(
      int notificationId,
      ) async {
    return _post(
      '/api/notifications/'
          '$notificationId/read',
      data: <String, dynamic>{
        'user_id': userId,
      },
    );
  }

  // =======================================================
  // TÜM BİLDİRİMLERİ OKUNDU YAP
  // =======================================================

  Future<Map<String, dynamic>>
  markAllAsRead() async {
    return _post(
      '/api/notifications/read-all',
      data: <String, dynamic>{
        'user_id': userId,
      },
    );
  }

  // =======================================================
  // CİHAZ KAYDET
  // =======================================================

  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    String? fcmToken,
    String platform = 'android',
  }) async {
    return _post(
      '/api/notifications/device',
      data: <String, dynamic>{
        'user_id': userId,
        'device_id': deviceId.trim(),
        'fcm_token': fcmToken?.trim(),
        'platform': platform.trim(),
      },
    );
  }

  // =======================================================
  // TEST BİLDİRİMİ OLUŞTUR
  // =======================================================

  Future<Map<String, dynamic>>
  createTestNotification() async {
    return _post(
      '/api/notifications/test',
      data: <String, dynamic>{
        'user_id': userId,
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
      await _dio.get<dynamic>(
        endpoint,
        queryParameters:
        queryParameters,
      );

      return _parseResponse(response);
    } on DioException catch (error) {
      debugPrint(
        'Bildirim GET hatası: ${error.message}',
      );

      return _handleDioException(error);
    } catch (error) {
      debugPrint(
        'Bildirim GET beklenmeyen hata: $error',
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
      await _dio.post<dynamic>(
        endpoint,
        data: data ??
            <String, dynamic>{},
      );

      return _parseResponse(response);
    } on DioException catch (error) {
      debugPrint(
        'Bildirim POST hatası: ${error.message}',
      );

      return _handleDioException(error);
    } catch (error) {
      debugPrint(
        'Bildirim POST beklenmeyen hata: $error',
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
      'success': false,
      'status_code': statusCode,
      'error':
      data['error']?.toString() ??
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
      return _parseResponse(response);
    }

    switch (error.type) {
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
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

  Map<String, dynamic>
  _connectionError() {
    return <String, dynamic>{
      'success': false,
      'error':
      'Bildirim sunucusuna bağlanılamadı.',
    };
  }
}