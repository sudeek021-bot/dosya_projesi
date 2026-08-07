import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'note_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
  });

  @override
  State<ExploreScreen> createState() =>
      _ExploreScreenState();
}

class _ExploreScreenState
    extends State<ExploreScreen> {
final ApiService _apiService =
ApiService();

final TextEditingController
_searchController =
TextEditingController();

Timer? _searchTimer;

List<Map<String, dynamic>>
_categories = [];

List<Map<String, dynamic>>
_notes = [];

final Map<String, int>
_categoryUsage = {};

bool _isLoading =
true;

bool _categoriesLoading =
true;

bool _serverError =
false;

int? _selectedCategoryId;

String _selectedCategoryName =
"Tümü";

static const int
_visibleCategoryCount = 7;

@override
void initState() {
super.initState();

_prepareScreen();
}

@override
void dispose() {
_searchTimer?.cancel();
_searchController.dispose();

super.dispose();
}

Future<void> _prepareScreen() async {
await _loadCategoryUsage();
await _loadCategories();
await _loadNotes();
}

// =========================================================
// KATEGORİ KULLANIM BİLGİLERİ
// =========================================================

Future<void> _loadCategoryUsage() async {
final SharedPreferences preferences =
await SharedPreferences.getInstance();

final Set<String> keys =
preferences
.getKeys()
.where(
(String key) =>
key.startsWith(
"category_usage_",
),
)
.toSet();

for (final String key in keys) {
final String categoryName =
key.replaceFirst(
"category_usage_",
"",
);

_categoryUsage[categoryName] =
preferences.getInt(
key,
) ??
0;
}
}

Future<void> _increaseCategoryUsage(
String categoryName,
) async {
if (categoryName == "Tümü") {
return;
}

final int newValue =
(_categoryUsage[
categoryName] ??
0) +
1;

_categoryUsage[
categoryName] = newValue;

final SharedPreferences preferences =
await SharedPreferences.getInstance();

await preferences.setInt(
"category_usage_$categoryName",
newValue,
);
}

List<Map<String, dynamic>>
get _visibleCategories {
final List<Map<String, dynamic>>
sorted =
List<Map<String, dynamic>>.from(
_categories,
);

sorted.sort(
(
Map<String, dynamic> first,
Map<String, dynamic> second,
) {
final String firstName =
first["name"]
?.toString() ??
"";

final String secondName =
second["name"]
?.toString() ??
"";

final int firstUsage =
_categoryUsage[
firstName] ??
0;

final int secondUsage =
_categoryUsage[
secondName] ??
0;

if (
firstUsage != secondUsage
) {
return secondUsage.compareTo(
firstUsage,
);
}

return firstName.compareTo(
secondName,
);
},
);

if (_selectedCategoryId != null) {
final int selectedIndex =
sorted.indexWhere(
(
Map<String, dynamic>
category,
) {
return int.tryParse(
category["id"]
.toString(),
) ==
_selectedCategoryId;
},
);

if (selectedIndex > 0) {
final Map<String, dynamic>
selectedItem =
sorted.removeAt(
selectedIndex,
);

sorted.insert(
0,
selectedItem,
);
}
}

return sorted
.take(
_visibleCategoryCount,
)
.toList();
}

// =========================================================
// KATEGORİLER
// =========================================================

Future<void> _loadCategories() async {
if (mounted) {
setState(() {
_categoriesLoading =
true;
});
}

final List<Map<String, dynamic>>?
result =
await _apiService
.getCategories();

if (!mounted) {
return;
}

setState(() {
_categories =
result ?? [];

_categoriesLoading =
false;
});
}

Future<void> _selectCategory({
required int? categoryId,
required String categoryName,
}) async {
if (
_selectedCategoryId ==
categoryId &&
_selectedCategoryName ==
categoryName
) {
return;
}

setState(() {
_selectedCategoryId =
categoryId;

_selectedCategoryName =
categoryName;
});

await _increaseCategoryUsage(
categoryName,
);

await _loadNotes();
}
// =========================================================
// TÜM KATEGORİLER PENCERESİ
// =========================================================

Future<void> _showAllCategories() async {
final TextEditingController
categorySearchController =
TextEditingController();

String categorySearchText =
"";

final Map<String, dynamic>? selected =
await showModalBottomSheet<
Map<String, dynamic>>(
context:
context,

isScrollControlled:
true,

backgroundColor:
Colors.transparent,

builder:
(BuildContext modalContext) {
return StatefulBuilder(
builder:
(
BuildContext context,
StateSetter modalSetState,
) {
final List<
Map<String, dynamic>>
filteredCategories =
_categories.where(
(
Map<String, dynamic>
category,
) {
final String name =
category["name"]
?.toString()
.toLowerCase() ??
"";

return name.contains(
categorySearchText
.toLowerCase(),
);
},
).toList();

return Container(
height:
MediaQuery.of(context)
.size
.height *
0.82,

decoration:
const BoxDecoration(
color:
AppColors.card,

borderRadius:
BorderRadius.vertical(
top:
Radius.circular(
25,
),
),
),

child:
SafeArea(
top:
false,

child:
Column(
children: [
const SizedBox(
height:
11,
),

Container(
width:
43,
height:
4,

decoration:
BoxDecoration(
color:
AppColors.textMuted,

borderRadius:
BorderRadius.circular(
10,
),
),
),

Padding(
padding:
const EdgeInsets.fromLTRB(
18,
18,
10,
12,
),

child:
Row(
children: [
const Expanded(
child:
Text(
"Tüm Kategoriler",

style:
TextStyle(
color:
AppColors.textPrimary,

fontSize:
19,

fontWeight:
FontWeight.bold,
),
),
),

IconButton(
onPressed:
() {
Navigator.of(
modalContext,
).pop();
},

icon:
const Icon(
Icons.close_rounded,
),
),
],
),
),

Padding(
padding:
const EdgeInsets.symmetric(
horizontal:
18,
),

child:
TextField(
controller:
categorySearchController,

autofocus:
false,

onChanged:
(
String value,
) {
modalSetState(
() {
categorySearchText =
value;
},
);
},

decoration:
const InputDecoration(
hintText:
"Kategori ara...",

prefixIcon:
Icon(
Icons.search_rounded,
),
),
),
),

const SizedBox(
height:
12,
),

Expanded(
child:
ListView(
padding:
const EdgeInsets.fromLTRB(
18,
0,
18,
25,
),

children: [
_allCategoryTile(
modalContext:
modalContext,

categoryId:
null,

name:
"Tümü",

icon:
Icons.apps_rounded,
),

...filteredCategories.map(
(
Map<String,
dynamic>
category,
) {
final int?
id =
int.tryParse(
category["id"]
.toString(),
);

final String
name =
category["name"]
?.toString() ??
"";

return _allCategoryTile(
modalContext:
modalContext,

categoryId:
id,

name:
name,

icon:
_categoryIcon(
name,
),
);
},
),
],
),
),
],
),
),
);
},
);
},
);

categorySearchController.dispose();

if (
selected != null &&
mounted
) {
await _selectCategory(
categoryId:
selected["id"] as int?,

categoryName:
selected["name"]
?.toString() ??
"Tümü",
);
}
}

Widget _allCategoryTile({
required BuildContext modalContext,
required int? categoryId,
required String name,
required IconData icon,
}) {
final bool selected =
_selectedCategoryId ==
categoryId;

final int usage =
_categoryUsage[name] ??
0;

return Container(
margin:
const EdgeInsets.only(
bottom:
9,
),

decoration:
BoxDecoration(
color:
selected
? AppColors.primary
.withValues(
alpha:
0.15,
)
: AppColors.input,

borderRadius:
BorderRadius.circular(
16,
),

border:
Border.all(
color:
selected
? AppColors.primaryLight
: AppColors.borderSoft,
),
),

child:
ListTile(
onTap:
() {
Navigator.of(
modalContext,
).pop(
<String, dynamic>{
"id":
categoryId,

"name":
name,
},
);
},

leading:
Container(
width:
41,

height:
41,

decoration:
BoxDecoration(
color:
selected
? AppColors.primary
.withValues(
alpha:
0.18,
)
: AppColors.cardSecondary,

borderRadius:
BorderRadius.circular(
13,
),
),

child:
Icon(
icon,

color:
selected
? AppColors.primaryLight
: AppColors.textSecondary,

size:
21,
),
),

title:
Text(
name,

style:
TextStyle(
color:
selected
? AppColors.primaryLight
: AppColors.textPrimary,

fontSize:
13,

fontWeight:
selected
? FontWeight.bold
: FontWeight.w600,
),
),

subtitle:
usage > 0 &&
name != "Tümü"
? Text(
"$usage kez görüntülendi",

style:
const TextStyle(
color:
AppColors.textMuted,

fontSize:
10,
),
)
: null,

trailing:
selected
? const Icon(
Icons.check_circle_rounded,

color:
AppColors.primaryLight,
)
: const Icon(
Icons.chevron_right_rounded,

color:
AppColors.textMuted,
),
),
);
}

IconData _categoryIcon(
String category,
) {
final String lowerCategory =
category.toLowerCase();

if (
lowerCategory.contains(
"bilgisayar",
) ||
lowerCategory.contains(
"yazılım",
)
) {
return Icons.computer_rounded;
}

if (
lowerCategory.contains(
"mühendis",
)
) {
return Icons.engineering_rounded;
}

if (
lowerCategory.contains(
"hukuk",
)
) {
return Icons.gavel_rounded;
}

if (
lowerCategory.contains(
"tıp",
) ||
lowerCategory.contains(
"sağlık",
)
) {
return Icons.medical_services_rounded;
}

if (
lowerCategory.contains(
"diş",
)
) {
return Icons.health_and_safety_rounded;
}

if (
lowerCategory.contains(
"eczac",
)
) {
return Icons.medication_rounded;
}

if (
lowerCategory.contains(
"işletme",
) ||
lowerCategory.contains(
"iktisat",
)
) {
return Icons.business_center_rounded;
}

if (
lowerCategory.contains(
"eğitim",
)
) {
return Icons.school_rounded;
}

if (
lowerCategory.contains(
"psikoloji",
)
) {
return Icons.psychology_rounded;
}

if (
lowerCategory.contains(
"mimarlık",
)
) {
return Icons.architecture_rounded;
}

return Icons.menu_book_rounded;
}

// =========================================================
// NOTLAR
// =========================================================

Future<void> _loadNotes() async {
if (mounted) {
setState(() {
_isLoading =
true;

_serverError =
false;
});
}

final String search =
_searchController.text.trim();

final List<dynamic>? result =
await _apiService.exploreNotes(
search:
search.isEmpty
? null
: search,

categoryId:
_selectedCategoryId,
);

if (!mounted) {
return;
}

if (result == null) {
setState(() {
_notes =
[];

_serverError =
true;

_isLoading =
false;
});

return;
}

final List<Map<String, dynamic>>
converted =
result
.whereType<Map>()
.map(
(
Map item,
) =>
Map<String, dynamic>.from(
item,
),
)
.toList();

setState(() {
_notes =
converted;

_serverError =
false;

_isLoading =
false;
});
}

void _onSearchChanged(
String value,
) {
setState(() {});

_searchTimer?.cancel();

_searchTimer = Timer(
const Duration(
milliseconds:
500,
),
_loadNotes,
);
}

void _clearSearch() {
_searchTimer?.cancel();

_searchController.clear();

FocusScope.of(context)
.unfocus();

_loadNotes();
}
// =========================================================
// FORMATLAMA
// =========================================================

String _formatPrice(
dynamic value,
) {
final double price =
double.tryParse(
value?.toString() ?? "",
) ??
0;

final String fixed =
price.toStringAsFixed(2);

final List<String> parts =
fixed.split(".");

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
result.write(".");
}
}

