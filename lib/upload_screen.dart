import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'device_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({
    super.key,
  });

  @override
  State<UploadScreen> createState() =>
      _UploadScreenState();
}

class _UploadScreenState
    extends State<UploadScreen> {
final ApiService _apiService =
ApiService();

final TextEditingController
_titleController =
TextEditingController();

final TextEditingController
_descriptionController =
TextEditingController();

final TextEditingController
_priceController =
TextEditingController();

final TextEditingController
_universityController =
TextEditingController();

PlatformFile? _secilenDosya;

List<Map<String, dynamic>>
_kategoriler = [];

List<Map<String, dynamic>>
_dersler = [];

List<Map<String, dynamic>>
_universiteSonuclari = [];

int? _secilenKategoriId;
String? _secilenKategoriAdi;

int? _secilenDersId;
String? _secilenDersAdi;

int? _secilenUniversiteId;
String? _secilenUniversiteAdi;

String? _secilenEgitimTuru;
String? _secilenSeviye;

bool _kategorilerYukleniyor =
true;

bool _kategoriHatasiVar =
false;

bool _derslerYukleniyor =
true;

bool _dersHatasiVar =
false;

bool _universiteAraniyor =
false;

bool _universiteListesiAcik =
false;

bool _notYukleniyor =
false;

Timer? _aramaTimer;

final List<String>
_egitimTurleri = [
"Ön Lisans",
"Lisans",
"Yüksek Lisans",
"Doktora",
"Uzmanlık",
"Diğer",
];

final Map<String, List<String>>
_seviyeler = {
"Ön Lisans": [
"Hazırlık",
"1. Sınıf",
"2. Sınıf",
"DGS Hazırlık",
"Staj Dönemi",
"Mezuniyet Dönemi",
],

"Lisans": [
"Hazırlık",
"1. Sınıf",
"2. Sınıf",
"3. Sınıf",
"4. Sınıf",
"5. Sınıf",
"6. Sınıf",
"Staj Dönemi",
"Bitirme Projesi",
"Mezuniyet Dönemi",
],

"Yüksek Lisans": [
"Bilimsel Hazırlık",
"1. Yıl",
"2. Yıl",
"Ders Dönemi",
"Seminer Dönemi",
"Tez Dönemi",
"Tezsiz Yüksek Lisans",
],

"Doktora": [
"Bilimsel Hazırlık",
"Ders Dönemi",
"Doktora Yeterlilik",
"Tez Önerisi Dönemi",
"Doktora Tez Dönemi",
],

"Uzmanlık": [
"Tıpta Uzmanlık",
"Diş Hekimliğinde Uzmanlık",
"Yan Dal Uzmanlık",
"Uzmanlık Ders Dönemi",
"Uzmanlık Tez Dönemi",
],

"Diğer": [
"DGS Hazırlık",
"YKS Hazırlık",
"KPSS Hazırlık",
"ALES Hazırlık",
"YDS Hazırlık",
"Hazırlık Atlama",
"Muafiyet Sınavı",
"Erasmus",
"Formasyon",
"Açıköğretim",
"Uzaktan Eğitim",
"Sertifika Programı",
"Mezuniyet Sonrası",
"Diğer",
],
};

@override
void initState() {
super.initState();

_priceController.addListener(
_fiyatDegisti,
);

_kategorileriGetir();
_dersleriGetir();
}

@override
void dispose() {
_aramaTimer?.cancel();

_priceController.removeListener(
_fiyatDegisti,
);

_titleController.dispose();
_descriptionController.dispose();
_priceController.dispose();
_universityController.dispose();

super.dispose();
}

void _fiyatDegisti() {
if (mounted) {
setState(() {});
}
}

List<String> get _aktifSeviyeler {
if (_secilenEgitimTuru == null) {
return [];
}

return _seviyeler[
_secilenEgitimTuru] ??
[];
}

double get _brutFiyat {
String text =
_priceController.text.trim();

if (text.isEmpty) {
return 0;
}

text =
text.replaceAll(".", "");

text =
text.replaceAll(",", ".");

return double.tryParse(
text,
) ??
0;
}

double get _komisyon =>
_brutFiyat * 0.20;

double get _netKazanc =>
_brutFiyat - _komisyon;
// =========================================================
// KATEGORİLERİ GETİR
// =========================================================

Future<void> _kategorileriGetir() async {
setState(() {
_kategorilerYukleniyor = true;
_kategoriHatasiVar = false;
});

final List<Map<String, dynamic>>? result =
await _apiService.getCategories();

if (!mounted) return;

setState(() {
if (result == null) {
_kategoriler = [];
_kategoriHatasiVar = true;
} else {
_kategoriler = result;
_kategoriHatasiVar = false;
}

_kategorilerYukleniyor = false;
});
}

// =========================================================
// DERSLERİ GETİR
// SEÇİLİ KATEGORİYE GÖRE
// =========================================================

  Future<void> _dersleriGetir() async {
    final int? categoryId =
        _secilenKategoriId;

    if (categoryId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dersler = [];
        _secilenDersId = null;
        _derslerYukleniyor = false;
        _dersHatasiVar = false;
      });

      return;
    }

    setState(() {
      _derslerYukleniyor = true;
      _dersHatasiVar = false;

      // Kategori değiştiğinde eski ders seçimi temizlensin.
      _secilenDersId = null;
    });

    final List<Map<String, dynamic>>? result =
    await _apiService.getCourses(
      categoryId: categoryId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      if (result == null) {
        _dersler = [];
        _dersHatasiVar = true;
      } else {
        _dersler = result;
        _dersHatasiVar = false;
      }

      _derslerYukleniyor = false;
    });
  }

