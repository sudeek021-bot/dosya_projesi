import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'notification_service.dart';

class NotificationsScreen
    extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.userId,
    this.onNotificationsChanged,
  });

  // DeviceService'ten gelen device_id
  final String userId;

  final Future<void> Function()?
  onNotificationsChanged;

  @override
  State<NotificationsScreen>
  createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
late final NotificationService
_notificationService;

bool _isLoading = true;
bool _isMarkingAll = false;

String? _errorMessage;

List<Map<String, dynamic>>
_notifications =
<Map<String, dynamic>>[];

@override
void initState() {
super.initState();

_notificationService =
NotificationService(
userId:
widget.userId,
);

_loadNotifications();
}

// =========================================================
// BİLDİRİMLERİ YÜKLE
// =========================================================

Future<void>
_loadNotifications() async {
if (!mounted) {
return;
}

setState(() {
_isLoading =
true;

_errorMessage =
null;
});

try {
final Map<String, dynamic> result =
await _notificationService
.getNotifications(
page:
1,

limit:
50,
);

if (!mounted) {
return;
}

if (result['success'] != true) {
setState(() {
_isLoading =
false;

_notifications =
<Map<String, dynamic>>[];

_errorMessage =
result['error']
?.toString() ??
'Bildirimler yüklenemedi.';
});

return;
}

final dynamic notificationsValue =
result['notifications'];

final List<Map<String, dynamic>>
notifications =
<Map<String, dynamic>>[];

if (notificationsValue is List) {
for (
final dynamic item
in notificationsValue
) {
if (item is Map) {
notifications.add(
Map<String, dynamic>.from(
item,
),
);
}
}
}

setState(() {
_notifications =
notifications;

_isLoading =
false;

_errorMessage =
null;
});

await widget
.onNotificationsChanged
?.call();
} catch (error) {
if (!mounted) {
return;
}

setState(() {
_isLoading =
false;

_notifications =
<Map<String, dynamic>>[];

_errorMessage =
'Bildirimler yüklenirken beklenmeyen bir hata oluştu.';
});
}
}

// =========================================================
// TEK BİLDİRİMİ OKUNDU YAP
// =========================================================

Future<bool> _markAsRead(
Map<String, dynamic> notification,
) async {
final bool isRead =
_toBool(
notification['is_read'],
);

if (isRead) {
return true;
}

final int? notificationId =
int.tryParse(
notification['id']
?.toString() ??
'',
);

if (notificationId == null) {
_showMessage(
'Bildirim kimliği alınamadı.',
success:
false,
);

return false;
}

final Map<String, dynamic> result =
await _notificationService
.markAsRead(
notificationId,
);

if (!mounted) {
return false;
}

if (result['success'] != true) {
_showMessage(
result['error']
?.toString() ??
'Bildirim güncellenemedi.',
success:
false,
);

return false;
}

setState(() {
notification['is_read'] =
1;
});

await widget
.onNotificationsChanged
?.call();

return true;
}

// =========================================================
// TÜMÜNÜ OKUNDU YAP
// =========================================================

Future<void>
_markAllAsRead() async {
if (_isMarkingAll) {
return;
}

final bool hasUnread =
_notifications.any(
(
Map<String, dynamic>
notification,
) {
return !_toBool(
notification['is_read'],
);
},
);

if (!hasUnread) {
_showMessage(
'Okunmamış bildiriminiz bulunmuyor.',
success:
true,
);

return;
}

setState(() {
_isMarkingAll =
true;
});

try {
final Map<String, dynamic> result =
await _notificationService
.markAllAsRead();

if (!mounted) {
return;
}

if (result['success'] != true) {
_showMessage(
result['error']
?.toString() ??
'Bildirimler güncellenemedi.',
success:
false,
);

return;
}

setState(() {
for (
final Map<String, dynamic>
notification
in _notifications
) {
notification['is_read'] =
1;
}
});

await widget
.onNotificationsChanged
?.call();

if (!mounted) {
return;
}

_showMessage(
'Tüm bildirimler okundu olarak işaretlendi.',
success:
true,
);
} finally {
if (mounted) {
setState(() {
_isMarkingAll =
false;
});
}
}
}

// =========================================================
// MESAJ
// =========================================================

void _showMessage(
String message, {
required bool success,
}) {
if (!mounted) {
return;
}

ScaffoldMessenger.of(context)
.hideCurrentSnackBar();

ScaffoldMessenger.of(context)
.showSnackBar(
SnackBar(
content:
Row(
children: [
Icon(
success
? Icons.check_circle_rounded
: Icons.error_outline_rounded,

color:
success
? AppColors.success
: AppColors.error,
),

const SizedBox(
width:
10,
),

Expanded(
child:
Text(
message,
),
),
],
),
),
);
}

