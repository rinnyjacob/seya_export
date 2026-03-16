import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_birth_details_widget.dart';


class ExpertChatScreen extends StatefulWidget {
  final String callId;
  final String userName;
  final String userId;

  const ExpertChatScreen({
    super.key,
    required this.callId,
    required this.userName,
    required this.userId,
  });

  @override
  State<ExpertChatScreen> createState() => _ExpertChatScreenState();
}

class _ExpertChatScreenState extends State<ExpertChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  int _seconds = 0;
  bool _showEmojiPicker = false;
  String? _replyingToId;
  Map<String, dynamic>? _replyingToData;
  bool _isUploading = false;
  String? _highlightedMsgId;
  bool _userScrolledUp = false;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();

    _startTimer();
    _listenForEnd();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    // If user is more than 100px from bottom, consider scrolled up
    setState(() {
      _userScrolledUp = (max - offset) > 100;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted) return;
        // Only update timer if widget is visible
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          setState(() => _seconds++);
        }
      },
    );
  }

  void _listenForEnd() {
    FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['status'] == 'ended' && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && !_isUploading) return;

    final messageData = {
      'senderRole': 'expert',
      'message': text.isNotEmpty ? text : '[File attachment]',
      'type': text.isNotEmpty ? 'text' : 'file',
      'createdAt': FieldValue.serverTimestamp(),
      if (_replyingToId != null && _replyingToData != null)
        'replyTo': {
          'id': _replyingToId,
          'text': _replyingToData!['message'] ?? '',
          'senderId': _replyingToData!['senderId'] ?? widget.userId,
          'senderRole': _replyingToData!['senderRole'] ?? '',
        },
    };

    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .collection('messages')
        .add(messageData);

    _msgCtrl.clear();
    _replyingToId = null;
    _replyingToData = null;
    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadFile() async {
    try {
      setState(() => _isUploading = true);

      final result = await FilePicker.platform.pickFiles();
      if (result == null) {
        setState(() => _isUploading = false);
        return;
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileSize = file.lengthSync();

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_files/${widget.callId}/$fileName');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('call_requests')
          .doc(widget.callId)
          .collection('messages')
          .add({
        'senderRole': 'expert',
        'senderId': FirebaseAuth.instance.currentUser!.uid, // Use expert id if available, else userId
        'message': fileName, // Pass file name as message, or custom text
        'type': 'file',
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'fileSize': fileSize,
        'createdAt': FieldValue.serverTimestamp(),
        if (_replyingToId != null && _replyingToData != null)
          'replyTo': {
            'id': _replyingToId,
            'text': _replyingToData!['message'] ?? '',
            'senderId': _replyingToData!['senderId'] ?? widget.userId,
            'senderRole': _replyingToData!['senderRole'] ?? '',
          },
      });

      _msgCtrl.clear();
      _replyingToId = null;
      _replyingToData = null;

      if (mounted) {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    }
  }

  void _showBirthDetailsDialog(Map<String, dynamic> birthDetails) {
    final dateOfBirthTimestamp = birthDetails['dateOfBirth'] as Timestamp?;
    if (dateOfBirthTimestamp == null) return;

    final birthDate = dateOfBirthTimestamp.toDate();
    final age = UserBirthDetailsWidget.calculateAge(birthDate);
    final zodiac = UserBirthDetailsWidget.getZodiacSign(birthDate);
    final formattedDate = UserBirthDetailsWidget.formatBirthDate(birthDate);

    final fullName = birthDetails['fullName'] as String? ?? 'User';
    final gender = birthDetails['gender'] as String? ?? '';
    String placeOfBirth = birthDetails['placeOfBirth'] as String? ?? '';
    if (placeOfBirth.isEmpty) {
      final city = birthDetails['place_of_birth_city'] as String? ?? '';
      final state = birthDetails['place_of_birth_state'] as String? ?? '';
      final country = birthDetails['place_of_birth_country'] as String? ?? '';
      placeOfBirth = [city, state, country].where((e) => e.isNotEmpty).join(', ');
    }
    final timeOfBirth = birthDetails['timeOfBirth'] as String? ?? '';
    String concern = '';
    if (birthDetails['concern'] is String) {
      concern = birthDetails['concern'] as String;
    } else if (birthDetails['concern'] is List) {
      concern = (birthDetails['concern'] as List).whereType<String>().join(', ');
    }
    final relationship = birthDetails['relationship'] as String? ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: bgColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Birth Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.close,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Name Section
                Text(
                  fullName,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Age & Zodiac
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$age yrs',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        zodiac,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Divider
                Divider(
                  color: primaryColor.withValues(alpha: 0.2),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 28),

                // Details
                Column(
                  children: [
                    if (formattedDate.isNotEmpty)
                      _buildSimpleDetailRow(
                        'Date of Birth',
                        formattedDate,
                        primaryColor,
                        isDark,
                      ),
                    if (gender.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSimpleDetailRow(
                        'Gender',
                        gender,
                        primaryColor,
                        isDark,
                      ),
                    ],
                    if (placeOfBirth.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSimpleDetailRow(
                        'Place of Birth',
                        placeOfBirth,
                        primaryColor,
                        isDark,
                      ),
                    ],
                    if (timeOfBirth.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSimpleDetailRow(
                        'Time of Birth',
                        timeOfBirth,
                        primaryColor,
                        isDark,
                      ),
                    ],
                    if (concern.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSimpleDetailRow(
                        'Concern',
                        concern,
                        primaryColor,
                        isDark,
                      ),
                    ],
                    if (relationship.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSimpleDetailRow(
                        'Relationship',
                        relationship,
                        primaryColor,
                        isDark,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleDetailRow(
    String label,
    String value,
    Color primaryColor,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Future<void> _endChat() async {
    _timer?.cancel();

    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .update({
      'status': 'ended',
      'endedBy': 'expert',
      'endedAt': FieldValue.serverTimestamp(),
      'durationSeconds': _seconds,
    });

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  void _setReply(String messageId, Map<String, dynamic> messageData) {
    setState(() {
      _replyingToId = messageId;
      _replyingToData = {
        'message': messageData['message'] ?? '',
        'senderRole': messageData['senderRole'] ?? '',
        'senderId': messageData['senderId'] ?? '',
        'type': messageData['type'] ?? messageData['messageType'] ?? 'text',
      };
    });
  }

  void _clearReply() {
    setState(() {
      _replyingToId = null;
      _replyingToData = null;
    });
  }

  void _scrollToMessage(String msgId) {
    setState(() => _highlightedMsgId = msgId);
    // Wait for build, then scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _messageKeyMap[msgId]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
    // Remove highlight after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMsgId = null);
    });
  }

  final Map<String, GlobalKey> _messageKeyMap = {};

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmEndChat() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Conversation'),
        content: const Text('Do you want to end the conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (shouldEnd == true) {
      await _endChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldEnd = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('End Conversation'),
            content: const Text('Do you want to end the conversation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (shouldEnd == true) {
          await _endChat();
          return false;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.userName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'LIVE CHAT',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
              const SizedBox(height: 4),
              if (widget.userId.isNotEmpty)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('call_requests')
                      .doc(widget.callId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final callData = snapshot.data!.data() as Map<String, dynamic>;
                      final birthDetails = callData['birthDetails'] as Map<String, dynamic>?;
                      if (birthDetails != null) {
                        return UserBirthDetailsWidget(
                          userId: widget.userId,
                          birthDetailsData: birthDetails,
                          isCompact: true,
                          textColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          actions: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('call_requests')
                  .doc(widget.callId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final callData = snapshot.data!.data() as Map<String, dynamic>;
                final birthDetails = callData['birthDetails'] as Map<String, dynamic>?;

                if (birthDetails == null) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  icon: const Icon(Icons.info_outline),
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  onPressed: () => _showBirthDetailsDialog(birthDetails),
                  tooltip: 'View Birth Details',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.call_end),
              color: Colors.red,
              onPressed: _confirmEndChat,
              tooltip: 'End Chat',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                const Color(0xFF0F172A),
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
              ]
                  : [
                AppColors.lightPrimary.withValues(alpha: 0.05),
                Colors.white,
                AppColors.lightPrimary.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _messages(Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.lightPrimary, Theme.of(context).brightness == Brightness.dark)),
              if (_replyingToData != null) _buildReplyPreview(Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.lightPrimary, Theme.of(context).brightness == Brightness.dark),
              _input(Theme.of(context).brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.lightPrimary, Theme.of(context).brightness == Brightness.dark),
              // if (_showEmojiPicker) _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: primaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingToData!['senderRole'] == 'expert' ? 'You' : 'User'}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingToData!['message'] ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: primaryColor,
            iconSize: 18,
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  // Widget _buildEmojiPicker() {
  //   return SizedBox(
  //     height: 250,
  //     child: EmojiPicker(
  //       onEmojiSelected: (category, emoji) {
  //         _msgCtrl.text += emoji.emoji;
  //       },
  //       onBackspacePressed: () {
  //         _msgCtrl.text = _msgCtrl.text.characters.skipLast(1).string;
  //       },
  //     ),
  //   );
  // }

  Widget _messages(Color primaryColor, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('call_requests')
          .doc(widget.callId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        final docs = snap.data!.docs;
        // Only scroll if new message is added and user is at the bottom
        if (_lastMessageCount != docs.length && !_userScrolledUp && _scrollController.hasClients && (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        }
        _lastMessageCount = docs.length;
        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          children: docs.map((d) {
            final messageId = d.id;
            final m = d.data() as Map<String, dynamic>;
            final isExpert = m['senderRole'] == 'expert';
            final messageType = m['type'] ?? m['messageType'] ?? 'text';
            final replyTo = m['replyTo'] as Map<String, dynamic>?;
            log('lsrtgdsjkf ${m['type']}');
            final legacyReply = m['replyingToData'] as Map<String, dynamic>?;
            final timestamp = m['createdAt'] as Timestamp?;
            final time = timestamp != null ? _formatTime(timestamp.toDate()) : '';
            final msgKey = _messageKeyMap.putIfAbsent(messageId, () => GlobalKey());
            final isHighlighted = _highlightedMsgId == messageId;

            // File attachment variables
            String fileUrl = '';
            String fileName = '';
            bool isImage = false;
            if (messageType == 'file') {
              fileUrl = m['fileUrl']?.toString() ?? '';
              fileName = m['fileName']?.toString() ?? '';
              isImage = fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.jpeg') ||
                  fileName.toLowerCase().endsWith('.png') ||
                  fileName.toLowerCase().endsWith('.gif');
            }

            return Align(
              alignment: isExpert ? Alignment.centerRight : Alignment.centerLeft,
              child: Dismissible(
                key: ValueKey(messageId),
                direction: isExpert ? DismissDirection.startToEnd : DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  _setReply(messageId, m);
                  return false;
                },
                child: GestureDetector(
                  key: msgKey,
                  onLongPress: () async {
                    if (messageType == 'text' && (m['message'] ?? '').toString().isNotEmpty) {
                      await Clipboard.setData(ClipboardData(text: m['message']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message copied')),
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        isExpert ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          gradient: isExpert
                              ? LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [
                              isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade200,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isExpert ? 16 : 4),
                            bottomRight: Radius.circular(isExpert ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isExpert ? primaryColor : Colors.grey)
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                          border: isHighlighted
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (replyTo != null || legacyReply != null) ...[
                              InkWell(
                                onTap: () {
                                  final replyId = replyTo?['id'] ?? legacyReply?['id'];
                                  if (replyId != null) _scrollToMessage(replyId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '↳ ${(replyTo?['senderRole'] ?? legacyReply?['senderRole']) == 'expert' ? 'You' : 'User'}',
                                        style: TextStyle(
                                          color: isExpert
                                              ? Colors.white.withValues(alpha: 0.7)
                                              : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (replyTo?['text'] ?? legacyReply?['message'] ?? '').toString(),
                                        style: TextStyle(
                                          color: isExpert
                                              ? Colors.white
                                              : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (messageType == 'text')
                              Text(
                                m['message'] ?? '',
                                style: TextStyle(
                                  color: isExpert ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (messageType == 'file') ...[
                              if (isImage)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    fileUrl,
                                    width: MediaQuery.of(context).size.width * 0.75,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 220,
                                      color: Colors.grey.shade300,
                                      child: const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                )
                              else ...[
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isExpert ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                                    foregroundColor: isExpert ? Colors.white : Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Icon(Icons.download_rounded),
                                  onPressed: () {
                                    if (fileUrl.isNotEmpty) {
                                      // Use url_launcher or similar
                                      // launchUrl(Uri.parse(fileUrl));
                                    }
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(m['fileSize'] ?? 0),
                                  style: TextStyle(
                                    color: isExpert
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: isExpert ? 0 : 16,
                          right: isExpert ? 16 : 0,
                          top: 4,
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                )));
          }).toList(),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _input(Color primaryColor, bool isDark) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: GlassCard(
              borderRadius: 24,
              blur: 12,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        setState(() => _showEmojiPicker = !_showEmojiPicker);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: "Type a message…",
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      onTap: () {
                        if (_showEmojiPicker) {
                          setState(() => _showEmojiPicker = false);
                        }
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: primaryColor,
                      ),
                      onPressed: _isUploading ? null : _pickAndUploadFile,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isUploading ? null : _send,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: _isUploading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.white : Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
