import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'device_service.dart';
import 'purchase_screen.dart';
import 'report_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;

  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  @override
  State<NoteDetailScreen> createState() =>
      _NoteDetailScreenState();
}

class _NoteDetailScreenState
    extends State<NoteDetailScreen> {
final ApiService _apiService =
ApiService();

late Map<String, dynamic> _note;

bool _loading =
false;

bool _detailError =
false;

@override
void initState() {
super.initState();

_note =
Map<String, dynamic>.from(
widget.note,
);

_loadNoteDetail();
}

// =========================================================
// NOT DETAYINI BACKEND'DEN YENİLE
// =========================================================

Future<void> _loadNoteDetail() async {
final int? noteId =
int.tryParse(
_note["id"]?.toString() ??
"",
);

if (noteId == null) {
return;
}

setState(() {
_loading =
true;

_detailError =
false;
});

final Map<String, dynamic> result =
await _apiService.getNoteDetail(
noteId:
noteId,
);

if (!mounted) {
return;
}

if (result["success"] == false) {
setState(() {
_loading =
false;

_detailError =
true;
});

return;
}

Map<String, dynamic> newNote =
result;

// Backend:
// {
//   success: true,
//   note: {...}
// }
//
// şeklinde dönerse note alanını kullan.
if (result["note"] is Map) {
newNote =
Map<String, dynamic>.from(
result["note"] as Map,
);
}

setState(() {
_note = {
..._note,
...newNote,
};

_loading =
false;

_detailError =
false;
});
}

// =========================================================
// SAYISAL DEĞER
// =========================================================

double _parseDouble(
dynamic value,
) {
return double.tryParse(
value?.toString() ??
"",
) ??
0;
}

// =========================================================
// FİYAT FORMATLA
// =========================================================

String _fiyatFormatla(
dynamic value,
) {
final double price =
_parseDouble(
value,
);

final String fixed =
price.toStringAsFixed(
2,
);

final List<String> parts =
fixed.split(
".",
);

final String integerPart =
parts.first;

final String decimalPart =
parts.last;

final StringBuffer result =
StringBuffer();

for (
int i = 0;
i < integerPart.length;
i++
) {
final int remaining =
integerPart.length - i;

result.write(
integerPart[i],
);

if (
remaining > 1 &&
remaining % 3 == 1
) {
result.write(
".",
);
}
}

return "${result.toString()},$decimalPart";
}

String _puanFormatla(
dynamic value,
) {
return _parseDouble(
value,
).toStringAsFixed(
1,
);
}

// =========================================================
// ARAYÜZ
// =========================================================

@override
Widget build(
BuildContext context,
) {
final String title =
_note["title"]
?.toString() ??
"Başlıksız Not";

final String description =
_note["description"]
?.toString() ??
"Bu not için açıklama eklenmemiş.";

final String university =
_note["university_name"]
?.toString() ??
"Üniversite belirtilmemiş";

final String category =
_note["category_name"]
?.toString() ??
"Kategori belirtilmemiş";

final String course =
_note["course_name"]
?.toString() ??
"Ders belirtilmemiş";

final String educationType =
_note["education_type"]
?.toString() ??
"";

final String gradeLevel =
_note["grade_level"]
?.toString() ??
"Seviye belirtilmemiş";

final String rating =
_puanFormatla(
_note["average_rating"],
);

final String price =
_fiyatFormatla(
_note["price"],
);

final String downloadCount =
_note["download_count"]
?.toString() ??
"0";

final String reviewCount =
_note["review_count"]
?.toString() ??
"0";

return Scaffold(
backgroundColor:
AppColors.background,

appBar:
AppBar(
title:
const Text(
"Not Detayı",
),

actions: [
IconButton(
onPressed:
_loading
? null
: _loadNoteDetail,
icon:
const Icon(
Icons.refresh_rounded,
),
),
],
),

body:
RefreshIndicator(
color:
AppColors.primaryLight,

onRefresh:
_loadNoteDetail,

child:
SingleChildScrollView(
physics:
const AlwaysScrollableScrollPhysics(),

padding:
const EdgeInsets.fromLTRB(
16,
10,
16,
30,
),

child:
Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
if (_loading)
const LinearProgressIndicator(),

if (_detailError)
Padding(
padding:
const EdgeInsets.only(
bottom:
12,
),
child:
Container(
width:
double.infinity,

padding:
const EdgeInsets.all(
12,
),

decoration:
BoxDecoration(
color:
AppColors.warning
.withValues(
alpha:
0.10,
),

borderRadius:
BorderRadius.circular(
14,
),
),

child:
const Text(
"Güncel not bilgileri alınamadı. Mevcut bilgiler gösteriliyor.",
style:
TextStyle(
color:
AppColors.warning,
fontSize:
12,
),
),
),
),

_pdfOnizleme(),

const SizedBox(
height:
23,
),

Row(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Expanded(
child:
Text(
title,

style:
const TextStyle(
color:
AppColors.textPrimary,

fontSize:
22,

height:
1.25,

fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(
width:
12,
),

Container(
padding:
const EdgeInsets.symmetric(
horizontal:
13,

vertical:
9,
),

decoration:
BoxDecoration(
color:
AppColors.success
.withValues(
alpha:
0.14,
),

borderRadius:
BorderRadius.circular(
14,
),
),

child:
Text(
"$price TL",

style:
const TextStyle(
color:
AppColors.success,

fontSize:
16,

fontWeight:
FontWeight.bold,
),
),
),
],
),

const SizedBox(
height:
16,
),

_bilgiSatiri(
Icons.school_rounded,
university,
),

const SizedBox(
height:
9,
),

_bilgiSatiri(
Icons.menu_book_rounded,
course,
),

const SizedBox(
height:
9,
),

_bilgiSatiri(
Icons.category_rounded,
category,
),

if (educationType.isNotEmpty) ...[
const SizedBox(
height:
9,
),

_bilgiSatiri(
Icons.account_balance_rounded,
educationType,
),
],

const SizedBox(
height:
9,
),

_bilgiSatiri(
Icons.workspace_premium_rounded,
gradeLevel,
),

const SizedBox(
height:
23,
),

Row(
children: [
Expanded(
child:
_istatistikKarti(
icon:
Icons.star_rounded,

iconColor:
AppColors.warning,

value:
rating,

title:
"$reviewCount yorum",
),
),

const SizedBox(
width:
12,
),

Expanded(
child:
_istatistikKarti(
icon:
Icons.download_rounded,

iconColor:
AppColors.primaryLight,

value:
downloadCount,

title:
"İndirme",
),
),
],
),
const SizedBox(
height: 27,
),

// =================================================
// NOT AÇIKLAMASI
// =================================================

const Text(
"Not Açıklaması",
style:
TextStyle(
color:
AppColors.textPrimary,
fontSize:
17,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 11,
),

Container(
width:
double.infinity,

padding:
const EdgeInsets.all(
18,
),

decoration:
BoxDecoration(
color:
AppColors.card,

borderRadius:
BorderRadius.circular(
18,
),

border:
Border.all(
color:
AppColors.borderSoft,
),
),

child:
Text(
description,

style:
const TextStyle(
color:
AppColors.textSecondary,

fontSize:
14,

height:
1.6,
),
),
),

const SizedBox(
height: 20,
),

_ucretsizBilgi(),

const SizedBox(
height: 27,
),

// =================================================
// SATIN AL
// =================================================

SizedBox(
width:
double.infinity,

child:
ElevatedButton.icon(
onPressed:
() {
Navigator.of(context)
.push(
MaterialPageRoute<void>(
builder:
(
BuildContext context,
) {
return PurchaseScreen(
note:
_note,
);
},
),
);
},

icon:
const Icon(
Icons.shopping_cart_checkout_rounded,
),

label:
Text(
"Satın Al • $price TL",
),
),
),

const SizedBox(
height: 12,
),

// =================================================
// NOTU ŞİKÂYET ET
// =================================================

SizedBox(
width:
double.infinity,

child:
OutlinedButton.icon(
onPressed:
() async {
final int? noteId =
int.tryParse(
_note["id"]
?.toString() ??
"",
);

if (noteId == null) {
ScaffoldMessenger.of(
context,
).showSnackBar(
const SnackBar(
content:
Text(
"Not kimliği alınamadı.",
),
),
);

return;
}

final String userId =
await DeviceService
.getDeviceId();

if (!context.mounted) {
return;
}

Navigator.of(context)
.push(
MaterialPageRoute<void>(
builder:
(
BuildContext context,
) {
return ReportScreen(
noteId:
noteId,

noteTitle:
title,

userId:
userId,
);
},
),
);
},

icon:
const Icon(
Icons.flag_outlined,
color:
AppColors.error,
),

label:
const Text(
"Notu Şikâyet Et",

style:
TextStyle(
color:
AppColors.error,
),
),
),
),
],
),
),
),
);
}

// =========================================================
// PDF ÖNİZLEME
// =========================================================

Widget _pdfOnizleme() {
return Container(
width:
double.infinity,

height:
215,

decoration:
BoxDecoration(
gradient:
const LinearGradient(
colors: [
AppColors.card,
AppColors.blueSoft,
],

begin:
Alignment.topLeft,

end:
Alignment.bottomRight,
),

borderRadius:
BorderRadius.circular(
24,
),

border:
Border.all(
color:
AppColors.primaryLight
.withValues(
alpha:
0.28,
),
),
),

child:
const Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Icon(
Icons.picture_as_pdf_rounded,
color:
AppColors.primaryLight,
size:
67,
),

SizedBox(
height:
12,
),

Text(
"PDF Ders Notu",

style:
TextStyle(
color:
AppColors.textPrimary,

fontSize:
17,

fontWeight:
FontWeight.bold,
),
),

SizedBox(
height:
6,
),

Padding(
padding:
EdgeInsets.symmetric(
horizontal:
20,
),

child:
Text(
"Satın almadan önce dosya bilgilerini inceleyin",

textAlign:
TextAlign.center,

style:
TextStyle(
color:
AppColors.textSecondary,

fontSize:
12,
),
),
),
],
),
);
}

