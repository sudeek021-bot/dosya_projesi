import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
static const String _baseUrl =
    'https://evrak-backend-production.up.railway.app/api';

static const String _serverUrl =
    'https://evrak-backend-production.up.railway.app';

final Dio _dio = Dio(
BaseOptions(
baseUrl: _baseUrl,
connectTimeout:
const Duration(seconds: 20),
receiveTimeout:
const Duration(seconds: 40),
sendTimeout:
const Duration(seconds: 60),
headers: const <String, dynamic>{
'Accept': 'application/json',
},
),
);

// =========================================================
// YARDIMCI FONKSİYONLAR
// =========================================================

Map<String, dynamic>? _mapFromData(
dynamic data,
) {
if (data is Map) {
return Map<String, dynamic>.from(
data,
);
}

return null;
}

List<Map<String, dynamic>>
_mapListFromData(
dynamic data,
) {
if (data is! List) {
return <Map<String, dynamic>>[];
}

final List<Map<String, dynamic>>
result =
<Map<String, dynamic>>[];

for (final dynamic item in data) {
if (item is Map) {
result.add(
Map<String, dynamic>.from(
item,
),
);
}
}

return result;
}

List<Map<String, dynamic>>
_extractMapList(
dynamic responseData,
String fieldName,
) {
if (responseData is List) {
return _mapListFromData(
responseData,
);
}

if (responseData is Map) {
final Map<String, dynamic> data =
Map<String, dynamic>.from(
responseData,
);

return _mapListFromData(
data[fieldName],
);
}

return <Map<String, dynamic>>[];
}

String _extractErrorMessage(
DioException error, {
required String fallback,
}) {
final dynamic responseData =
error.response?.data;

if (responseData is Map) {
final dynamic errorValue =
responseData['error'];

final dynamic messageValue =
responseData['message'];

if (
errorValue != null &&
errorValue
.toString()
.trim()
.isNotEmpty
) {
return errorValue.toString();
}

if (
messageValue != null &&
messageValue
.toString()
.trim()
.isNotEmpty
) {
return messageValue.toString();
}
}

switch (error.type) {
case DioExceptionType.connectionError:
return 'Sunucuya bağlanılamadı. Node.js sunucusunun çalıştığından emin olun.';

case DioExceptionType.connectionTimeout:
return 'Sunucu bağlantısı zaman aşımına uğradı.';

case DioExceptionType.receiveTimeout:
return 'Sunucudan cevap alınamadı.';

case DioExceptionType.sendTimeout:
return 'Veriler sunucuya gönderilirken zaman aşımı oluştu.';

case DioExceptionType.transformTimeout:
return 'Sunucudan gelen veri işlenirken zaman aşımı oluştu.';

case DioExceptionType.cancel:
return 'İstek iptal edildi.';

case DioExceptionType.badCertificate:
return 'Sunucu güvenlik sertifikası geçersiz.';

case DioExceptionType.badResponse:
return fallback;

case DioExceptionType.unknown:
return fallback;
}
}

// =========================================================
// KULLANICI KONTROLÜ
// POST /api/users/check
// =========================================================

Future<Map<String, dynamic>?> checkUser(
String deviceId,
) async {
final String cleanedDeviceId =
deviceId.trim();

if (cleanedDeviceId.isEmpty) {
return null;
}

try {
final Response<dynamic> response =
await _dio.post(
'/users/check',
data: <String, dynamic>{
'device_id':
cleanedDeviceId,
},
);

return _mapFromData(
response.data,
);
} on DioException catch (error) {
debugPrint(
'Kullanıcı kontrol hatası: '
'${error.response?.data ?? error.message}',
);

return null;
} catch (error) {
debugPrint(
'Kullanıcı kontrolünde beklenmeyen hata: $error',
);

return null;
}
}

// =========================================================
// DEVICE_ID -> SAYISAL USERS.ID
// =========================================================

