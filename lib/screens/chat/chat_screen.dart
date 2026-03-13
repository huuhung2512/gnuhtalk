import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../utils/constants.dart';
import '../../services/chat_service.dart';
import '../../services/translation_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatScreen({Key? key, required this.roomId, required this.roomName})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final TranslationService _translationService = TranslationService();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String _currentUserLanguage = 'en';
  String _currentUserName = 'User';
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  bool _isListening = false;
  bool _isSendingImage = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _initSpeech();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (val) {
        setState(() => _isListening = false);
      },
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _loadUserPreferences() async {
    if (_currentUserId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (doc.exists) {
        setState(() {
          _currentUserLanguage = doc.data()?['language'] ?? 'en';
          _currentUserName = doc.data()?['name'] ?? 'User';
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    await _chatService.sendMessage(
      widget.roomId,
      text,
      _currentUserName,
      _currentUserLanguage,
    );
  }

  // Speech-to-Text toggle
  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể sử dụng microphone. Kiểm tra quyền!'),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);

      // Map user language code to speech locale
      String localeId = _getSpeechLocale(_currentUserLanguage);

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          });
        },
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  // Map language codes to speech recognition locale IDs
  String _getSpeechLocale(String langCode) {
    switch (langCode) {
      case 'vi':
        return 'vi_VN';
      case 'ko':
        return 'ko_KR';
      case 'ja':
        return 'ja_JP';
      case 'zh':
        return 'zh_CN';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'es':
        return 'es_ES';
      case 'th':
        return 'th_TH';
      case 'en':
      default:
        return 'en_US';
    }
  }

  // Pick and send image
  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      setState(() => _isSendingImage = true);

      await _chatService.sendImage(
        widget.roomId,
        File(pickedFile.path),
        _currentUserName,
        _currentUserLanguage,
      );

      setState(() => _isSendingImage = false);
    } catch (e) {
      setState(() => _isSendingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi gửi ảnh: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlue,
              ),
              title: const Text(
                'Chụp ảnh',
                style: TextStyle(color: AppColors.textDark),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryBlue,
              ),
              title: const Text(
                'Chọn từ thư viện',
                style: TextStyle(color: AppColors.textDark),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              color: AppColors.bgLight,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.asset(
                        'assets/images/ic_back.png',
                        width: 26,
                        height: 26,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.arrow_back,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('💬', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roomName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/ic_call.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.call, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 15),
                  Image.asset(
                    'assets/images/ic_video.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.videocam, color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            // Sending image indicator
            if (_isSendingImage)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đang gửi ảnh...',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ],
                ),
              ),

            // Messages List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessages(widget.roomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/img_empty_chat.png',
                            width: 200,
                            height: 200,
                            errorBuilder: (c, e, s) =>
                                const SizedBox(height: 100),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Gửi tin nhắn đầu tiên!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: messages.length,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    itemBuilder: (context, index) {
                      final msgMap =
                          messages[index].data() as Map<String, dynamic>;
                      final messageId = messages[index].id;
                      final isMe = msgMap['senderId'] == _currentUserId;
                      final text = msgMap['text'] ?? '';
                      final senderName = msgMap['senderName'] ?? 'Unknown';
                      final senderLanguage = msgMap['senderLanguage'] ?? 'en';
                      final isTranslated = msgMap['isTranslated'] ?? false;
                      final translatedTextDb = msgMap['translatedText'] ?? '';
                      final messageType = msgMap['type'] ?? 'text';

                      // Auto-translate text messages from others
                      if (!isMe && !isTranslated && messageType == 'text') {
                        _translationService
                            .translateMessage(
                              messageId,
                              text,
                              senderLanguage,
                              _currentUserLanguage,
                            )
                            .then((resultText) {
                              FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomId)
                                  .collection('messages')
                                  .doc(messageId)
                                  .update({
                                    'isTranslated': true,
                                    'translatedText': resultText,
                                  });
                            });
                      }

                      // Render image messages
                      if (messageType == 'image') {
                        return _buildImageBubble(
                          isMe: isMe,
                          imageBase64: msgMap['imageBase64'] ?? '',
                          senderName: senderName,
                          senderInitials: senderName.isNotEmpty
                              ? senderName[0].toUpperCase()
                              : 'U',
                        );
                      }

                      return _buildMessageBubble(
                        isMe: isMe,
                        text: text,
                        translatedText: isTranslated ? translatedTextDb : '',
                        senderName: senderName,
                        senderInitials: senderName.isNotEmpty
                            ? senderName[0].toUpperCase()
                            : 'U',
                        isLoadingTranslation: !isMe && !isTranslated,
                      );
                    },
                  );
                },
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 10,
                bottom: 15,
              ),
              decoration: const BoxDecoration(
                color: AppColors.bgLight,
                border: Border(
                  top: BorderSide(color: AppColors.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Attach Image Button
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Image.asset(
                      'assets/images/ic_attach.png',
                      width: 26,
                      height: 26,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.attach_file,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Input Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isListening
                            ? const Color(
                                0xFFE3F2FD,
                              ) // Light blue when listening
                            : AppColors.bgInput,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isListening
                              ? AppColors.primaryBlue
                              : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Đang nghe... hãy nói đi!'
                              : 'Type a message...',
                          hintStyle: TextStyle(
                            color: _isListening
                                ? AppColors.primaryBlue
                                : AppColors.textLightGray,
                            fontStyle: _isListening
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mic Button (Speech-to-Text)
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: _isListening
                          ? const Icon(Icons.mic, color: Colors.white, size: 22)
                          : Image.asset(
                              'assets/images/ic_mic.png',
                              width: 26,
                              height: 26,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.mic,
                                color: AppColors.textDark,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/ic_send.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== MESSAGE BUBBLE (TEXT) ==========
  Widget _buildMessageBubble({
    required bool isMe,
    required String text,
    required String translatedText,
    required String senderName,
    required String senderInitials,
    required bool isLoadingTranslation,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.borderLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                senderInitials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 1),
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      color: AppColors.textLightGray,
                      fontSize: 11,
                    ),
                  ),
                ),
              isMe
                  ? Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    )
                  : Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 0.5,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                              height: 1.25,
                            ),
                          ),
                          if (isLoadingTranslation ||
                              translatedText.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              height: 0.5,
                              color: const Color(0xFFD1D5DB),
                            ),
                            isLoadingTranslation
                                ? const SizedBox(
                                    height: 10,
                                    width: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Text(
                                    translatedText,
                                    style: const TextStyle(
                                      color: AppColors.textGray,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                          ],
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== IMAGE BUBBLE ==========
  Widget _buildImageBubble({
    required bool isMe,
    required String imageBase64,
    required String senderName,
    required String senderInitials,
  }) {
    Widget imageWidget;
    try {
      final bytes = base64Decode(imageBase64);
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          width: 150,
          height: 150,
          color: AppColors.surfaceLight,
          child: const Icon(Icons.broken_image, color: AppColors.textGray),
        ),
      );
    } catch (e) {
      imageWidget = Container(
        width: 150,
        height: 150,
        color: AppColors.surfaceLight,
        child: const Icon(Icons.broken_image, color: AppColors.textGray),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.borderLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                senderInitials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 1),
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      color: AppColors.textLightGray,
                      fontSize: 11,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => _showFullImage(context, imageBase64),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                      maxHeight: 250,
                    ),
                    child: imageWidget,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Full screen image viewer
  void _showFullImage(BuildContext context, String imageBase64) {
    try {
      final bytes = base64Decode(imageBase64);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể mở ảnh')));
    }
  }
}
