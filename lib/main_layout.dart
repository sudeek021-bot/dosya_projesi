import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'explore_screen.dart';
import 'upload_screen.dart';
import 'wallet_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _secilenIndeks = 0;

  final List<Widget> _sayfalar = const [
    ExploreScreen(),
    UploadScreen(),
    WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _secilenIndeks,
        children: _sayfalar,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navigationBar,
          border: Border(
            top: BorderSide(
              color: AppColors.borderSoft,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _secilenIndeks,
            type: BottomNavigationBarType.fixed,
            onTap: (indeks) {
              setState(() {
                _secilenIndeks = indeks;
              });
            },
            items: const [
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.grid_view_rounded),
                icon: Icon(Icons.grid_view_outlined),
                label: 'Keşfet',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.add_circle_rounded),
                icon: Icon(Icons.add_circle_outline_rounded),
                label: 'Not Yükle',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(
                  Icons.account_balance_wallet_rounded,
                ),
                icon: Icon(
                  Icons.account_balance_wallet_outlined,
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
