import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream Rooms (only rooms where current user is a participant)
  Stream<QuerySnapshot> getRooms() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('rooms')
        .where('participants', arrayContains: uid)
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  // Create a Group Room with selected participants
  Future<void> createRoom(String roomName, List<String> memberUids) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Always include the creator
    final participants = <String>{uid, ...memberUids}.toList();

    await _db.collection('rooms').add({
      'name': roomName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'type': participants.length == 2 ? 'private' : 'group',
      'participants': participants,
    });
  }

  // Get User Current Language
  Future<String> getUserLanguage(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['language'] ?? 'en';
    } catch (e) {
      return 'en';
    }
  }

  // Stream Messages
  Stream<QuerySnapshot> getMessages(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send Message
  Future<void> sendMessage(
    String roomId,
    String text,
    String senderName,
    String senderLanguage,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final msgData = {
      'text': text,
      'senderId': user.uid,
      'senderName': senderName,
      'senderLanguage': senderLanguage,
      'isTranslated': false,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add(msgData);

    // Update Room timestamp
    await _db.collection('rooms').doc(roomId).update({
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastMessage': text,
    });

    // Send Push Notifications
    _sendPushToRoomParticipants(roomId, text, senderName, user.uid);
  }

  // Send Image Message (Base64 stored in Firestore)
  Future<void> sendImage(
    String roomId,
    File imageFile,
    String senderName,
    String senderLanguage,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Read file and convert to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final msgData = {
      'type': 'image',
      'imageBase64': base64Image,
      'text': '📷 Hình ảnh',
      'senderId': user.uid,
      'senderName': senderName,
      'senderLanguage': senderLanguage,
      'isTranslated': true, // No need to translate images
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add(msgData);

    await _db.collection('rooms').doc(roomId).update({
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastMessage': '📷 Hình ảnh',
    });

    _sendPushToRoomParticipants(roomId, '📷 Hình ảnh', senderName, user.uid);
  }

  Future<void> _sendPushToRoomParticipants(
    String roomId,
    String text,
    String senderName,
    String senderUid,
  ) async {
    try {
      final roomSnap = await _db.collection('rooms').doc(roomId).get();
      if (!roomSnap.exists) return;

      final roomData = roomSnap.data();
      final participants = List<String>.from(roomData?['participants'] ?? []);

      var notificationTitle = senderName;
      if (roomData?['type'] == 'group') {
        final roomName = roomData?['name'] ?? 'Group Chat';
        notificationTitle = '$roomName ($senderName)';
      }

      for (String uid in participants) {
        if (uid != senderUid) {
          final userSnap = await _db.collection('users').doc(uid).get();
          if (userSnap.exists) {
            final fcmToken = userSnap.data()?['fcmToken'];
            if (fcmToken != null && fcmToken.isNotEmpty) {
              await NotificationService().sendPushNotification(
                fcmToken,
                notificationTitle,
                text,
              );
            }
          }
        }
      }
    } catch (e) {
      print("Error triggering FCM: $e");
    }
  }
}
