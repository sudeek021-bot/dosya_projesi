import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = "http://10.0.2.2:3000/api";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 40),
      sendTimeout: const Duration(seconds: 60),
      headers: const {
        "Accept": "application/json",
      },
    ),
  );

  // =========================================================
  // KULLANICI KONTROLÜ
  // =========================================================

  Future<Map<String, dynamic>?> checkUser(
      String deviceId,
      ) async {
    try {
      final Response<dynamic> response = await _dio.post(
        "/users/check",
        data: {
          "device_id": deviceId,
        },
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(
          response.data,
        );
      }

      return null;
    } on DioException catch (error) {
      debugPrint(
        "Kullanıcı kontrol hatası: "
            "${error.response?.data ?? error.message}",
      );

      return null;
    } catch (error) {
      debugPrint(
        "Kullanıcı kontrolünde beklenmeyen hata: $error",
      );

      return null;
    }
  }

  // =========================================================
  // KATEGORİLERİ GETİR
  // =========================================================

  Future<List<Map<String, dynamic>>?> getCategories() async {
    try {
      final Response<dynamic> response = await _dio.get(
        "/categories",
      );

      if (response.data is! List) {
        return [];
      }

      final List<dynamic> data =
      List<dynamic>.from(response.data);

      return data.map((dynamic item) {
        return Map<String, dynamic>.from(
          item as Map,
        );
      }).toList();
    } on DioException catch (error) {
      debugPrint(
        "Kategori listeleme hatası: "
            "${error.response?.data ?? error.message}",
      );

      return null;
    } catch (error) {
      debugPrint(
        "Kategori listelemede beklenmeyen hata: $error",
      );

      return null;
    }
  }

  // =========================================================
  // KEŞFET SAYFASI
  // =========================================================

  Future<List<dynamic>?> exploreNotes({
    String? search,
    String? city,
    String? district,
    String? school,
    String? grade,
    String? category,
    String? educationType,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        "/notes/explore",
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            "search": search.trim(),
          if (city != null && city.trim().isNotEmpty)
            "city": city.trim(),
          if (district != null &&
              district.trim().isNotEmpty)
            "district": district.trim(),
          if (school != null && school.trim().isNotEmpty)
            "school": school.trim(),
          if (grade != null && grade.trim().isNotEmpty)
            "grade": grade.trim(),
          if (category != null &&
              category.trim().isNotEmpty &&
              category.trim() != "Tümü")
            "category": category.trim(),
          if (educationType != null &&
              educationType.trim().isNotEmpty)
            "education_type": educationType.trim(),
        },
      );

      if (response.data is List) {
        return List<dynamic>.from(
          response.data,
        );
      }

      return [];
    } on DioException catch (error) {
      debugPrint(
        "Not listeleme hatası: "
            "${error.response?.data ?? error.message}",
      );

      return null;
    } catch (error) {
      debugPrint(
        "Not listelemede beklenmeyen hata: $error",
      );

      return null;
    }
  }

  // =========================================================
  // ÜNİVERSİTE ARAMA
  // =========================================================

  Future<List<Map<String, dynamic>>?> searchUniversities(
      String query,
      ) async {
    final String cleanedQuery = query.trim();

    if (cleanedQuery.length < 2) {
      return [];
    }

    try {
      final Response<dynamic> response = await _dio.get(
        "/universities/search",
        queryParameters: {
          "q": cleanedQuery,
        },
      );

      if (response.data is! List) {
        return [];
      }

      final List<dynamic> data =
      List<dynamic>.from(response.data);

      return data.map((dynamic item) {
        return Map<String, dynamic>.from(
          item as Map,
        );
      }).toList();
    } on DioException catch (error) {
      debugPrint(
        "Üniversite arama hatası: "
            "${error.response?.data ?? error.message}",
      );

      return null;
    } catch (error) {
      debugPrint(
        "Üniversite aramada beklenmeyen hata: $error",
      );

      return null;
    }
  }

  // =========================================================
  // NOT VE PDF YÜKLEME
  // =========================================================

  Future<Map<String, dynamic>> uploadNote({
    required String filePath,
    required String fileName,
    required String title,
    required String description,
    required int categoryId,
    required int universityId,
    required int courseId,
    required String educationType,
    required String gradeLevel,
    required double price,
    required String userId,
  }) async {
    try {
      final MultipartFile pdfFile =
      await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      final FormData formData = FormData.fromMap({
        "document": pdfFile,
        "title": title.trim(),
        "description": description.trim(),
        "category_id": categoryId.toString(),
        "university_id": universityId.toString(),
        "course_id": courseId.toString(),
        "education_type": educationType.trim(),
        "grade_level": gradeLevel.trim(),
        "price": price.toStringAsFixed(2),
        "user_id": userId,
      });

      final Response<dynamic> response = await _dio.post(
        "/notes/upload",
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
        ),
      );

      String message = "Not başarıyla yüklendi.";
      dynamic noteId;

      if (response.data is Map) {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          response.data,
        );

        message =
            data["message"]?.toString() ?? message;

        noteId = data["note_id"];
      }

      return {
        "success": true,
        "message": message,
        "note_id": noteId,
      };
    } on DioException catch (error) {
      String message = "Not yüklenemedi.";

      final dynamic responseData =
          error.response?.data;

      if (responseData is Map) {
        message =
            responseData["error"]?.toString() ??
                message;
      } else if (error.type ==
          DioExceptionType.connectionError) {
        message =
        "Sunucuya bağlanılamadı. Node.js sunucusunu kontrol edin.";
      } else if (error.type ==
          DioExceptionType.sendTimeout) {
        message =
        "PDF yükleme işlemi zaman aşımına uğradı.";
      }

      return {
        "success": false,
        "message": message,
      };
    } catch (error) {
      return {
        "success": false,
        "message":
        "Not yüklenirken beklenmeyen bir hata oluştu.",
      };
    }
  }

  // =========================================================
  // NOT SATIN ALMA
  // =========================================================

  Future<Map<String, dynamic>> purchaseNote({
    required int noteId,
    required String userId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        "/notes/purchase",
        data: {
          "note_id": noteId,
          "user_id": userId,
        },
      );

      if (response.data is Map) {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          response.data,
        );

        return {
          "success": true,
          "message":
          data["message"]?.toString() ??
              "Satın alma tamamlandı.",
          "filePath": data["filePath"]?.toString(),
          "freeTrialUsed":
          data["freeTrialUsed"] == true,
          "alreadyPurchased":
          data["alreadyPurchased"] == true,
        };
      }

      return {
        "success": true,
        "message": "Satın alma tamamlandı.",
      };
    } on DioException catch (error) {
      String message =
          "Satın alma işlemi tamamlanamadı.";

      if (error.response?.data is Map) {
        message =
            error.response?.data["error"]?.toString() ??
                message;
      }

      return {
        "success": false,
        "message": message,
        "statusCode": error.response?.statusCode,
      };
    } catch (error) {
      return {
        "success": false,
        "message":
        "Satın alma sırasında beklenmeyen bir hata oluştu.",
      };
    }
  }

  // =========================================================
  // CÜZDAN BİLGİLERİ
  // =========================================================

  Future<Map<String, dynamic>?> getWallet(
      String userId,
      ) async {
    try {
      final Response<dynamic> response = await _dio.get(
        "/wallet/$userId",
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(
          response.data,
        );
      }

      return null;
    } on DioException catch (error) {
      debugPrint(
        "Cüzdan getirme hatası: "
            "${error.response?.data ?? error.message}",
      );

      return null;
    } catch (error) {
      debugPrint(
        "Cüzdan getirmede beklenmeyen hata: $error",
      );

      return null;
    }
  }

  // =========================================================
  // PARA ÇEKME
  // =========================================================

  Future<Map<String, dynamic>> createWithdrawRequest({
    required String userId,
    required String iban,
    required double amount,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        "/wallet/withdraw",
        data: {
          "user_id": userId,
          "iban": iban.trim(),
          "amount": amount,
        },
      );

      String message =
          "Para çekme talebi oluşturuldu.";

      if (response.data is Map) {
        message =
            response.data["message"]?.toString() ??
                message;
      }

      return {
        "success": true,
        "message": message,
      };
    } on DioException catch (error) {
      String message =
          "Para çekme talebi oluşturulamadı.";

      if (error.response?.data is Map) {
        message =
            error.response?.data["error"]?.toString() ??
                message;
      }

      return {
        "success": false,
        "message": message,
      };
    } catch (error) {
      return {
        "success": false,
        "message":
        "Para çekme sırasında beklenmeyen bir hata oluştu.",
      };
    }
  }

  // =========================================================
  // PDF ADRESİ OLUŞTURMA
  // =========================================================

  String buildFileUrl(String? filePath) {
    if (filePath == null || filePath.trim().isEmpty) {
      return "";
    }

    if (filePath.startsWith("http://") ||
        filePath.startsWith("https://")) {
      return filePath;
    }

    if (filePath.startsWith("/uploads/")) {
      return "http://10.0.2.2:3000$filePath";
    }

    return "http://10.0.2.2:3000/uploads/$filePath";
  }
}