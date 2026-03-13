import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/chat_service.dart';
import '../../services/friends_service.dart';
import '../chat/chat_screen.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({Key? key}) : super(key: key);

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final ChatService _chatService = ChatService();
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _createRoomController = TextEditingController();

  void _createNewRoom() {
    final selectedFriends = <String, String>{}; // uid -> name

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.bgLight,
              title: const Text(
                'Tạo phòng chat mới',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Room Name Input
                    TextField(
                      controller: _createRoomController,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Tên phòng chat',
                        hintStyle: const TextStyle(
                          color: AppColors.textLightGray,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mời bạn bè:',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Friends List with checkboxes
                    SizedBox(
                      height: 200,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _friendsService.getFriends(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'Chưa có bạn bè nào.\nHãy thêm bạn bè trước!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textGray),
                              ),
                            );
                          }
                          final friends = snapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friendData =
                                  friends[index].data() as Map<String, dynamic>;
                              final friendId =
                                  friendData['friendId'] ?? friends[index].id;

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _friendsService.getUserDetails(
                                  friendId,
                                ),
                                builder: (context, userSnap) {
                                  if (!userSnap.hasData ||
                                      userSnap.data == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final user = userSnap.data!;
                                  final name = user['name'] ?? 'Unknown';
                                  final email = user['email'] ?? '';
                                  final isSelected = selectedFriends
                                      .containsKey(friendId);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        if (val == true) {
                                          selectedFriends[friendId] = name;
                                        } else {
                                          selectedFriends.remove(friendId);
                                        }
                                      });
                                    },
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      email,
                                      style: const TextStyle(
                                        color: AppColors.textGray,
                                        fontSize: 12,
                                      ),
                                    ),
                                    activeColor: AppColors.primaryBlue,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (selectedFriends.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Đã chọn: ${selectedFriends.values.join(", ")}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _createRoomController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Huỷ',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final roomName = _createRoomController.text.trim();
                    if (roomName.isNotEmpty && selectedFriends.isNotEmpty) {
                      _chatService.createRoom(
                        roomName,
                        selectedFriends.keys.toList(),
                      );
                      _createRoomController.clear();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text('Tạo phòng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header exactly like OldTalkApp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/ic_search.png',
                    width: 26,
                    height: 26,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.search, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 15),
                  Image.asset(
                    'assets/images/ic_info.png',
                    width: 26,
                    height: 26,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.info_outline,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // Chat List (From Firebase)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // Empty State exactly like OldTalkApp
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/img_empty_chat.png',
                            width: 250,
                            height: 250,
                            errorBuilder: (c, e, s) =>
                                const SizedBox(height: 100),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Nothing in inbox',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Enjoy your day',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final rooms = snapshot.data!.docs;

                  return RefreshIndicator(
                    onRefresh: () async {}, // Handle refresh logic if needed
                    color: AppColors.primaryBlue,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 80),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final roomData =
                            rooms[index].data() as Map<String, dynamic>;
                        final roomId = rooms[index].id;
                        final roomType = roomData['type'] ?? 'group';
                        final participants = List<String>.from(
                          roomData['participants'] ?? [],
                        );
                        String defaultRoomName =
                            roomData['name'] ?? 'Unknown Room';
                        final lastMessage = roomData['lastMessage'] ?? '...';
                        // Simple time formatter
                        final timestamp = roomData['lastUpdated'] as Timestamp?;
                        final timeString = timestamp != null
                            ? "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                            : "";

                        // If it's a 1-on-1 chat, we fetch the other user's name
                        final currentUser = FirebaseAuth.instance.currentUser;
                        String? otherUserId;
                        if (roomType == 'private' &&
                            participants.length == 2 &&
                            currentUser != null) {
                          otherUserId = participants.firstWhere(
                            (id) => id != currentUser.uid,
                            orElse: () => '',
                          );
                        }

                        return FutureBuilder<DocumentSnapshot?>(
                          future:
                              (otherUserId != null && otherUserId.isNotEmpty)
                              ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(otherUserId)
                                    .get()
                              : Future<DocumentSnapshot?>.value(null),
                          builder: (context, userSnap) {
                            String displayRoomName = defaultRoomName;
                            if (userSnap.hasData &&
                                userSnap.data != null &&
                                userSnap.data!.exists) {
                              displayRoomName =
                                  userSnap.data!.get('name') ?? defaultRoomName;
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      roomId: roomId,
                                      roomName: displayRoomName,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 55,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        displayRoomName.isNotEmpty
                                            ? displayRoomName[0].toUpperCase()
                                            : '💬',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: AppColors.textGray,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    // Text Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayRoomName,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            lastMessage,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textGray,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Time
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          timeString,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textLightGray,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ), // Spacing to align top
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // FAB exactly like OldTalkApp
      floatingActionButton: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.4),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _createNewRoom,
            child: const Center(
              child: Text(
                '➕',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
