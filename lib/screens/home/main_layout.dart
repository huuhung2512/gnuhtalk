import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'chats_list_page.dart';
import 'friends_page.dart';
import '../settings/settings_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    const ChatsListPage(),
    const FriendsPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgLight,
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.bgLight,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textLightGray,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Image.asset(
                  'assets/images/tab_chat.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 0
                      ? AppColors.primaryBlue
                      : AppColors.textLightGray,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.chat_bubble_outline),
                ),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Image.asset(
                  'assets/images/tab_friends.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 1
                      ? AppColors.primaryBlue
                      : AppColors.textLightGray,
                  errorBuilder: (c, e, s) => const Icon(Icons.people_outline),
                ),
              ),
              label: 'Bạn bè',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Image.asset(
                  'assets/images/tab_settings.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 2
                      ? AppColors.primaryBlue
                      : AppColors.textLightGray,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.settings_outlined),
                ),
              ),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}
