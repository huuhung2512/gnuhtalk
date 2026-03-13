import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search for users by email
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || email.isEmpty) return [];

    final querySnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .get();

    return querySnapshot.docs
        .where((doc) => doc.id != currentUserId) // Exclude self
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // Send a friend request
  Future<void> sendFriendRequest(String toUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _db
        .collection('users')
        .doc(toUserId)
        .collection('friend_requests')
        .doc(currentUserId)
        .set({
          'fromUserId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
  }

  // Stream Friend Requests
  Stream<QuerySnapshot> getFriendRequests() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Accept Friend Request
  Future<void> acceptRequest(String fromUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // 1. Add to my friends list
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(fromUserId)
        .set({
          'friendId': fromUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // 2. Add me to their friends list
    await _db
        .collection('users')
        .doc(fromUserId)
        .collection('friends')
        .doc(currentUserId)
        .set({
          'friendId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // 3. Delete the request
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests')
        .doc(fromUserId)
        .delete();

    // 4. Create a 1-1 Chat Room automatically
    await _create1on1Room(currentUserId, fromUserId);
  }

  // Decline Friend Request
  Future<void> declineRequest(String fromUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('friend_requests')
        .doc(fromUserId)
        .delete();
  }

  // Stream Friends List
  Stream<QuerySnapshot> getFriends() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .snapshots();
  }

  // Get User Details for Display
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data()!};
    }
    return null;
  }

  // Helper: Create a 1-1 room if not exists
  Future<String?> _create1on1Room(String user1, String user2) async {
    // A simple way to generate a unique room ID for 2 users
    List<String> userIds = [user1, user2];
    userIds.sort();
    String roomId = "${userIds[0]}_${userIds[1]}";

    final roomDoc = await _db.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      await _db.collection('rooms').doc(roomId).set({
        'name': '1-on-1 Chat',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'type': 'private',
        'participants': userIds,
      });
    }
    return roomId;
  }
}