return "${result.toString()},$decimalPart";
}

String _formatRating(
dynamic value,
) {
final double rating =
double.tryParse(
value?.toString() ?? "",
) ??
0;

return rating.toStringAsFixed(
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
return Scaffold(
backgroundColor:
AppColors.background,

body: SafeArea(
child: RefreshIndicator(
color:
AppColors.primaryLight,

backgroundColor:
AppColors.card,

onRefresh:
() async {
await _loadCategories();
await _loadNotes();
},

child: CustomScrollView(
physics:
const AlwaysScrollableScrollPhysics(),

slivers: [
SliverToBoxAdapter(
child: Padding(
padding:
const EdgeInsets.fromLTRB(
16,
15,
16,
0,
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
_header(),

const SizedBox(
height: 20,
),

const Text(
"Ders Notu Keşfet",
style:
TextStyle(
color:
AppColors.textPrimary,
fontSize:
22,
fontWeight:
FontWeight.w800,
letterSpacing:
-0.4,
),
),

const SizedBox(
height: 6,
),

const Text(
"Üniversite, ders veya konu adına göre arama yap.",
style:
TextStyle(
color:
AppColors.textSecondary,
fontSize:
13,
),
),

const SizedBox(
height: 17,
),

_searchField(),

const SizedBox(
height: 22,
),

_categoryHeader(),

const SizedBox(
height: 12,
),

_categoryChips(),

const SizedBox(
height: 24,
),

_notesHeader(),

const SizedBox(
height: 13,
),
],
),
),
),

if (_isLoading)
const SliverFillRemaining(
hasScrollBody:
false,
child:
Center(
child:
CircularProgressIndicator(),
),
)
else if (_serverError)
SliverFillRemaining(
hasScrollBody:
false,
child:
_serverErrorWidget(),
)
else if (_notes.isEmpty)
SliverFillRemaining(
hasScrollBody:
false,
child:
_emptyNotesWidget(),
)
else
SliverPadding(
padding:
const EdgeInsets.fromLTRB(
16,
0,
16,
30,
),

sliver:
SliverList.separated(
itemCount:
_notes.length,

separatorBuilder:
(
BuildContext context,
int index,
) {
return const SizedBox(
height:
12,
);
},

itemBuilder:
(
BuildContext context,
int index,
) {
return _noteCard(
_notes[index],
);
},
),
),
],
),
),
),
);
}