Future<int?> _resolveNumericUserId(
String deviceId,
) async {
final String cleanedDeviceId =
deviceId.trim();

if (cleanedDeviceId.isEmpty) {
return null;
}

final Map<String, dynamic>? result =
await checkUser(
cleanedDeviceId,
);

if (result == null) {
return null;
}

// Backend:
// {
//   "success": true,
//   "user_id": 2
// }
final int? numericUserId =
int.tryParse(
result['user_id']
?.toString() ??
'',
);

if (
numericUserId == null ||
numericUserId <= 0
) {
debugPrint(
'Sayısal kullanıcı ID çözümlenemedi: $result',
);

return null;
}

return numericUserId;
}

Map<String, dynamic>
_userResolutionError({
String message =
'Kullanıcı bilgisi çözümlenemedi.',
}) {
return <String, dynamic>{
'success': false,
'error': message,
'message': message,
};
}

// =========================================================
// KATEGORİLER
// GET /api/categories
// =========================================================

Future<List<Map<String, dynamic>>?>
getCategories() async {
try {
final Response<dynamic> response =
await _dio.get(
'/categories',
);

return _extractMapList(
response.data,
'categories',
);
} on DioException catch (error) {
debugPrint(
'Kategori listeleme hatası: '
'${error.response?.data ?? error.message}',
);

return null;
} catch (error) {
debugPrint(
'Kategori listelemede beklenmeyen hata: $error',
);

return null;
}
}

// =========================================================
// KEŞFET
// GET /api/notes/explore
// =========================================================

Future<List<dynamic>?> exploreNotes({
String? search,
String? city,
String? district,
String? school,
String? grade,
String? category,
int? categoryId,
String? educationType,
int page = 1,
int limit = 50,
}) async {
try {
final Response<dynamic> response =
await _dio.get(
'/notes/explore',
queryParameters:
<String, dynamic>{
if (
search != null &&
search.trim().isNotEmpty
)
'search':
search.trim(),

if (categoryId != null)
'category_id':
categoryId,

if (
city != null &&
city.trim().isNotEmpty
)
'city':
city.trim(),

if (
district != null &&
district.trim().isNotEmpty
)
'district':
district.trim(),

if (
school != null &&
school.trim().isNotEmpty
)
'school':
school.trim(),

if (
grade != null &&
grade.trim().isNotEmpty
)
'grade':
grade.trim(),

if (
category != null &&
category.trim().isNotEmpty &&
category.trim() != 'Tümü'
)
'category':
category.trim(),

if (
educationType != null &&
educationType
.trim()
.isNotEmpty
)
'education_type':
educationType.trim(),

'page':
page,

'limit':
limit,
},
);

if (response.data is List) {
return List<dynamic>.from(
response.data as List,
);
}

if (response.data is Map) {
final Map<String, dynamic> data =
Map<String, dynamic>.from(
response.data as Map,
);

final dynamic notesValue =
data['notes'];

if (notesValue is List) {
return List<dynamic>.from(
notesValue,
);
}
}

return <dynamic>[];
} on DioException catch (error) {
debugPrint(
'Not listeleme hatası: '
'${error.response?.data ?? error.message}',
);

return null;
} catch (error) {
debugPrint(
'Not listelemede beklenmeyen hata: $error',
);

return null;
}
}
// =========================================================
// TEK NOT DETAYI
// GET /api/notes/:id
// =========================================================

Future<Map<String, dynamic>>
getNoteDetail({
required int noteId,
}) async {
try {
final Response<dynamic> response =
await _dio.get(
'/notes/$noteId',
);

final Map<String, dynamic>? data =
_mapFromData(
response.data,
);

if (data == null) {
return <String, dynamic>{
'success': false,
'error':
'Not bilgileri okunamadı.',
};
}

return data;
} on DioException catch (error) {
return <String, dynamic>{
'success': false,
'error':
_extractErrorMessage(
error,
fallback:
'Not bilgileri getirilemedi.',
),
'statusCode':
error.response?.statusCode,
};
} catch (error) {
return <String, dynamic>{
'success': false,
'error':
'Not bilgileri alınırken beklenmeyen bir hata oluştu.',
};
}
}

// =========================================================
// ÜNİVERSİTE ARAMA
// GET /api/universities/search
// =========================================================

