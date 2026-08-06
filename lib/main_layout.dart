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

class _MainLayoutState extends State<MainLayout> {
  String? _userId;

  NotificationService? _notificationService;

  List<Widget> _sayfalar = <Widget>[];

  Timer? _notificationTimer;

  int _secilenIndeks = 0;
  int _unreadCount = 0;

  bool _isLoadingUser = true;
  bool _isLoadingUnreadCount = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final String userId =
    await DeviceService.getDeviceId();

    if (!mounted) {
      return;
    }

    _notificationService =
        NotificationService(
          userId: userId,
        );

    _sayfalar = <Widget>[
      const ExploreScreen(),
      const UploadScreen(),
      NotificationsScreen(
        userId: userId,
        onNotificationsChanged:
        _loadUnreadCount,
      ),
      const WalletScreen(),
    ];

    setState(() {
      _userId = userId;
      _isLoadingUser = false;
    });

    await _loadUnreadCount();

    _notificationTimer =
        Timer.periodic(
          const Duration(seconds: 30),
              (_) {
            _loadUnreadCount();
          },
        );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    if (
    _isLoadingUnreadCount ||
        _notificationService == null
    ) {
      return;
    }

    _isLoadingUnreadCount = true;

    final Map<String, dynamic> result =
    await _notificationService!
        .getUnreadCount();

    _isLoadingUnreadCount = false;

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
      _unreadCount = unreadCount;
    });
  }

  void _changePage(int index) {
    setState(() {
      _secilenIndeks = index;
    });

    if (index == 2) {
      _loadUnreadCount();
    }
  }

  Widget _buildNotificationIcon({
    required bool active,
  }) {
    final IconData icon = active
        ? Icons.notifications_rounded
        : Icons.notifications_outlined;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),

        if (_unreadCount > 0)
          Positioned(
            top: -7,
            right: -11,
            child: Container(
              constraints:
              const BoxConstraints(
                minWidth: 19,
                minHeight: 19,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration:
              const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _unreadCount > 99
                    ? '99+'
                    : _unreadCount
                    .toString(),
                style:
                const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _secilenIndeks,
        children: _sayfalar,
      ),
      bottomNavigationBar: Container(
        decoration:
        const BoxDecoration(
          color:
          AppColors.navigationBar,
          border: Border(
            top: BorderSide(
              color:
              AppColors.borderSoft,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex:
            _secilenIndeks,
            type:
            BottomNavigationBarType
                .fixed,
            onTap: _changePage,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                activeIcon: Icon(
                  Icons.grid_view_rounded,
                ),
                icon: Icon(
                  Icons.grid_view_outlined,
                ),
                label: 'Keşfet',
              ),
              const BottomNavigationBarItem(
                activeIcon: Icon(
                  Icons.add_circle_rounded,
                ),
                icon: Icon(
                  Icons
                      .add_circle_outline_rounded,
                ),
                label: 'Not Yükle',
              ),
              BottomNavigationBarItem(
                activeIcon:
                _buildNotificationIcon(
                  active: true,
                ),
                icon:
                _buildNotificationIcon(
                  active: false,
                ),
                label: 'Bildirimler',
              ),
              const BottomNavigationBarItem(
                activeIcon: Icon(
                  Icons
                      .account_balance_wallet_rounded,
                ),
                icon: Icon(
                  Icons
                      .account_balance_wallet_outlined,
                ),
                label: 'Cüzdanım',
              ),
            ],
          ),
        ),
      ),
    );
  }
}