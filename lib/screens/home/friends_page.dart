import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/friends_service.dart';
import '../chat/chat_screen.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _searchFriends() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _friendsService.searchUsersByEmail(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _sendFriendRequest(String userId) async {
    await _friendsService.sendFriendRequest(userId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu kết bạn.')));
    _searchController.clear();
    _searchFriends();
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.bgLight,
              title: const Text(
                'Thêm bạn bè',
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
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Nhập email...',
                        hintStyle: const TextStyle(
                          color: AppColors.textLightGray,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: AppColors.textGray,
                          ),
                          onPressed: () async {
                            final query = _searchController.text.trim();
                            if (query.isEmpty) return;
                            setStateDialog(() => _isSearching = true);
                            final results = await _friendsService
                                .searchUsersByEmail(query);
                            setStateDialog(() {
                              _searchResults = results;
                              _isSearching = false;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_isSearching) const CircularProgressIndicator(),
                    if (!_isSearching && _searchResults.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surfaceLight,
                                child: Text(
                                  (user['name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                user['email'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.textGray,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.person_add,
                                  color: AppColors.primaryBlue,
                                ),
                                onPressed: () {
                                  _sendFriendRequest(user['id']);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    if (!_isSearching &&
                        _searchResults.isEmpty &&
                        _searchController.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Không tìm thấy người dùng",
                          style: TextStyle(color: AppColors.textGray),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchResults.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: AppColors.textGray),
                  ),
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bạn bè',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddFriendDialog,
                    child: Image.asset(
                      'assets/images/ic_add_friend.png',
                      width: 26,
                      height: 26,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.person_add,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lời mời kết bạn (Pending Requests)
            StreamBuilder<QuerySnapshot>(
              stream: _friendsService.getFriendRequests(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const SizedBox.shrink();

                final requests = snapshot.data!.docs;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lời mời kết bạn',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final reqMap =
                              requests[index].data() as Map<String, dynamic>;
                          final fromUserId = reqMap['fromUserId'];

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _friendsService.getUserDetails(fromUserId),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData) {
                                return const SizedBox.shrink();
                              }
                              final user = userSnap.data!;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppColors.bgLight,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        (user['name'] ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          Text(
                                            '${user['language'] ?? 'en'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _friendsService
                                          .acceptRequest(fromUserId),
                                      child: Image.asset(
                                        'assets/images/ic_accept.png',
                                        width: 32,
                                        height: 32,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.check_circle,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _friendsService
                                          .declineRequest(fromUserId),
                                      child: Image.asset(
                                        'assets/images/ic_reject.png',
                                        width: 32,
                                        height: 32,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.cancel,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // Danh sách bạn bè chính
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _friendsService.getFriends(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // Empty State
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/img_empty_friends.png',
                            width: 250,
                            height: 250,
                            errorBuilder: (c, e, s) =>
                                const SizedBox(height: 100),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Welcome to GnuhTalk',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Kết nối với bạn bè trên toàn thế giới!',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final friends = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friendData =
                          friends[index].data() as Map<String, dynamic>;
                      final friendId = friendData['friendId'];

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _friendsService.getUserDetails(friendId),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) {
                            return const SizedBox.shrink();
                          }
                          final user = userSnap.data!;

                          return GestureDetector(
                            onTap: () {
                              // Compute the 1-on-1 room ID (same logic as FriendsService)
                              final currentUid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (currentUid == null) return;
                              final userIds = [currentUid, friendId]..sort();
                              final roomId = '${userIds[0]}_${userIds[1]}';
                              final displayName = user['name'] ?? 'Chat';

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    roomId: roomId,
                                    roomName: displayName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.bgLight,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (user['name'] ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          user['email'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textLightGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppColors.primaryBlue,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