Future<List<Map<String, dynamic>>?>
searchUniversities(
String query,
) async {
final String cleanedQuery =
query.trim();

if (cleanedQuery.length < 2) {
return <Map<String, dynamic>>[];
}

try {
final Response<dynamic> response =
await _dio.get(
'/universities/search',
queryParameters:
<String, dynamic>{
'q':
cleanedQuery,
},
);

return _extractMapList(
response.data,
'universities',
);
} on DioException catch (error) {
debugPrint(
'Üniversite arama hatası: '
'${error.response?.data ?? error.message}',
);

return null;
} catch (error) {
debugPrint(
'Üniversite aramada beklenmeyen hata: $error',
);

return null;
}
}

// =========================================================
// TÜM DERSLERİ / KATEGORİYE GÖRE DERSLERİ GETİR
//
// GET /api/universities/courses/all
//
// GET
// /api/universities/courses/all?category_id=2
// =========================================================

  Future<List<Map<String, dynamic>>?>
  getCourses({
    int? categoryId,
  }) async {
    try {
      final Response<dynamic> response =
      await _dio.get(
        '/universities/courses/all',
        queryParameters:
        <String, dynamic>{
          if (categoryId != null)
            'category_id':
            categoryId,
        },
      );

      return _extractMapList(
        response.data,
        'courses',
      );
    } on DioException catch (error) {
      debugPrint(
        'Ders listeleme hatası: '
            '${error.response?.data ?? error.message}',
      );

      return null;
    } catch (error) {
      debugPrint(
        'Ders listelemede beklenmeyen hata: $error',
      );

      return null;
    }
  }
// =========================================================
// NOT VE PDF YÜKLEME
// POST /api/notes/upload
// =========================================================

Future<Map<String, dynamic>>
uploadNote({
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

// Buraya DeviceService'ten gelen device_id gelir.
required String userId,
}) async {
try {
final int? numericUserId =
await _resolveNumericUserId(
userId,
);

if (numericUserId == null) {
return _userResolutionError(
message:
'Not yüklemek için kullanıcı bilgisi alınamadı.',
);
}

final MultipartFile pdfFile =
await MultipartFile.fromFile(
filePath,
filename:
fileName,
);

final FormData formData =
FormData.fromMap(
<String, dynamic>{
'document':
pdfFile,

'title':
title.trim(),

'description':
description.trim(),

'category_id':
categoryId.toString(),

'university_id':
universityId.toString(),

'course_id':
courseId.toString(),

'education_type':
educationType.trim(),

'grade_level':
gradeLevel.trim(),

'price':
price.toStringAsFixed(
2,
),

// ARTIK SAYISAL ID GİDİYOR
'user_id':
numericUserId,
},
);

final Response<dynamic> response =
await _dio.post(
'/notes/upload',
data:
formData,
options:
Options(
contentType:
'multipart/form-data',
),
);

final Map<String, dynamic>? data =
_mapFromData(
response.data,
);

final dynamic noteValue =
data?['note'];

dynamic noteId =
data?['note_id'];

if (
noteId == null &&
noteValue is Map
) {
noteId =
noteValue['id'];
}

return <String, dynamic>{
'success':
data?['success'] != false,

'message':
data?['message']
?.toString() ??
'Not başarıyla yüklendi.',

'note_id':
noteId,

if (noteValue != null)
'note':
noteValue,
};
} on DioException catch (error) {
return <String, dynamic>{
'success': false,

'message':
_extractErrorMessage(
error,
fallback:
'Not yüklenemedi.',
),

'statusCode':
error.response?.statusCode,
};
} catch (error) {
debugPrint(
'Not yükleme beklenmeyen hata: $error',
);

return <String, dynamic>{
'success': false,
'message':
'Not yüklenirken beklenmeyen bir hata oluştu.',
};
}
}

// =========================================================
// NOT SATIN ALMA
// POST /api/notes/purchase
// =========================================================