// =========================================================
// ÜST BAŞLIK
// =========================================================

Widget _header() {
return Row(
children: [
Container(
width:
57,
height:
57,
padding:
const EdgeInsets.all(
5,
),

decoration:
BoxDecoration(
color:
AppColors.card,

borderRadius:
BorderRadius.circular(
17,
),

border:
Border.all(
color:
AppColors.borderSoft,
),
),

child:
ClipRRect(
borderRadius:
BorderRadius.circular(
12,
),

child:
Image.asset(
'assets/images/notla_logo.png',

fit:
BoxFit.cover,

errorBuilder:
(
BuildContext context,
Object error,
StackTrace? stackTrace,
) {
return const Icon(
Icons.menu_book_rounded,
color:
AppColors.primaryLight,
size:
31,
);
},
),
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

mainAxisAlignment:
MainAxisAlignment.center,

children: [
RichText(
text:
const TextSpan(
children: [
TextSpan(
text:
'Not',

style:
TextStyle(
color:
Color(
0xFFE8EEFF,
),

fontSize:
25,

fontWeight:
FontWeight.w900,

letterSpacing:
-0.8,
),
),

TextSpan(
text:
'la',

style:
TextStyle(
color:
Color(
0xFF9A45F5,
),

fontSize:
25,

fontWeight:
FontWeight.w900,

letterSpacing:
-0.8,
),
),
],
),
),

const SizedBox(
height:
2,
),

const Text(
'Notunu paylaş, başkasına fayda sağla.',

maxLines:
1,

overflow:
TextOverflow.ellipsis,

style:
TextStyle(
color:
AppColors.textSecondary,

fontSize:
11,
),
),
],
),
),
],
);
}