// =========================================================
// PDF SEÇ
// =========================================================

Future<void> _pdfSec() async {
try {
final FilePickerResult? result =
await FilePicker.platform.pickFiles(
type: FileType.custom,
allowedExtensions: [
"pdf",
],
allowMultiple: false,
withData: false,
);

if (
result == null ||
result.files.isEmpty
) {
return;
}

final PlatformFile file =
result.files.first;

if (
file.size >
50 * 1024 * 1024
) {
_mesajGoster(
"PDF dosyası en fazla 50 MB olabilir.",
);

return;
}

if (file.path == null) {
_mesajGoster(
"Seçilen dosyanın yolu alınamadı.",
);

return;
}

setState(() {
_secilenDosya =
file;
});
} catch (error) {
_mesajGoster(
"PDF seçilirken bir hata oluştu.",
);
}
}

// =========================================================
// ÜNİVERSİTE ARAMA
// =========================================================

void _universiteAramasiDegisti(
String value,
) {
_secilenUniversiteId =
null;

_secilenUniversiteAdi =
null;

_aramaTimer?.cancel();

final String query =
value.trim();

if (query.length < 2) {
setState(() {
_universiteSonuclari =
[];

_universiteListesiAcik =
false;

_universiteAraniyor =
false;
});

return;
}

setState(() {
_universiteAraniyor =
true;
});

_aramaTimer = Timer(
const Duration(
milliseconds: 450,
),
() async {
final List<Map<String, dynamic>>? result =
await _apiService
.searchUniversities(
query,
);

if (!mounted) return;

setState(() {
_universiteSonuclari =
result ?? [];

_universiteListesiAcik =
true;

_universiteAraniyor =
false;
});
},
);
}

void _universiteSec(
Map<String, dynamic> university,
) {
final int? id =
int.tryParse(
university["id"]
.toString(),
);

final String name =
university["name"]
?.toString() ??
"";

if (
id == null ||
name.isEmpty
) {
_mesajGoster(
"Üniversite bilgisi alınamadı.",
);

return;
}

setState(() {
_secilenUniversiteId =
id;

_secilenUniversiteAdi =
name;

_universityController.text =
name;

_universityController.selection =
TextSelection.collapsed(
offset:
name.length,
);

_universiteSonuclari =
[];

_universiteListesiAcik =
false;

_universiteAraniyor =
false;
});

FocusScope.of(context)
.unfocus();
}

void _universiteTemizle() {
_aramaTimer?.cancel();

setState(() {
_universityController
.clear();

_secilenUniversiteId =
null;

_secilenUniversiteAdi =
null;

_universiteSonuclari =
[];

_universiteListesiAcik =
false;

_universiteAraniyor =
false;
});
}

