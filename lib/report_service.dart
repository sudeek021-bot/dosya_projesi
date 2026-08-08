import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  static const String _baseUrl =
      'https://evrak-backend-production.up.railway.app/api';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(
        seconds: 20,
      ),
      receiveTimeout: const Duration(
        seconds: 40,
      ),
      sendTimeout: const Duration(
        seconds: 40,
      ),
      headers: const <String, dynamic>{
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

  // =========================================================
  // DEVICE_ID -> SAYISAL USER_ID
  // =========================================================

  Future<int?> _resolveNumericUserId(
      String deviceId,
      ) async {
    final String cleanDeviceId =
    deviceId.trim();

    if (cleanDeviceId.isEmpty) {
      return null;
    }

    try {
      final Response<dynamic> response =
      await _dio.post(
        '/users/check',
        data: <String, dynamic>{
          'device_id': cleanDeviceId,
        },
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        debugPrint(
          'Şikâyet kullanıcı çözümleme HTTP hatası: '
              '${response.statusCode} ${response.data}',
        );

        return null;
      }

      if (response.data is! Map) {
        return null;
      }

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(
        response.data as Map,
      );

      final int? numericUserId =
      int.tryParse(
        data['user_id']?.toString() ?? '',
      );

      if (numericUserId == null ||
          numericUserId <= 0) {
        debugPrint(
          'Şikâyet kullanıcı ID bulunamadı: $data',
        );

        return null;
      }

      return numericUserId;
    } on DioException catch (error) {
      debugPrint(
        'Şikâyet kullanıcı çözümleme hatası: '
            '${error.response?.data ?? error.message}',
      );

      return null;
    } catch (error) {
      debugPrint(
        'Şikâyet kullanıcı çözümleme beklenmeyen hata: '
            '$error',
      );

      return null;
    }
  }

  // =========================================================
  // NOTU ŞİKÂYET ET
  // =========================================================

  Future<Map<String, dynamic>> reportNote({
    required int noteId,
    required String userId,
    required String reason,
    required String description,
  }) async {
    try {
      // Buraya gelen userId aslında cihaz kimliği.
      final int? numericUserId =
      await _resolveNumericUserId(
        userId,
      );

      if (numericUserId == null) {
        return <String, dynamic>{
          'success': false,
          'error':
          'Kullanıcı bilgisi çözümlenemedi.',
        };
      }

      final Response<dynamic> response =
      await _dio.post(
        '/reports/notes',
        data: <String, dynamic>{
          'note_id': noteId,
          'user_id': numericUserId,
          'reason': reason.trim(),
          'description': description.trim(),
        },
      );

      final int statusCode =
          response.statusCode ?? 0;

      if (response.data is Map) {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          response.data as Map,
        );

        if (statusCode >= 200 &&
            statusCode < 300) {
          data.putIfAbsent(
            'success',
                () => true,
          );

          return data;
        }

        return <String, dynamic>{
          ...data,
          'success': false,
          'error':
          data['error']?.toString() ??
              data['message']?.toString() ??
              'Şikâyet gönderilemedi.',
          'statusCode': statusCode,
        };
      }

      if (statusCode >= 200 &&
          statusCode < 300) {
        return <String, dynamic>{
          'success': true,
          'message':
          'Şikâyetiniz incelemeye alındı.',
        };
      }

      return <String, dynamic>{
        'success': false,
        'error': 'Şikâyet gönderilemedi.',
        'statusCode': statusCode,
      };
    } on DioException catch (error) {
      String message =
          'Şikâyet gönderilemedi.';

      final dynamic responseData =
          error.response?.data;

      if (responseData is Map) {
        message =
            responseData['error']?.toString() ??
                responseData['message']
                    ?.toString() ??
                message;
      } else {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.transformTimeout:
            message =
            'Sunucu bağlantısı zaman aşımına uğradı.';
            break;

          case DioExceptionType.connectionError:
            message =
            'Sunucuya bağlanılamadı. Node.js sunucusunu kontrol edin.';
            break;

          case DioExceptionType.cancel:
            message =
            'Şikâyet isteği iptal edildi.';
            break;

          case DioExceptionType.badCertificate:
            message =
            'Sunucu güvenlik sertifikası geçersiz.';
            break;

          case DioExceptionType.badResponse:
            message =
            'Sunucudan geçersiz cevap alındı.';
            break;

          case DioExceptionType.unknown:
            message =
            'Sunucu bağlantısında bilinmeyen bir hata oluştu.';
            break;
        }
      }

      debugPrint(
        'Not şikâyeti gönderme hatası: '
            '${error.response?.data ?? error.message}',
      );

      return <String, dynamic>{
        'success': false,
        'error': message,
        'statusCode':
        error.response?.statusCode,
      };
    } catch (error) {
      debugPrint(
        'Not şikâyetinde beklenmeyen hata: $error',
      );

      return <String, dynamic>{
        'success': false,
        'error':
        'Şikâyet gönderilirken beklenmeyen bir hata oluştu.',
      };
    }
  }
}