// =========================================================
// ARAMA ALANI
// =========================================================

Widget _searchField() {
return TextField(
controller:
_searchController,

onChanged:
_onSearchChanged,

style:
const TextStyle(
color:
AppColors.textPrimary,

fontSize:
14,
),

decoration:
InputDecoration(
hintText:
"Not, ders veya üniversite ara...",

prefixIcon:
const Icon(
Icons.search_rounded,
),

suffixIcon:
_searchController
.text
.isNotEmpty
? IconButton(
onPressed:
_clearSearch,

icon:
const Icon(
Icons.close_rounded,
),
)
: null,
),
);
}

// =========================================================
// KATEGORİ BAŞLIĞI
// =========================================================

Widget _categoryHeader() {
return Row(
children: [
const Expanded(
child:
Text(
"Kategoriler",

style:
TextStyle(
color:
AppColors.textPrimary,

fontSize:
16,

fontWeight:
FontWeight.bold,
),
),
),

TextButton.icon(
onPressed:
_categoriesLoading
? null
: _showAllCategories,

icon:
const Icon(
Icons.grid_view_rounded,
size:
15,
),

label:
const Text(
"Tümü",

style:
TextStyle(
fontSize:
12,
),
),
),
],
);
}

// =========================================================
// KATEGORİ CHİPLERİ
// =========================================================

