import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  static const String _baseUrl =
      'http://10.0.2.2:3000/api';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout:
      const Duration(seconds: 20),
      receiveTimeout:
      const Duration(seconds: 40),
      sendTimeout:
      const Duration(seconds: 40),
      headers: const <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<Map<String, dynamic>> reportNote({
    required int noteId,
    required String userId,
    required String reason,
    required String description,
  }) async {
    try {
      final Response<dynamic> response =
      await _dio.post(
        '/reports/notes',
        data: <String, dynamic>{
          'note_id': noteId,
          'user_id': userId.trim(),
          'reason': reason,
          'description': description.trim(),
        },
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(
          response.data as Map,
        );
      }

      return <String, dynamic>{
        'success': true,
        'message':
        'Şikâyetiniz incelemeye alındı.',
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
      } else if (error.type ==
          DioExceptionType.connectionError) {
        message =
        'Sunucuya bağlanılamadı. Node.js sunucusunu kontrol edin.';
      } else if (error.type ==
          DioExceptionType.connectionTimeout) {
        message =
        'Sunucu bağlantısı zaman aşımına uğradı.';
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
