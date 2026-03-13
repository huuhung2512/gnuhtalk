import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/constants.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_layout.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the settings from flutterfire configure
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Push Notifications
    await NotificationService().initNotification();
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        // TODO: add providers for Auth, Chat, Translation services
        Provider<String>.value(value: 'Placeholder'),
      ],
      child: const GnuhTalkApp(),
    ),
  );
}

class GnuhTalkApp extends StatelessWidget {
  const GnuhTalkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GnuhTalk',
      theme: appThemeData,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.bgLight,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainLayout();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