bool _toBool(
dynamic value,
) {
if (value is bool) {
return value;
}

if (value is num) {
return value ==
1;
}

final String text =
value
?.toString()
.toLowerCase() ??
'';

return text == '1' ||
text == 'true';
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
title:
const Text(
'Bildirimler',
),

actions: [
TextButton.icon(
onPressed:
_isMarkingAll
? null
: _markAllAsRead,

icon:
_isMarkingAll
? const SizedBox(
width: 17,
height: 17,
child:
CircularProgressIndicator(
strokeWidth: 2,
),
)
: const Icon(
Icons.done_all_rounded,
size: 19,
),

label:
const Text(
'Tümünü Oku',
),
),

const SizedBox(
width: 8,
),
],
),

body:
RefreshIndicator(
color:
AppColors.primaryLight,

onRefresh:
_loadNotifications,

child:
_buildBody(),
),
);
}

// =========================================================
// SAYFA İÇERİĞİ
// =========================================================

Widget _buildBody() {
// =======================================================
// YÜKLENİYOR
// =======================================================

if (_isLoading) {
return ListView(
physics:
const AlwaysScrollableScrollPhysics(),

children:
const [
SizedBox(
height: 260,
),

Center(
child:
CircularProgressIndicator(),
),
],
);
}

// =======================================================
// HATA
// =======================================================

if (_errorMessage != null) {
return ListView(
physics:
const AlwaysScrollableScrollPhysics(),

padding:
const EdgeInsets.all(
24,
),

children: [
const SizedBox(
height: 130,
),

const Icon(
Icons.cloud_off_rounded,
color:
AppColors.error,
size:
64,
),

const SizedBox(
height: 18,
),

const Text(
'Bildirimler yüklenemedi',

textAlign:
TextAlign.center,

style:
TextStyle(
color:
AppColors.textPrimary,

fontSize:
18,

fontWeight:
FontWeight.w700,
),
),

const SizedBox(
height: 8,
),

Text(
_errorMessage!,

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

const SizedBox(
height: 22,
),

ElevatedButton.icon(
onPressed:
_loadNotifications,

icon:
const Icon(
Icons.refresh_rounded,
),

label:
const Text(
'Tekrar Dene',
),
),
],
);
}

// =======================================================
// HİÇ BİLDİRİM YOK
// =======================================================

if (_notifications.isEmpty) {
return ListView(
physics:
const AlwaysScrollableScrollPhysics(),

padding:
const EdgeInsets.all(
24,
),

children: [
const SizedBox(
height: 145,
),

Center(
child:
Container(
width:
84,

height:
84,

decoration:
BoxDecoration(
color:
AppColors.primary
.withValues(
alpha: 0.12,
),

borderRadius:
BorderRadius.circular(
26,
),
),

child:
const Icon(
Icons.notifications_none_rounded,

color:
AppColors.primary,

size:
45,
),
),
),

const SizedBox(
height: 20,
),

const Text(
'Henüz bildiriminiz yok',

textAlign:
TextAlign.center,

style:
TextStyle(
color:
AppColors.textPrimary,

fontSize:
18,

fontWeight:
FontWeight.w700,
),
),

const SizedBox(
height: 8,
),

const Text(
'Not satışları, yorumlar, onaylar ve para çekme işlemleri burada görünecek.',

textAlign:
TextAlign.center,

style:
TextStyle(
color:
AppColors.textSecondary,

fontSize:
13,

height:
1.45,
),
),
],
);
}

// =======================================================
// BİLDİRİM LİSTESİ
// =======================================================

return ListView.separated(
physics:
const AlwaysScrollableScrollPhysics(),

padding:
const EdgeInsets.fromLTRB(
16,
14,
16,
28,
),

itemCount:
_notifications.length,

separatorBuilder:
(
BuildContext context,
int index,
) {
return const SizedBox(
height: 11,
);
},

itemBuilder:
(
BuildContext context,
int index,
) {
return _buildNotificationCard(
_notifications[index],
);
},
);
}

// =========================================================
// BİLDİRİM KARTI
// =========================================================

Widget _buildNotificationCard(
Map<String, dynamic> notification,
) {
final bool isRead =
_toBool(
notification['is_read'],
);

final String type =
notification['type']
?.toString() ??
'announcement';

final String title =
notification['title']
?.toString() ??
'Bildirim';

final String message =
notification['message']
?.toString() ??
'';

final String createdAt =
notification['created_at']
?.toString() ??
'';

// Backend'den gelen referans bilgileri.
// Bir sonraki aşamada bildirime tıklayınca
// ilgili not/işlem ekranına gitmek için kullanacağız.
final String referenceType =
notification['reference_type']
?.toString() ??
'';

final int? referenceId =
int.tryParse(
notification['reference_id']
?.toString() ??
'',
);

final bool hasReference =
referenceType.isNotEmpty &&
referenceId != null;

return Material(
color:
Colors.transparent,

child:
InkWell(
onTap:
() async {
final bool success =
await _markAsRead(
notification,
);

if (!success ||
!mounted) {
return;
}

// Şimdilik bildirim okundu olarak işaretleniyor.
// referenceType/referenceId hazır tutuluyor.
// İlgili ekran yönlendirmesini sonraki aşamada
// mevcut route yapımıza göre bağlayacağız.
},

borderRadius:
BorderRadius.circular(
20,
),

child:
AnimatedContainer(
duration:
const Duration(
milliseconds:
220,
),

width:
double.infinity,

padding:
const EdgeInsets.all(
16,
),

decoration:
BoxDecoration(
color:
isRead
? const Color(
0xFF101D30,
)
: AppColors.primary
.withValues(
alpha:
0.10,
),

borderRadius:
BorderRadius.circular(
20,
),

border:
Border.all(
color:
isRead
? AppColors.border
: AppColors.primary
.withValues(
alpha:
0.32,
),
),
),

child:
Row(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
_buildNotificationIcon(
type,
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

style:
TextStyle(
color:
AppColors.textPrimary,

fontSize:
15,

fontWeight:
isRead
? FontWeight.w600
: FontWeight.w800,
),
),
),

if (!isRead) ...[
const SizedBox(
width:
9,
),

Container(
width:
9,

height:
9,

margin:
const EdgeInsets.only(
top:
5,
),

decoration:
const BoxDecoration(
color:
AppColors.primary,

shape:
BoxShape.circle,
),
),
],
],
),

const SizedBox(
height:
6,
),

Text(
message,

style:
const TextStyle(
color:
AppColors.textSecondary,

fontSize:
13,

height:
1.4,
),
),

const SizedBox(
height:
10,
),

Row(
children: [
const Icon(
Icons.schedule_rounded,

color:
AppColors.textMuted,

size:
15,
),

const SizedBox(
width:
5,
),

Expanded(
child:
Text(
_formatDate(
createdAt,
),

style:
const TextStyle(
color:
AppColors.textMuted,

fontSize:
11,
),
),
),

if (hasReference)
const Icon(
Icons.chevron_right_rounded,
color:
AppColors.textMuted,
size:
19,
),
],
),
],
),
),
],
),
),
),
);
}
  // =========================================================
  // BİLDİRİM İKONU
  // =========================================================

  Widget _buildNotificationIcon(
      String type,
      ) {
    final IconData icon;
    final Color color;

    switch (type) {
      case 'note_approved':
        icon =
            Icons.check_circle_rounded;
        color =
            AppColors.success;
        break;

      case 'note_rejected':
        icon =
            Icons.cancel_rounded;
        color =
            AppColors.error;
        break;

      case 'note_sold':
        icon =
            Icons.shopping_cart_rounded;
        color =
            AppColors.success;
        break;

      case 'withdrawal_created':
        icon =
            Icons.hourglass_top_rounded;
        color =
            AppColors.primary;
        break;

      case 'withdrawal_approved':
        icon =
            Icons.account_balance_rounded;
        color =
            AppColors.success;
        break;

      case 'withdrawal_rejected':
        icon =
            Icons.money_off_csred_rounded;
        color =
            AppColors.error;
        break;

      case 'new_review':
        icon =
            Icons.star_rounded;
        color =
            Colors.amber;
        break;

      case 'account_banned':
        icon =
            Icons.block_rounded;
        color =
            AppColors.error;
        break;

      case 'account_unbanned':
        icon =
            Icons.lock_open_rounded;
        color =
            AppColors.success;
        break;

      case 'role_changed':
        icon =
            Icons.manage_accounts_rounded;
        color =
            AppColors.primary;
        break;

      case 'announcement':
      default:
        icon =
            Icons.campaign_rounded;
        color =
            AppColors.primary;
        break;
    }

    return Container(
      width:
      48,

      height:
      48,

      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha:
          0.13,
        ),

        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),

      child:
      Icon(
        icon,
        color:
        color,
        size:
        25,
      ),
    );
  }

  // =========================================================
  // TARİH FORMATLA
  // =========================================================

  String _formatDate(
      String value,
      ) {
    if (value.trim().isEmpty) {
      return 'Tarih bilgisi yok';
    }

    final DateTime? date =
    DateTime.tryParse(
      value,
    );

    if (date == null) {
      return value;
    }

    final DateTime localDate =
    date.toLocal();

    final DateTime now =
    DateTime.now();

    final Duration difference =
    now.difference(
      localDate,
    );

    if (
    difference.isNegative ||
        difference.inMinutes < 1
    ) {
      return 'Az önce';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    }

    if (difference.inDays == 1) {
      return 'Dün';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    }

    final String day =
    localDate.day
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String month =
    localDate.month
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$day.$month.${localDate.year}';
  }
}