// =========================================================
// BİLGİ SATIRI
// =========================================================

Widget _bilgiSatiri(
IconData icon,
String value,
) {
return Row(
children: [
Icon(
icon,
color:
AppColors.primaryLight,
size:
19,
),

const SizedBox(
width:
9,
),

Expanded(
child:
Text(
value,

style:
const TextStyle(
color:
AppColors.textSecondary,

fontSize:
13,
),
),
),
],
);
}
  // =========================================================
  // İSTATİSTİK KARTI
  // =========================================================

  Widget _istatistikKarti({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String title,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        15,
        vertical:
        16,
      ),

      decoration:
      BoxDecoration(
        color:
        AppColors.card,

        borderRadius:
        BorderRadius.circular(
          18,
        ),

        border:
        Border.all(
          color:
          AppColors.borderSoft,
        ),
      ),

      child:
      Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(
              9,
            ),

            decoration:
            BoxDecoration(
              color:
              iconColor.withValues(
                alpha:
                0.12,
              ),

              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),

            child:
            Icon(
              icon,
              color:
              iconColor,
              size:
              22,
            ),
          ),

          const SizedBox(
            width:
            12,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  value,

                  style:
                  const TextStyle(
                    color:
                    AppColors.textPrimary,

                    fontSize:
                    17,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                  2,
                ),

                Text(
                  title,

                  maxLines:
                  1,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(
                    color:
                    AppColors.textMuted,

                    fontSize:
                    11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ÜCRETSİZ İLK İNDİRME BİLGİSİ
  // =========================================================

  Widget _ucretsizBilgi() {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.all(
        17,
      ),

      decoration:
      BoxDecoration(
        color:
        AppColors.primaryLight
            .withValues(
          alpha:
          0.08,
        ),

        borderRadius:
        BorderRadius.circular(
          18,
        ),

        border:
        Border.all(
          color:
          AppColors.primaryLight
              .withValues(
            alpha:
            0.22,
          ),
        ),
      ),

      child:
      const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.info_outline_rounded,
            color:
            AppColors.primaryLight,
            size:
            23,
          ),

          SizedBox(
            width:
            12,
          ),

          Expanded(
            child:
            Text(
              "İlk not indirme hakkınız ücretsizdir. Sonraki satın alımlar cüzdan bakiyenizden gerçekleştirilir.",

              style:
              TextStyle(
                color:
                AppColors.textSecondary,

                fontSize:
                12,

                height:
                1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}