Widget _categoryChips() {
if (_categoriesLoading) {
return const SizedBox(
height:
44,

child:
Center(
child:
LinearProgressIndicator(),
),
);
}

final List<Map<String, dynamic>>
visible =
_visibleCategories;

return SizedBox(
height:
44,

child:
ListView(
scrollDirection:
Axis.horizontal,

physics:
const BouncingScrollPhysics(),

children: [
_categoryChip(
categoryId:
null,

categoryName:
"Tümü",
),

...visible.map(
(
Map<String, dynamic>
category,
) {
final int? id =
int.tryParse(
category["id"]
.toString(),
);

final String name =
category["name"]
?.toString() ??
"";

return _categoryChip(
categoryId:
id,

categoryName:
name,
);
},
),
],
),
);
}

Widget _categoryChip({
required int? categoryId,
required String categoryName,
}) {
final bool selected =
_selectedCategoryId ==
categoryId;

return Padding(
padding:
const EdgeInsets.only(
right:
9,
),

child:
InkWell(
onTap:
() {
_selectCategory(
categoryId:
categoryId,

categoryName:
categoryName,
);
},

borderRadius:
BorderRadius.circular(
15,
),

child:
AnimatedContainer(
duration:
const Duration(
milliseconds:
180,
),

padding:
const EdgeInsets.symmetric(
horizontal:
16,
vertical:
11,
),

decoration:
BoxDecoration(
color:
selected
? AppColors.primary
: AppColors.card,

borderRadius:
BorderRadius.circular(
15,
),

border:
Border.all(
color:
selected
? AppColors.primary
: AppColors.border,
),
),

child:
Text(
categoryName,

maxLines:
1,

style:
TextStyle(
color:
selected
? Colors.white
: AppColors.textSecondary,

fontSize:
12,

fontWeight:
selected
? FontWeight.bold
: FontWeight.w500,
),
),
),
),
);
}

// =========================================================
// NOTLAR BAŞLIĞI
// =========================================================

Widget _notesHeader() {
return Row(
children: [
Expanded(
child:
Text(
_selectedCategoryName ==
"Tümü"
? "Yeni Eklenen Notlar"
: _selectedCategoryName,

style:
const TextStyle(
color:
AppColors.textPrimary,

fontSize:
16,

fontWeight:
FontWeight.bold,
),
),
),

Container(
padding:
const EdgeInsets.symmetric(
horizontal:
10,

vertical:
6,
),

decoration:
BoxDecoration(
color:
AppColors.primary.withValues(
alpha:
0.12,
),

borderRadius:
BorderRadius.circular(
11,
),
),

child:
Text(
"${_notes.length} not",

style:
const TextStyle(
color:
AppColors.primaryLight,

fontSize:
11,

fontWeight:
FontWeight.bold,
),
),
),
],
);
}

// =========================================================
// NOT KARTI
// =========================================================