// =========================================================
// FORMU GÖNDER
// =========================================================

Future<void> _formuGonder() async {
if (_notYukleniyor) return;

if (
_secilenDosya == null ||
_secilenDosya!.path == null
) {
_mesajGoster(
"Lütfen bir PDF dosyası seçin.",
);

return;
}

if (
_titleController.text
.trim()
.isEmpty
) {
_mesajGoster(
"Lütfen not başlığını yazın.",
);

return;
}

if (
_descriptionController
.text
.trim()
.isEmpty
) {
_mesajGoster(
"Lütfen açıklama yazın.",
);

return;
}

if (_secilenKategoriId == null) {
_mesajGoster(
"Lütfen kategori seçin.",
);

return;
}

if (_secilenDersId == null) {
_mesajGoster(
"Lütfen ders seçin.",
);

return;
}

if (_secilenEgitimTuru == null) {
_mesajGoster(
"Lütfen eğitim türünü seçin.",
);

return;
}

if (_secilenSeviye == null) {
_mesajGoster(
"Lütfen eğitim seviyesini seçin.",
);

return;
}

if (_secilenUniversiteId == null) {
_mesajGoster(
"Üniversiteyi açılan listeden seçin.",
);

return;
}

if (_brutFiyat <= 0) {
_mesajGoster(
"Geçerli bir satış fiyatı girin.",
);

return;
}

setState(() {
_notYukleniyor =
true;
});

try {
final String userId =
await DeviceService
.getDeviceId();

final Map<String, dynamic> result =
await _apiService.uploadNote(
filePath:
_secilenDosya!.path!,

fileName:
_secilenDosya!.name,

title:
_titleController.text,

description:
_descriptionController.text,

categoryId:
_secilenKategoriId!,

universityId:
_secilenUniversiteId!,

courseId:
_secilenDersId!,

educationType:
_secilenEgitimTuru!,

gradeLevel:
_secilenSeviye!,

price:
_brutFiyat,

userId:
userId,
);

if (!mounted) return;

final bool success =
result["success"] ==
true;

_mesajGoster(
result["message"]
?.toString() ??
"İşlem tamamlandı.",
success:
success,
);

if (success) {
_formuTemizle();
}
} finally {
if (mounted) {
setState(() {
_notYukleniyor =
false;
});
}
}
}
// =========================================================
// FORMU TEMİZLE
// =========================================================

void _formuTemizle() {
_titleController.clear();
_descriptionController.clear();
_priceController.clear();
_universityController.clear();

setState(() {
_secilenDosya =
null;

_secilenKategoriId =
null;

_secilenKategoriAdi =
null;

_secilenDersId =
null;

_secilenDersAdi =
null;

_secilenEgitimTuru =
null;

_secilenSeviye =
null;

_secilenUniversiteId =
null;

_secilenUniversiteAdi =
null;

_universiteSonuclari =
[];

_universiteListesiAcik =
false;
});

FocusScope.of(context)
.unfocus();
}

// =========================================================
// PARA FORMATLAMA
// =========================================================

String _paraFormatla(
double value,
) {
final String fixed =
value.toStringAsFixed(2);

final List<String> parts =
fixed.split(".");

final String integerPart =
parts[0];

final String decimalPart =
parts[1];

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
result.write(".");
}
}

return "${result.toString()},$decimalPart";
}

// =========================================================
// DOSYA BOYUTU
// =========================================================

String _dosyaBoyutu(
int bytes,
) {
final double mb =
bytes / (1024 * 1024);

if (mb >= 1) {
return "${mb.toStringAsFixed(2)} MB";
}

return "${(bytes / 1024).toStringAsFixed(0)} KB";
}

// =========================================================
// MESAJ GÖSTER
// =========================================================

void _mesajGoster(
String message, {
bool success = false,
}) {
if (!mounted) return;

ScaffoldMessenger.of(context)
.hideCurrentSnackBar();

ScaffoldMessenger.of(context)
.showSnackBar(
SnackBar(
content: Row(
children: [
Icon(
success
? Icons.check_circle_rounded
: Icons.info_outline_rounded,
color: success
? AppColors.success
: AppColors.warning,
),
const SizedBox(
width: 10,
),
Expanded(
child: Text(
message,
),
),
],
),
),
);
}

