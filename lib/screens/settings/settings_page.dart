import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  String _displayName = "Loading...";
  String _email = "";
  String _currentLanguage = "en";

  final List<Map<String, String>> _languages = [
    {'code': 'vi', 'name': 'Tiếng Việt'},
    {'code': 'en', 'name': 'English'},
    {'code': 'ko', 'name': '한국어'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'zh-CN', 'name': '中文'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    if (_user == null) return;

    _email = _user.email ?? "";

    final doc = await _db.collection('users').doc(_user.uid).get();
    if (doc.exists) {
      if (!mounted) return;
      setState(() {
        _displayName = doc.data()?['name'] ?? "User";
        _currentLanguage = doc.data()?['language'] ?? "en";
      });
    }
  }

  void _updateLanguage(String newLangCode) async {
    if (_user == null) return;
    await _db.collection('users').doc(_user.uid).update({
      'language': newLangCode,
    });
    if (!mounted) return;
    setState(() {
      _currentLanguage = newLangCode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language updated successfully.')),
    );
  }

  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgInput, // F9FAFB in XAML
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Padding(
                padding: EdgeInsets.only(left: 5, bottom: 10),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),

              // Profile Card
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textLightGray.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: AppColors.borderLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Preferences Label
              const Padding(
                padding: EdgeInsets.only(left: 10, top: 10, bottom: 5),
                child: Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLightGray,
                  ),
                ),
              ),

              // Preferences Box
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Column(
                  children: [
                    // Language Setting
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/ic_globe.png',
                            width: 26,
                            height: 26,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.language,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'App Translation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  'Auto-translate target',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _currentLanguage,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primaryBlue,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) _updateLanguage(newValue);
                              },
                              items: _languages.map<DropdownMenuItem<String>>((
                                lang,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: lang['code'],
                                  child: Text(lang['name']!),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 1,
                      color: AppColors.surfaceLight,
                      margin: const EdgeInsets.only(left: 60),
                    ),

                    // Notifications Fake UI
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/ic_bell.png',
                            width: 26,
                            height: 26,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.notifications_active,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Switch(
                            value: true,
                            onChanged: (val) {},
                            activeTrackColor: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Support Label
              const Padding(
                padding: EdgeInsets.only(left: 10, top: 10, bottom: 5),
                child: Text(
                  'SUPPORT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLightGray,
                  ),
                ),
              ),

              // Support Box
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/ic_info.png',
                        width: 26,
                        height: 26,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.info, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'About GnuhTalk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Version 1.0.0 (Groq AI)',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '❯',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLightGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Logout Button
              GestureDetector(
                onTap: _logout,
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ic_logout.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.logout, color: AppColors.error),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
