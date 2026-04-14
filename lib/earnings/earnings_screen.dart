import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_doc_view.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expertId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        // backgroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('call_requests')
            .where('expertId', isEqualTo: expertId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error loading earnings: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = List.of(snap.data!.docs)
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bTime = (bData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bTime.compareTo(aTime);
            });

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          List<QueryDocumentSnapshot> todayCalls = [];
          List<QueryDocumentSnapshot> yesterdayCalls = [];
          double todayTotal = 0;
          double yesterdayTotal = 0;
          int completedCalls = 0;

          for (var d in allDocs) {
            final data = d.data() as Map<String, dynamic>;
            final amount = ((data['totalAmount'] ?? data['expertEarnings'] ?? 0) as num).toDouble();
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (data['status'] == 'completed' || data['status'] == 'ended') {
              completedCalls++;
            }
            if (createdAt != null) {
              final callDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
              if (callDate.isAtSameMomentAs(today)) {
                todayTotal += amount;
                todayCalls.add(d);
              } else if (callDate.isAtSameMomentAs(yesterday)) {
                yesterdayTotal += amount;
                yesterdayCalls.add(d);
              }
            }
          }

          Widget buildEarningsList(List<QueryDocumentSnapshot> docs, double total, String emptyMsg) {
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  emptyMsg,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ₹${total.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${docs.length} Calls',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = (data['totalAmount'] ?? 0).toDouble();
                  final status = data['status'] ?? 'pending';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final userName = data['userName'] ?? 'User';
                  final type = data['type'] ?? 'call';
                  final callId = doc.id;
                  return _EarningTileWithReview(
                    amount: amount,
                    status: status,
                    date: createdAt ?? DateTime.now(),
                    userName: userName,
                    type: type,
                    primaryColor: primaryColor,
                    callId: callId,
                  );
                }),
              ],
            );
          }

          return Column(
            children: [
              // Dashboard/statistics section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ModernStatCard(
                            label: "Today's Earning",
                            value: '₹${todayTotal.toStringAsFixed(0)}',
                            icon: Icons.today,
                            color: AppColors.onlineGreen,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModernStatCard(
                            label: 'Yesterday',
                            value: '₹${yesterdayTotal.toStringAsFixed(0)}',
                            icon: Icons.calendar_today,
                            color: AppColors.lightAccent,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ModernStatCard(
                            label: 'Completed',
                            value: completedCalls.toString(),
                            icon: Icons.check_circle,
                            color: primaryColor,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModernStatCard(
                            label: 'Total Calls',
                            value: allDocs.length.toString(),
                            icon: Icons.phone,
                            color: primaryColor.withValues(alpha: 0.71),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tabs for earnings lists
              TabBar(
                controller: _tabController,
                indicatorColor: primaryColor,
                labelColor: primaryColor,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                tabs: const [
                  Tab(text: "Today's Earnings"),
                  Tab(text: "Yesterday's Earnings"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildEarningsList(todayCalls, todayTotal, 'No earnings for today yet.'),
                    buildEarningsList(yesterdayCalls, yesterdayTotal, 'No earnings for yesterday.'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _ModernStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningTileWithReview extends StatefulWidget {
  final double amount;
  final String status;
  final DateTime date;
  final String userName;
  final String type;
  final Color primaryColor;
  final String callId;

  const _EarningTileWithReview({
    required this.amount,
    required this.status,
    required this.date,
    required this.userName,
    required this.type,
    required this.primaryColor,
    required this.callId,
  });

  @override
  State<_EarningTileWithReview> createState() => _EarningTileWithReviewState();
}

class _EarningTileWithReviewState extends State<_EarningTileWithReview> {
  late final Future<QuerySnapshot> _reviewFuture;

  @override
  void initState() {
    super.initState();
    _reviewFuture = FirebaseFirestore.instance
        .collection('expert_reviews')
        .where('callId', isEqualTo: widget.callId)
        .limit(1)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${widget.date.hour.toString().padLeft(2, '0')}:${widget.date.minute.toString().padLeft(2, '0')}';
    IconData typeIcon;
    switch (widget.type) {
      case 'video':
        typeIcon = Icons.videocam;
        break;
      case 'audio':
        typeIcon = Icons.call;
        break;
      case 'chat':
        typeIcon = Icons.chat;
        break;
      default:
        typeIcon = Icons.phone;
    }
    return FutureBuilder<QuerySnapshot>(
      future: _reviewFuture,
      builder: (context, reviewSnap) {
        String review = '';
        double? rating;
        if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
          final reviewData = reviewSnap.data!.docs.first.data() as Map<String, dynamic>;
          review = reviewData['feedback'] ?? '';
          rating = (reviewData['rating'] is num) ? (reviewData['rating'] as num).toDouble() : null;
        }
        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, color: widget.primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.userName,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${widget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: widget.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.type.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.status == 'ended' ? 'COMPLETED' : widget.status.toUpperCase(),
                      style: TextStyle(
                        color: widget.status == 'completed' || widget.status == 'ended'
                            ? Colors.green
                            : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if ((widget.status == 'completed' || widget.status == 'ended')) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < (rating ?? 0).round()
                            ? Icons.star
                            : Icons.star_border,
                        color: widget.primaryColor,
                        size: 18,
                      )),
                      const SizedBox(width: 8),
                      Text(
                        rating != null ? rating.toStringAsFixed(1) : 'No rating',
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (review.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        review,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (review.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        'No review',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
                if (widget.type == 'chat' && (widget.status == 'completed' || widget.status == 'ended'))
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(Icons.chat_bubble_outline, color: widget.primaryColor),
                      label: Text('View Chat', style: TextStyle(color: widget.primaryColor)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpertChatHistoryScreen(callId: widget.callId),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Extracted chat history widget for reuse
class ChatHistoryWidget extends StatefulWidget {
  final String callId;
  const ChatHistoryWidget({required this.callId, super.key});

  @override
  State<ChatHistoryWidget> createState() => _ChatHistoryWidgetState();
}

class _ChatHistoryWidgetState extends State<ChatHistoryWidget> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeyMap = {};

  // Pagination
  static const int _pageSize = 20;
  List<DocumentSnapshot> _messages = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _highlightedMsgId;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    final snap = await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .collection('messages')
        .orderBy('createdAt')
        .limit(_pageSize)
        .get();
    if (!mounted) return;
    setState(() {
      _messages = snap.docs;
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == _pageSize;
    });
    // scroll to bottom on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);

    final snap = await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .collection('messages')
        .orderBy('createdAt')
        .startAfterDocument(_lastDocument!)
        .limit(_pageSize)
        .get();
    if (!mounted) return;

    final previousOffset = _scrollController.offset;
    setState(() {
      _messages = [..._messages, ...snap.docs];
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : _lastDocument;
      _hasMore = snap.docs.length == _pageSize;
      _isLoadingMore = false;
    });
    // Keep scroll position stable after loading more at bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          (_scrollController.position.maxScrollExtent - previousOffset).abs() < 1
              ? _scrollController.position.maxScrollExtent
              : previousOffset,
        );
      }
    });
  }

  void _onScroll() {
    // Load more when near the bottom
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100) {
      _loadMoreMessages();
    }
  }

  void _scrollToMessage(String msgId) {
    setState(() => _highlightedMsgId = msgId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _messageKeyMap[msgId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMsgId = null);
    });
  }

  void _openFile(BuildContext context, String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocPreviewScreen(url: url, fileName: fileName),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    if (_messages.isEmpty && !_isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, idx) {
        // Loading indicator at the bottom
        if (idx == _messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final d = _messages[idx];
        final messageId = d.id;
        final m = d.data() as Map<String, dynamic>;
        final isExpert = m['senderRole'] == 'expert';
        final messageType = m['type'] ?? m['messageType'] ?? 'text';
        final replyTo = m['replyTo'] as Map<String, dynamic>?;
        final legacyReply = m['replyingToData'] as Map<String, dynamic>?;
        final timestamp = m['createdAt'] as Timestamp?;
        final time = timestamp != null
            ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
            : '';
        final isHighlighted = messageId == _highlightedMsgId;

        final msgKey = _messageKeyMap.putIfAbsent(messageId, () => GlobalKey());

        // File fields
        String fileUrl = '';
        String fileName = '';
        String messageText = (m['message'] ?? '').toString();
        bool isImage = false;
        if (messageType == 'file') {
          fileUrl = m['fileUrl']?.toString() ?? '';
          fileName = m['fileName']?.toString() ?? '';
          final fileLabel = (fileName.isNotEmpty ? fileName : messageText).toLowerCase();
          isImage = fileLabel.endsWith('.jpg') ||
              fileLabel.endsWith('.jpeg') ||
              fileLabel.endsWith('.png') ||
              fileLabel.endsWith('.gif') ||
              fileLabel.endsWith('.webp');
        }

        Widget bubble = GestureDetector(
          key: msgKey,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
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
                        isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        isDark ? Colors.grey.shade600 : Colors.grey.shade200,
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
                  color: (isExpert ? primaryColor : Colors.grey).withValues(alpha: 0.2),
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
                // Reply preview
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
                            '↳ ${(replyTo?['senderRole'] ?? legacyReply?['senderRole']) == 'expert' ? 'Expert' : 'User'}',
                            style: TextStyle(
                              color: isExpert
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : (isDark ? Colors.white70 : Colors.black54),
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
                                  : (isDark ? Colors.white : Colors.black87),
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

                // Message content
                if (messageType == 'text')
                  Text(
                    messageText,
                    style: TextStyle(
                      color: isExpert ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (messageType == 'file') ...[
                  if (isImage)
                    GestureDetector(
                      onTap: () => _openFile(context, fileUrl, fileName),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fileUrl,
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: Colors.grey.shade300,
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _openFile(context, fileUrl, fileName),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isExpert
                              ? Colors.white.withValues(alpha: 0.16)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isExpert
                                ? Colors.white.withValues(alpha: 0.28)
                                : Colors.grey.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_rounded,
                              color: isExpert ? Colors.white : primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName.isNotEmpty
                                        ? fileName
                                        : (messageText.isNotEmpty ? messageText : 'Document'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isExpert ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatFileSize(m['fileSize'] ?? 0)} • Tap to open',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      // color: isExpert
                                      //     ? Colors.white.withValues(alpha: 0.75)
                                      //     : Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isExpert
                          ? Colors.white.withValues(alpha: 0.7)
                          : (isDark ? Colors.white54 : Colors.grey.shade600),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return Align(
          alignment: isExpert ? Alignment.centerRight : Alignment.centerLeft,
          child: bubble,
        );
      },
    );
  }
}

// New full screen for chat history
class ExpertChatHistoryScreen extends StatelessWidget {
  final String callId;
  const ExpertChatHistoryScreen({required this.callId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ChatHistoryWidget(callId: callId),
    );
  }
}