// =========================================================
// ANA EKRAN
// =========================================================

@override
Widget build(
BuildContext context,
) {
return Scaffold(
backgroundColor:
AppColors.background,

appBar: AppBar(
title: const Text(
"Ders Notu Yükle",
),
),

body: GestureDetector(
onTap: () {
FocusScope.of(context)
.unfocus();

setState(() {
_universiteListesiAcik =
false;
});
},

child: SingleChildScrollView(
padding:
const EdgeInsets.fromLTRB(
16,
12,
16,
32,
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
_pdfSecimAlani(),

const SizedBox(
height: 22,
),

_baslik(
"Not Başlığı",
),

_metinAlani(
controller:
_titleController,
hint:
"Örn: Veri Yapıları Vize Özeti",
),

_baslik(
"Açıklama",
),

_metinAlani(
controller:
_descriptionController,
hint:
"Notun içeriğini ve kapsadığı konuları yazın...",
maxLines:
4,
),

// =================================================
// KATEGORİ
// =================================================

_baslik(
"Kategori",
),

_kategoriAlani(),

// =================================================
// DERS
// =================================================

_baslik(
"Ders",
),

_dersAlani(),

// =================================================
// EĞİTİM TÜRÜ + SEVİYE
// =================================================

Row(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
_baslik(
"Eğitim Türü",
),

_stringDropdown(
value:
_secilenEgitimTuru,

items:
_egitimTurleri,

hint:
"Tür seçin",

onChanged:
(value) {
setState(() {
_secilenEgitimTuru =
value;

_secilenSeviye =
null;
});
},
),
],
),
),

const SizedBox(
width: 12,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
_baslik(
"Seviye",
),

_stringDropdown(
value:
_secilenSeviye,

items:
_aktifSeviyeler,

hint:
_secilenEgitimTuru ==
null
? "Önce tür"
: "Seviye seçin",

onChanged:
_secilenEgitimTuru ==
null
? null
: (value) {
setState(() {
_secilenSeviye =
value;
});
},
),
],
),
),
],
),
// =================================================
// ÜNİVERSİTE
// =================================================

_baslik(
"Üniversite",
),

TextField(
controller:
_universityController,

enabled:
!_notYukleniyor,

onChanged:
_universiteAramasiDegisti,

style:
const TextStyle(
color:
AppColors.textPrimary,
),

decoration:
InputDecoration(
hintText:
"Üniversite adını yazın...",

prefixIcon:
const Icon(
Icons.school_rounded,
),

suffixIcon:
_universiteAraniyor
? const Padding(
padding:
EdgeInsets.all(
14,
),
child:
SizedBox(
width: 18,
height: 18,
child:
CircularProgressIndicator(
strokeWidth:
2,
),
),
)
: _universityController
.text
.isNotEmpty
? IconButton(
onPressed:
_universiteTemizle,
icon:
const Icon(
Icons.close_rounded,
),
)
: null,
),
),

if (_universiteListesiAcik)
_universiteSonucKutusu(),

if (_secilenUniversiteId != null)
Padding(
padding:
const EdgeInsets.only(
top: 9,
),
child: Row(
children: [
const Icon(
Icons.check_circle_rounded,
color:
AppColors.success,
size:
18,
),
const SizedBox(
width:
7,
),
Expanded(
child:
Text(
"$_secilenUniversiteAdi seçildi",
style:
const TextStyle(
color:
AppColors.success,
fontSize:
12,
fontWeight:
FontWeight.w600,
),
),
),
],
),
),

// =================================================
// FİYAT
// =================================================

_baslik(
"Brüt Satış Fiyatı",
),

TextField(
controller:
_priceController,

enabled:
!_notYukleniyor,

keyboardType:
TextInputType.number,

inputFormatters: [
FilteringTextInputFormatter
.digitsOnly,
TurkLirasiFormatter(),
],

style:
const TextStyle(
color:
AppColors.textPrimary,
fontWeight:
FontWeight.w600,
),

decoration:
const InputDecoration(
hintText:
"0,00",
prefixText:
"₺ ",
),
),