Future<Map<String, dynamic>>
purchaseNote({
required int noteId,

// Buraya da device_id gelir.
required String userId,
}) async {
try {
final int? numericUserId =
await _resolveNumericUserId(
userId,
);

if (numericUserId == null) {
return _userResolutionError(
message:
'Satın alma için kullanıcı bilgisi alınamadı.',
);
}

final Response<dynamic> response =
await _dio.post(
'/notes/purchase',
data:
<String, dynamic>{
'note_id':
noteId,

// ARTIK SAYISAL
'user_id':
numericUserId,
},
);

final Map<String, dynamic>? data =
_mapFromData(
response.data,
);

if (data == null) {
return <String, dynamic>{
'success': true,
'message':
'Satın alma tamamlandı.',
};
}

return <String, dynamic>{
'success':
data['success'] != false,

'message':
data['message']
?.toString() ??
'Satın alma tamamlandı.',

'filePath':
data['filePath']
?.toString(),

'freeTrialUsed':
data['freeTrialUsed'] ==
true,

'alreadyPurchased':
data['alreadyPurchased'] ==
true,
};
} on DioException catch (error) {
return <String, dynamic>{
'success': false,

'message':
_extractErrorMessage(
error,
fallback:
'Satın alma işlemi tamamlanamadı.',
),

'statusCode':
error.response?.statusCode,
};
} catch (error) {
return <String, dynamic>{
'success': false,
'message':
'Satın alma sırasında beklenmeyen bir hata oluştu.',
};
}
}
// =========================================================
// CÜZDAN BİLGİLERİ
// GET /api/wallet/:userId
// =========================================================

Future<Map<String, dynamic>?> getWallet(
String userId,
) async {
final String cleanedUserId =
userId.trim();

if (cleanedUserId.isEmpty) {
return null;
}

try {
final int? numericUserId =
await _resolveNumericUserId(
cleanedUserId,
);

if (numericUserId == null) {
debugPrint(
'Cüzdan için kullanıcı ID çözümlenemedi.',
);

return null;
}

final Response<dynamic> response =
await _dio.get(
'/wallet/$numericUserId',
);

return _mapFromData(
response.data,
);
} on DioException catch (error) {
debugPrint(
'Cüzdan getirme hatası: '
'${error.response?.data ?? error.message}',
);

return null;
} catch (error) {
debugPrint(
'Cüzdan getirmede beklenmeyen hata: $error',
);

return null;
}
}

// =========================================================
// PARA ÇEKME
// POST /api/wallet/withdraw
// =========================================================

Future<Map<String, dynamic>>
createWithdrawRequest({
required String userId,
required String iban,
required double amount,
}) async {
try {
final int? numericUserId =
await _resolveNumericUserId(
userId,
);

if (numericUserId == null) {
return _userResolutionError(
message:
'Para çekme işlemi için kullanıcı bilgisi alınamadı.',
);
}

final Response<dynamic> response =
await _dio.post(
'/wallet/withdraw',
data: <String, dynamic>{
'user_id':
numericUserId,

'iban':
iban.trim(),

'amount':
amount,
},
);

final Map<String, dynamic>? data =
_mapFromData(
response.data,
);

return <String, dynamic>{
'success':
data?['success'] != false,

'message':
data?['message']
?.toString() ??
'Para çekme talebi oluşturuldu.',

if (data?['withdrawal'] != null)
'withdrawal':
data!['withdrawal'],

if (
data?['remaining_balance'] !=
null
)
'remaining_balance':
data!['remaining_balance'],
};
} on DioException catch (error) {
return <String, dynamic>{
'success': false,

'message':
_extractErrorMessage(
error,
fallback:
'Para çekme talebi oluşturulamadı.',
),

'statusCode':
error.response?.statusCode,
};
} catch (error) {
return <String, dynamic>{
'success': false,

'message':
'Para çekme sırasında beklenmeyen bir hata oluştu.',
};
}
}

// =========================================================
// YORUMLARI GETİR
// GET /api/notes/:noteId/reviews
// =========================================================

Future<Map<String, dynamic>>
getReviews({
required int noteId,
int page = 1,
int limit = 20,
}) async {
try {
final Response<dynamic> response =
await _dio.get(
'/notes/$noteId/reviews',
queryParameters:
<String, dynamic>{
'page':
page,

'limit':
limit,
},
);

final Map<String, dynamic>? data =
_mapFromData(
response.data,
);

if (data == null) {
return <String, dynamic>{
'success': false,
'error':
'Yorum verileri okunamadı.',
};
}

return data;
} on DioException catch (error) {
return <String, dynamic>{
'success': false,

'error':
_extractErrorMessage(
error,
fallback:
'Yorumlar alınamadı.',
),

'statusCode':
error.response?.statusCode,
};
} catch (error) {
return <String, dynamic>{
'success': false,

'error':
'Yorumlar alınırken beklenmeyen bir hata oluştu.',
};
}
}

