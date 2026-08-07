import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'device_service.dart';
import 'explore_screen.dart';
import 'notification_service.dart';
import 'notifications_screen.dart';
import 'upload_screen.dart';
import 'wallet_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({
    super.key,
  });

  @override
  State<MainLayout> createState() =>
      _MainLayoutState();
}

class _MainLayoutState
    extends State<MainLayout> {
NotificationService? _notificationService;

List<Widget> _sayfalar =
<Widget>[];

Timer? _notificationTimer;

int _secilenIndeks = 0;
int _unreadCount = 0;

bool _isLoadingUser = true;
bool _isLoadingUnreadCount = false;

String? _initializationError;

@override
void initState() {
super.initState();

_initializeUser();
}

// =========================================================
// KULLANICIYI HAZIRLA
// =========================================================

Future<void> _initializeUser() async {
try {
final String userId =
await DeviceService
.getDeviceId();

if (!mounted) {
return;
}

if (userId.trim().isEmpty) {
setState(() {
_isLoadingUser =
false;

_initializationError =
'Kullanıcı bilgisi alınamadı.';
});

return;
}

_notificationService =
NotificationService(
userId:
userId,
);

_sayfalar =
<Widget>[
const ExploreScreen(),

const UploadScreen(),

NotificationsScreen(
userId:
userId,

onNotificationsChanged:
_loadUnreadCount,
),

const WalletScreen(),
];

setState(() {
_isLoadingUser =
false;

_initializationError =
null;
});

await _loadUnreadCount();

if (!mounted) {
return;
}

_notificationTimer?.cancel();

_notificationTimer =
Timer.periodic(
const Duration(
seconds:
30,
),
(
Timer timer,
) {
_loadUnreadCount();
},
);
} catch (error) {
debugPrint(
'Ana kullanıcı başlatma hatası: $error',
);

if (!mounted) {
return;
}

setState(() {
_isLoadingUser =
false;

_initializationError =
'Kullanıcı bilgileri hazırlanamadı.';
});
}
}

@override
void dispose() {
_notificationTimer
?.cancel();

super.dispose();
}

// =========================================================
// OKUNMAMIŞ BİLDİRİM SAYISI
// =========================================================

Future<void> _loadUnreadCount() async {
if (
_isLoadingUnreadCount ||
_notificationService == null
) {
return;
}

_isLoadingUnreadCount =
true;

try {
final Map<String, dynamic> result =
await _notificationService!
.getUnreadCount();

if (!mounted) {
return;
}

if (result['success'] != true) {
return;
}

final int unreadCount =
int.tryParse(
result['unread_count']
?.toString() ??
'0',
) ??
0;

setState(() {
_unreadCount =
unreadCount < 0
? 0
: unreadCount;
});
} catch (error) {
debugPrint(
'Okunmamış bildirim sayısı hatası: $error',
);
} finally {
_isLoadingUnreadCount =
false;
}
}

// =========================================================
// SAYFA DEĞİŞTİR
// =========================================================

void _changePage(
int index,
) {
if (
index < 0 ||
index >= _sayfalar.length
) {
return;
}

setState(() {
_secilenIndeks =
index;
});

if (index == 2) {
_loadUnreadCount();
}
}

// =========================================================
// BİLDİRİM İKONU + ROZET
// =========================================================

Widget _buildNotificationIcon({
required bool active,
}) {
final IconData icon =
active
? Icons.notifications_rounded
: Icons.notifications_outlined;

return Stack(
clipBehavior:
Clip.none,

children: [
Icon(
icon,
),

if (_unreadCount > 0)
Positioned(
top:
-7,

right:
-11,

child:
Container(
constraints:
const BoxConstraints(
minWidth:
19,

minHeight:
19,
),

padding:
const EdgeInsets.symmetric(
horizontal:
5,

vertical:
2,
),

decoration:
const BoxDecoration(
color:
AppColors.error,

shape:
BoxShape.circle,
),

alignment:
Alignment.center,

child:
Text(
_unreadCount > 99
? '99+'
: _unreadCount
.toString(),

style:
const TextStyle(
color:
Colors.white,

fontSize:
9,

fontWeight:
FontWeight.w800,

height:
1,
),
),
),
),
],
);
}
  // =========================================================
  // ANA EKRAN
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor:
        AppColors.background,
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_initializationError != null) {
      return Scaffold(
        backgroundColor:
        AppColors.background,

        body:
        SafeArea(
          child:
          Center(
            child:
            Padding(
              padding:
              const EdgeInsets.all(
                24,
              ),

              child:
              Column(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color:
                    AppColors.error,
                    size:
                    58,
                  ),

                  const SizedBox(
                    height:
                    16,
                  ),

                  const Text(
                    'Uygulama hazırlanamadı',
                    textAlign:
                    TextAlign.center,
                    style:
                    TextStyle(
                      color:
                      AppColors.textPrimary,
                      fontSize:
                      18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                    8,
                  ),

                  Text(
                    _initializationError!,
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
                    height:
                    20,
                  ),

                  ElevatedButton.icon(
                    onPressed:
                        () {
                      setState(() {
                        _isLoadingUser =
                        true;

                        _initializationError =
                        null;
                      });

                      _initializeUser();
                    },

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
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body:
      IndexedStack(
        index:
        _secilenIndeks,

        children:
        _sayfalar,
      ),

      bottomNavigationBar:
      Container(
        decoration:
        const BoxDecoration(
          color:
          AppColors.navigationBar,

          border:
          Border(
            top:
            BorderSide(
              color:
              AppColors.borderSoft,
              width:
              1,
            ),
          ),
        ),

        child:
        SafeArea(
          top:
          false,

          child:
          BottomNavigationBar(
            currentIndex:
            _secilenIndeks,

            type:
            BottomNavigationBarType.fixed,

            onTap:
            _changePage,

            items:
            <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                activeIcon:
                Icon(
                  Icons.grid_view_rounded,
                ),

                icon:
                Icon(
                  Icons.grid_view_outlined,
                ),

                label:
                'Keşfet',
              ),

              const BottomNavigationBarItem(
                activeIcon:
                Icon(
                  Icons.add_circle_rounded,
                ),

                icon:
                Icon(
                  Icons.add_circle_outline_rounded,
                ),

                label:
                'Not Yükle',
              ),

              BottomNavigationBarItem(
                activeIcon:
                _buildNotificationIcon(
                  active:
                  true,
                ),

                icon:
                _buildNotificationIcon(
                  active:
                  false,
                ),

                label:
                'Bildirimler',
              ),

              const BottomNavigationBarItem(
                activeIcon:
                Icon(
                  Icons.account_balance_wallet_rounded,
                ),

                icon:
                Icon(
                  Icons.account_balance_wallet_outlined,
                ),

                label:
                'Cüzdanım',
              ),
            ],
          ),
        ),
      ),
    );
  }
}