Widget _noteCard(
Map<String, dynamic> note,
) {
final String title =
note["title"]
?.toString() ??
"Başlıksız Not";

final String university =
note["university_name"]
?.toString() ??
"Üniversite belirtilmemiş";

final String category =
note["category_name"]
?.toString() ??
"Kategori belirtilmemiş";

final String course =
note["course_name"]
?.toString() ??
"Ders belirtilmemiş";

final String grade =
note["grade_level"]
?.toString() ??
"Seviye belirtilmemiş";

final String price =
_formatPrice(
note["price"],
);

final String rating =
_formatRating(
note["average_rating"],
);

final String reviewCount =
note["review_count"]
?.toString() ??
"0";

final String downloadCount =
note["download_count"]
?.toString() ??
"0";

return Material(
color:
Colors.transparent,

child:
InkWell(
onTap:
() {
Navigator.of(context)
.push(
MaterialPageRoute(
builder:
(
BuildContext context,
) {
return NoteDetailScreen(
note:
note,
);
},
),
);
},

borderRadius:
BorderRadius.circular(
20,
),

child:
Ink(
padding:
const EdgeInsets.all(
14,
),

decoration:
BoxDecoration(
color:
AppColors.card,

borderRadius:
BorderRadius.circular(
20,
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
width:
63,

height:
69,

decoration:
BoxDecoration(
gradient:
const LinearGradient(
colors: [
AppColors.primary,
AppColors.secondary,
],

begin:
Alignment.topLeft,

end:
Alignment.bottomRight,
),

borderRadius:
BorderRadius.circular(
17,
),
),

child:
const Icon(
Icons.picture_as_pdf_rounded,

color:
Colors.white,

size:
31,
),
),

const SizedBox(
width:
13,
),

Expanded(
child:
Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Row(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Expanded(
child:
Text(
title,

maxLines:
2,

overflow:
TextOverflow.ellipsis,

style:
const TextStyle(
color:
AppColors.textPrimary,

fontSize:
14,

height:
1.25,

fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(
width:
8,
),

Container(
padding:
const EdgeInsets.symmetric(
horizontal:
10,

vertical:
6,
),

decoration:
BoxDecoration(
color:
AppColors.success
.withValues(
alpha:
0.13,
),

borderRadius:
BorderRadius.circular(
11,
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
12,

fontWeight:
FontWeight.bold,
),
),
),
],
),

const SizedBox(
height:
7,
),

Text(
university,

maxLines:
1,

overflow:
TextOverflow.ellipsis,

style:
const TextStyle(
color:
AppColors.textSecondary,

fontSize:
11,
),
),

const SizedBox(
height:
4,
),

Text(
"$course • $category • $grade",

maxLines:
1,

overflow:
TextOverflow.ellipsis,

style:
const TextStyle(
color:
AppColors.textMuted,

fontSize:
10,
),
),
  const SizedBox(
    height: 8,
  ),

  Row(
    children: [
      const Icon(
        Icons.star_rounded,
        color: AppColors.warning,
        size: 14,
      ),

      const SizedBox(
        width: 4,
      ),

      Text(
        "$rating • $reviewCount yorum",
        style: const TextStyle(
          color:
          AppColors.textSecondary,
          fontSize: 10,
        ),
      ),

      const SizedBox(
        width: 13,
      ),

      const Icon(
        Icons.download_rounded,
        color:
        AppColors.primaryLight,
        size: 14,
      ),

      const SizedBox(
        width: 4,
      ),

      Text(
        downloadCount,
        style: const TextStyle(
          color:
          AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    ],
  ),
],
),
),

  const SizedBox(
    width: 5,
  ),

  const Icon(
    Icons.chevron_right_rounded,
    color: AppColors.textMuted,
  ),
],
),
),
),
);
}

  // =========================================================
  // SUNUCU HATA ALANI
  // =========================================================

  Widget _serverErrorWidget() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          28,
        ),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color:
              AppColors.warning,
              size:
              58,
            ),

            const SizedBox(
              height:
              17,
            ),

            const Text(
              "Sunucuya bağlanılamadı",
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
              height:
              8,
            ),

            const Text(
              "Node.js sunucusunun çalıştığından emin olun.",
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                AppColors.textSecondary,
                fontSize:
                13,
              ),
            ),

            const SizedBox(
              height:
              20,
            ),

            OutlinedButton.icon(
              onPressed:
              _loadNotes,

              icon:
              const Icon(
                Icons.refresh_rounded,
              ),

              label:
              const Text(
                "Tekrar Dene",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOŞ NOT ALANI
  // =========================================================

  Widget _emptyNotesWidget() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          28,
        ),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.folder_open_rounded,
              color:
              AppColors.textMuted,
              size:
              56,
            ),

            const SizedBox(
              height:
              15,
            ),

            Text(
              _searchController
                  .text
                  .isNotEmpty
                  ? "Aramanızla eşleşen not bulunamadı."
                  : _selectedCategoryId != null
                  ? "Bu kategoride henüz not bulunmuyor."
                  : "Henüz yayınlanmış not bulunmuyor.",

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(
                color:
                AppColors.textSecondary,
                fontSize:
                13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}