import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialize Local Notifications Plugin (for foreground)
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification clicked: ${response.payload}");
        // Handle payload to navigate later
      },
    );

    // 4. Create Notification Channel (Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 5. Store Token
    await _saveTokenToFirestore();
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken: newToken);
    });

    // 6. Foregorund Message Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              priority: Priority.max,
              importance: Importance.max,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  Future<void> _saveTokenToFirestore({String? newToken}) async {
    try {
      String? token = newToken ?? await _firebaseMessaging.getToken();
      if (token == null) return;
      print('FCM Token: $token');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  // Delete token when log out
  Future<void> deleteToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': FieldValue.delete()},
      );
    }
    await _firebaseMessaging.deleteToken();
  }

  // Send Push Notification
  Future<void> sendPushNotification(
    String targetToken,
    String title,
    String body,
  ) async {
    try {
      // 1. Load service account
      final String jsonString = await rootBundle.loadString(
        'assets/service-account.json',
      );
      final Map<String, dynamic> serviceAccount = jsonDecode(jsonString);

      // 2. Get Access Token
      final auth.ServiceAccountCredentials credentials =
          auth.ServiceAccountCredentials.fromJson(serviceAccount);
      final List<String> scopes = [
        'https://www.googleapis.com/auth/firebase.messaging',
      ];

      final auth.AutoRefreshingAuthClient client = await auth
          .clientViaServiceAccount(credentials, scopes);
      final String accessToken = client.credentials.accessToken.data;

      // 3. Prepare FCM V1 Payload
      final String projectId = serviceAccount['project_id'];
      final String url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': targetToken,
          'notification': {'title': title, 'body': body},
          'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
        },
      };

      // 4. Send HTTP Request
      final http.Response response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print("Push Notification Sent Successfully!");
      } else {
        print("Push Notification Failed: ${response.body}");
      }

      client.close();
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }
}