const SizedBox(
height:
16,
),

_kazancOzeti(),

const SizedBox(
height:
25,
),

// =================================================
// GÖNDER
// =================================================

SizedBox(
width:
double.infinity,

child:
ElevatedButton.icon(
onPressed:
_notYukleniyor
? null
: _formuGonder,

icon:
_notYukleniyor
? const SizedBox(
width:
19,
height:
19,
child:
CircularProgressIndicator(
strokeWidth:
2,
color:
Colors.white,
),
)
: const Icon(
Icons.send_rounded,
),

label:
Text(
_notYukleniyor
? "Yükleniyor..."
: "İncelemeye Gönder",
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
// KATEGORİ ALANI
// =========================================================

Widget _kategoriAlani() {
if (_kategorilerYukleniyor) {
return Container(
height:
55,
alignment:
Alignment.center,
decoration:
BoxDecoration(
color:
AppColors.input,
borderRadius:
BorderRadius.circular(
17,
),
),
child:
const SizedBox(
width:
21,
height:
21,
child:
CircularProgressIndicator(
strokeWidth:
2,
),
),
);
}

if (_kategoriHatasiVar) {
return OutlinedButton.icon(
onPressed:
_kategorileriGetir,
icon:
const Icon(
Icons.refresh_rounded,
),
label:
const Text(
"Kategorileri Tekrar Yükle",
),
);
}

return Container(
padding:
const EdgeInsets.symmetric(
horizontal:
14,
),
decoration:
BoxDecoration(
color:
AppColors.input,
borderRadius:
BorderRadius.circular(
17,
),
border:
Border.all(
color:
AppColors.border,
),
),
child:
DropdownButtonHideUnderline(
child:
DropdownButton<int>(
value:
_secilenKategoriId,

isExpanded:
true,

dropdownColor:
AppColors.cardSecondary,

hint:
const Text(
"Kategori seçin",
style:
TextStyle(
color:
AppColors.textMuted,
),
),

icon:
const Icon(
Icons.keyboard_arrow_down_rounded,
color:
AppColors.primaryLight,
),

items:
_kategoriler.map(
(
Map<String, dynamic>
kategori,
) {
final int id =
int.tryParse(
kategori["id"]
.toString(),
) ??
0;

final String name =
kategori["name"]
?.toString() ??
"";

return DropdownMenuItem<int>(
value:
id,
child:
Text(
name,
overflow:
TextOverflow.ellipsis,
),
);
},
).toList(),

onChanged:
_notYukleniyor
? null
: (
int? value,
) async {
final Map<String, dynamic>?
selected =
_kategoriler
.cast<
Map<String,
dynamic>?>()
.firstWhere(
(item) =>
int.tryParse(
item?["id"]
?.toString() ??
"",
) ==
value,
orElse: () => null,
);

setState(() {
_secilenKategoriId =
value;

_secilenKategoriAdi =
selected?["name"]
?.toString();

// Kategori değişince eski ders seçimi temizlensin
_secilenDersId =
null;

_secilenDersAdi =
null;

_dersler =
[];
});

// Yeni kategoriye ait dersleri getir
if (value != null) {
await _dersleriGetir();
}
},
),
),
);
}
// =========================================================
// DERS ALANI
// =========================================================

Widget _dersAlani() {
if (_derslerYukleniyor) {
return Container(
height:
55,
alignment:
Alignment.center,
decoration:
BoxDecoration(
color:
AppColors.input,
borderRadius:
BorderRadius.circular(
17,
),
),
child:
const SizedBox(
width:
21,
height:
21,
child:
CircularProgressIndicator(
strokeWidth:
2,
),
),
);
}

if (_dersHatasiVar) {
return OutlinedButton.icon(
onPressed:
_dersleriGetir,
icon:
const Icon(
Icons.refresh_rounded,
),
label:
const Text(
"Dersleri Tekrar Yükle",
),
);
}

return Container(
padding:
const EdgeInsets.symmetric(
horizontal:
14,
),
decoration:
BoxDecoration(
color:
AppColors.input,
borderRadius:
BorderRadius.circular(
17,
),
border:
Border.all(
color:
AppColors.border,
),
),
child:
DropdownButtonHideUnderline(
child:
DropdownButton<int>(
value:
_secilenDersId,

isExpanded:
true,

dropdownColor:
AppColors.cardSecondary,

hint:
const Text(
"Ders seçin",
style:
TextStyle(
color:
AppColors.textMuted,
),
),

icon:
const Icon(
Icons.keyboard_arrow_down_rounded,
color:
AppColors.primaryLight,
),

items:
_dersler.map(
(
Map<String, dynamic>
ders,
) {
final int id =
int.tryParse(
ders["id"]
.toString(),
) ??
0;

final String name =
ders["name"]
?.toString() ??
"";

return DropdownMenuItem<int>(
value:
id,
child:
Text(
name,
overflow:
TextOverflow.ellipsis,
),
);
},
).toList(),

onChanged:
_notYukleniyor
? null
: (
int? value,
) {
final Map<String, dynamic>?
selected =
_dersler
.cast<
Map<String,
dynamic>?>()
.firstWhere(
(item) =>
int.tryParse(
item?["id"]
.toString() ??
"",
) ==
value,
orElse:
() =>
null,
);

setState(() {
_secilenDersId =
value;

_secilenDersAdi =
selected?["name"]
?.toString();
});
},
),
),
);
}
  // =========================================================
  // PDF SEÇİM ALANI
  // =========================================================

  Widget _pdfSecimAlani() {
    final bool fileSelected =
        _secilenDosya != null;

    return InkWell(
      onTap:
      _notYukleniyor
          ? null
          : _pdfSec,

      borderRadius:
      BorderRadius.circular(
        22,
      ),

      child: Container(
        width:
        double.infinity,

        padding:
        const EdgeInsets.all(
          20,
        ),

        decoration:
        BoxDecoration(
          color:
          AppColors.card,

          borderRadius:
          BorderRadius.circular(
            22,
          ),

          border:
          Border.all(
            color:
            fileSelected
                ? AppColors.success
                : AppColors.primaryLight,
          ),
        ),

        child:
        fileSelected
            ? Row(
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              color:
              AppColors.success,
              size:
              38,
            ),

            const SizedBox(
              width:
              14,
            ),

            Expanded(
              child:
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    _secilenDosya!.name,
                    maxLines:
                    2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      color:
                      AppColors.textPrimary,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  Text(
                    _dosyaBoyutu(
                      _secilenDosya!.size,
                    ),
                    style:
                    const TextStyle(
                      color:
                      AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed:
                  () {
                setState(() {
                  _secilenDosya =
                  null;
                });
              },

              icon:
              const Icon(
                Icons.delete_outline_rounded,
                color:
                AppColors.error,
              ),
            ),
          ],
        )
            : const Column(
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              color:
              AppColors.primaryLight,
              size:
              47,
            ),

            SizedBox(
              height:
              10,
            ),

            Text(
              "PDF Belgesi Seçin",
              style:
              TextStyle(
                color:
                AppColors.textPrimary,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            Text(
              "Sadece PDF • En fazla 50 MB",
              style:
              TextStyle(
                color:
                AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ÜNİVERSİTE SONUÇ KUTUSU
  // =========================================================

  Widget _universiteSonucKutusu() {
    return Container(
      margin:
      const EdgeInsets.only(
        top:
        8,
      ),

      constraints:
      const BoxConstraints(
        maxHeight:
        250,
      ),

      decoration:
      BoxDecoration(
        color:
        AppColors.cardSecondary,

        borderRadius:
        BorderRadius.circular(
          17,
        ),

        border:
        Border.all(
          color:
          AppColors.border,
        ),
      ),

      child:
      _universiteSonuclari.isEmpty
          ? const Padding(
        padding:
        EdgeInsets.all(
          18,
        ),
        child:
        Text(
          "Eşleşen üniversite bulunamadı.",
        ),
      )
          : ListView.separated(
        shrinkWrap:
        true,

        itemCount:
        _universiteSonuclari.length,

        separatorBuilder:
            (
            context,
            index,
            ) =>
        const Divider(
          height:
          1,
        ),

        itemBuilder:
            (
            context,
            index,
            ) {
          final Map<String, dynamic>
          university =
          _universiteSonuclari[
          index];

          return ListTile(
            title:
            Text(
              university["name"]
                  ?.toString() ??
                  "",
            ),

            subtitle:
            Text(
              [
                university["city"]
                    ?.toString() ??
                    "",

                university["type"]
                    ?.toString() ??
                    "",
              ]
                  .where(
                    (
                    item,
                    ) =>
                item.isNotEmpty,
              )
                  .join(
                " • ",
              ),
            ),

            onTap:
                () {
              _universiteSec(
                university,
              );
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // KAZANÇ ÖZETİ
  // =========================================================

  Widget _kazancOzeti() {
    return Container(
      padding:
      const EdgeInsets.all(
        17,
      ),

      decoration:
      BoxDecoration(
        color:
        AppColors.card,

        borderRadius:
        BorderRadius.circular(
          18,
        ),
      ),

      child:
      Column(
        children: [
          _kazancSatiri(
            "Brüt fiyat",
            "${_paraFormatla(_brutFiyat)} TL",
            AppColors.textPrimary,
          ),

          const SizedBox(
            height:
            10,
          ),

          _kazancSatiri(
            "Platform komisyonu (%20)",
            "-${_paraFormatla(_komisyon)} TL",
            AppColors.warning,
          ),

          const Divider(
            height:
            24,
          ),

          _kazancSatiri(
            "Senin kazancın",
            "${_paraFormatla(_netKazanc)} TL",
            AppColors.success,
            bold:
            true,
          ),
        ],
      ),
    );
  }

  Widget _kazancSatiri(
      String title,
      String value,
      Color color, {
        bool bold = false,
      }) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,
        ),

        Text(
          value,
          style:
          TextStyle(
            color:
            color,

            fontWeight:
            bold
                ? FontWeight.bold
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BAŞLIK
  // =========================================================

  Widget _baslik(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        top:
        16,
        bottom:
        8,
      ),

      child:
      Text(
        text,
        style:
        const TextStyle(
          color:
          AppColors.textPrimary,

          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  // =========================================================
  // METİN ALANI
  // =========================================================

  Widget _metinAlani({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller:
      controller,

      maxLines:
      maxLines,

      enabled:
      !_notYukleniyor,

      decoration:
      InputDecoration(
        hintText:
        hint,
      ),
    );
  }

  // =========================================================
  // STRING DROPDOWN
  // =========================================================

  Widget _stringDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        14,
      ),

      decoration:
      BoxDecoration(
        color:
        AppColors.input,

        borderRadius:
        BorderRadius.circular(
          17,
        ),
      ),

      child:
      DropdownButtonHideUnderline(
        child:
        DropdownButton<String>(
          value:
          value,

          isExpanded:
          true,

          hint:
          Text(
            hint,
          ),

          dropdownColor:
          AppColors.cardSecondary,

          items:
          items.map(
                (
                String item,
                ) {
              return DropdownMenuItem<String>(
                value:
                item,

                child:
                Text(
                  item,
                  overflow:
                  TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),

          onChanged:
          _notYukleniyor
              ? null
              : onChanged,
        ),
      ),
    );
  }
}

// =========================================================
// TÜRK LİRASI FORMATTER
// =========================================================

class TurkLirasiFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digits =
    newValue.text.replaceAll(
      RegExp(
        r"[^0-9]",
      ),
      "",
    );

    if (digits.isEmpty) {
      return const TextEditingValue(
        text:
        "",
        selection:
        TextSelection.collapsed(
          offset:
          0,
        ),
      );
    }

    while (digits.length < 3) {
      digits =
      "0$digits";
    }

    final String decimalPart =
    digits.substring(
      digits.length - 2,
    );

    String integerPart =
    digits.substring(
      0,
      digits.length - 2,
    );

    integerPart =
        integerPart.replaceFirst(
          RegExp(
            r"^0+(?=\d)",
          ),
          "",
        );

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

    final String formatted =
        "${result.toString()},$decimalPart";

    return TextEditingValue(
      text:
      formatted,

      selection:
      TextSelection.collapsed(
        offset:
        formatted.length,
      ),
    );
  }
}