// =========================================================
// YORUM ÖZETİ
// GET /api/notes/:noteId/review-summary
// =========================================================

Future<Map<String, dynamic>>
getReviewSummary({
required int noteId,
}) async {
try {
final Response<dynamic> response =
await _dio.get(
'/notes/$noteId/review-summary',
);

final Map<String, dynamic>? data =
_mapFromData(
response.data,
);

if (data == null) {
return <String, dynamic>{
'success': false,

'error':
'Yorum özeti okunamadı.',
};
}

return data;
} on DioException catch (error) {
return <String, dynamic>{
'success': false,

'error':
_extractErrorMessage(
error,
fallback:
'Yorum özeti alınamadı.',
),

'statusCode':
error.response?.statusCode,
};
} catch (error) {
return <String, dynamic>{
'success': false,

'error':
'Yorum özeti alınırken beklenmeyen bir hata oluştu.',
};
}
}
  // =========================================================
  // YORUM YETKİSİ KONTROLÜ
  // GET /api/notes/:noteId/review-permission/:userId
  // =========================================================

  Future<Map<String, dynamic>>
  reviewPermission({
    required int noteId,
    required String userId,
  }) async {
    try {
      final int? numericUserId =
      await _resolveNumericUserId(
        userId,
      );

      if (numericUserId == null) {
        return <String, dynamic>{
          'success': false,
          'can_review': false,
          'error':
          'Kullanıcı kimliği bulunamadı.',
        };
      }

      final Response<dynamic> response =
      await _dio.get(
        '/notes/$noteId/review-permission/'
            '$numericUserId',
      );

      final Map<String, dynamic>? data =
      _mapFromData(
        response.data,
      );

      if (data == null) {
        return <String, dynamic>{
          'success': false,
          'can_review': false,
          'error':
          'Yorum yetkisi okunamadı.',
        };
      }

      return data;
    } on DioException catch (error) {
      return <String, dynamic>{
        'success': false,
        'can_review': false,
        'error':
        _extractErrorMessage(
          error,
          fallback:
          'Yorum yetkisi kontrol edilemedi.',
        ),
        'statusCode':
        error.response?.statusCode,
      };
    } catch (error) {
      return <String, dynamic>{
        'success': false,
        'can_review': false,
        'error':
        'Yorum yetkisi kontrol edilirken beklenmeyen bir hata oluştu.',
      };
    }
  }

  // =========================================================
  // YORUM EKLE
  // POST /api/notes/:noteId/reviews
  // =========================================================

  Future<Map<String, dynamic>>
  addReview({
    required int noteId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final String cleanedComment =
    comment.trim();

    if (
    rating < 1 ||
        rating > 5
    ) {
      return <String, dynamic>{
        'success': false,
        'error':
        'Puan 1 ile 5 arasında olmalıdır.',
      };
    }

    if (cleanedComment.isEmpty) {
      return <String, dynamic>{
        'success': false,
        'error':
        'Yorum boş bırakılamaz.',
      };
    }

    try {
      final int? numericUserId =
      await _resolveNumericUserId(
        userId,
      );

      if (numericUserId == null) {
        return _userResolutionError(
          message:
          'Yorum eklemek için kullanıcı bilgisi alınamadı.',
        );
      }

      final Response<dynamic> response =
      await _dio.post(
        '/notes/$noteId/reviews',
        data: <String, dynamic>{
          'user_id':
          numericUserId,

          'rating':
          rating,

          'comment':
          cleanedComment,
        },
      );

      final Map<String, dynamic>? data =
      _mapFromData(
        response.data,
      );

      if (data == null) {
        return <String, dynamic>{
          'success': true,
          'message':
          'Yorumunuz eklendi.',
        };
      }

      return data;
    } on DioException catch (error) {
      return <String, dynamic>{
        'success': false,

        'error':
        _extractErrorMessage(
          error,
          fallback:
          'Yorum eklenemedi.',
        ),

        'statusCode':
        error.response?.statusCode,
      };
    } catch (error) {
      return <String, dynamic>{
        'success': false,

        'error':
        'Yorum eklenirken beklenmeyen bir hata oluştu.',
      };
    }
  }

  // =========================================================
  // YORUM GÜNCELLE
  // PUT /api/notes/:noteId/reviews/:reviewId
  // =========================================================

  Future<Map<String, dynamic>>
  updateReview({
    required int noteId,
    required int reviewId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final String cleanedComment =
    comment.trim();

    if (
    rating < 1 ||
        rating > 5
    ) {
      return <String, dynamic>{
        'success': false,
        'error':
        'Puan 1 ile 5 arasında olmalıdır.',
      };
    }

    if (cleanedComment.isEmpty) {
      return <String, dynamic>{
        'success': false,
        'error':
        'Yorum boş bırakılamaz.',
      };
    }

    try {
      final int? numericUserId =
      await _resolveNumericUserId(
        userId,
      );

      if (numericUserId == null) {
        return _userResolutionError(
          message:
          'Yorum güncellemek için kullanıcı bilgisi alınamadı.',
        );
      }

      final Response<dynamic> response =
      await _dio.put(
        '/notes/$noteId/reviews/$reviewId',
        data: <String, dynamic>{
          'user_id':
          numericUserId,

          'rating':
          rating,

          'comment':
          cleanedComment,
        },
      );

      final Map<String, dynamic>? data =
      _mapFromData(
        response.data,
      );

      if (data == null) {
        return <String, dynamic>{
          'success': true,
          'message':
          'Yorum güncellendi.',
        };
      }

      return data;
    } on DioException catch (error) {
      return <String, dynamic>{
        'success': false,

        'error':
        _extractErrorMessage(
          error,
          fallback:
          'Yorum güncellenemedi.',
        ),

        'statusCode':
        error.response?.statusCode,
      };
    } catch (error) {
      return <String, dynamic>{
        'success': false,

        'error':
        'Yorum güncellenirken beklenmeyen bir hata oluştu.',
      };
    }
  }

  // =========================================================
  // YORUM SİL
  // DELETE /api/notes/:noteId/reviews/:reviewId
  // =========================================================

  Future<Map<String, dynamic>>
  deleteReview({
    required int noteId,
    required int reviewId,
    required String userId,
  }) async {
    try {
      final int? numericUserId =
      await _resolveNumericUserId(
        userId,
      );

      if (numericUserId == null) {
        return _userResolutionError(
          message:
          'Yorum silmek için kullanıcı bilgisi alınamadı.',
        );
      }

      final Response<dynamic> response =
      await _dio.delete(
        '/notes/$noteId/reviews/$reviewId',
        data: <String, dynamic>{
          'user_id':
          numericUserId,
        },
      );

      final Map<String, dynamic>? data =
      _mapFromData(
        response.data,
      );

      if (data == null) {
        return <String, dynamic>{
          'success': true,
          'message':
          'Yorum silindi.',
        };
      }

      return data;
    } on DioException catch (error) {
      return <String, dynamic>{
        'success': false,

        'error':
        _extractErrorMessage(
          error,
          fallback:
          'Yorum silinemedi.',
        ),

        'statusCode':
        error.response?.statusCode,
      };
    } catch (error) {
      return <String, dynamic>{
        'success': false,

        'error':
        'Yorum silinirken beklenmeyen bir hata oluştu.',
      };
    }
  }

  // =========================================================
  // PDF ADRESİ OLUŞTURMA
  // =========================================================

  String buildFileUrl(
      String? filePath,
      ) {
    if (
    filePath == null ||
        filePath.trim().isEmpty
    ) {
      return '';
    }

    final String cleanedPath =
    filePath.trim();

    if (
    cleanedPath.startsWith(
      'http://',
    ) ||
        cleanedPath.startsWith(
          'https://',
        )
    ) {
      return cleanedPath;
    }

    if (
    cleanedPath.startsWith(
      '/uploads/',
    )
    ) {
      return '$_serverUrl$cleanedPath';
    }

    final String normalizedPath =
    cleanedPath.replaceAll(
      '\\',
      '/',
    );

    final String fileName =
        normalizedPath
            .split('/')
            .last;

    if (fileName.isEmpty) {
      return '';
    }

    return '$_serverUrl/uploads/$fileName';
  }
}