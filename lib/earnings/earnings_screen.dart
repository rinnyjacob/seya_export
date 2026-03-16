import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  static const int itemsPerPage = 5;
  int currentPage = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expertId = FirebaseAuth.instance.currentUser!.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('call_requests')
            .where('expertId', isEqualTo: expertId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Sort in app instead of Firestore (to avoid index requirement)
          final allDocs = snap.data!.docs.toList();
          allDocs.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); // Descending (recent first)
          });

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          double total = 0;
          double todayTotal = 0;
          double yesterdayTotal = 0;
          int completedCalls = 0;
          List<QueryDocumentSnapshot> todayCalls = [];

          for (var d in allDocs) {
            final amount = (d['totalAmount'] ?? 0).toDouble();
            total += amount;

            if (d['status'] == 'completed' || d['status'] == 'ended') {
              completedCalls++;
            }

            final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null) {
              final callDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

              if (callDate.isAtSameMomentAs(today)) {
                todayTotal += amount;
                todayCalls.add(d);
              } else if (callDate.isAtSameMomentAs(yesterday)) {
                yesterdayTotal += amount;
              }
            }
          }

          return CustomScrollView(
            slivers: [
              // Modern header
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF1E293B),
                                const Color(0xFF0F172A),
                              ]
                            : [
                                primaryColor.withValues(alpha: 0.9),
                                primaryColor.withValues(alpha: 0.6),
                              ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Earnings',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Stats section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ModernStatCard(
                              label: 'Today\'s Earning',
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
                              color: primaryColor.withValues(alpha: 0.7),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Today's earnings section
              if (todayCalls.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Earnings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.onlineGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '₹${todayTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.onlineGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = todayCalls[index];
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
                        isToday: true,
                        callId: callId,
                      );
                    },
                    childCount: todayCalls.length,
                  ),
                ),
              ]
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No earnings for today yet.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // All earnings section with pagination
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Earnings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Page ${(currentPage + 1)}',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Paginated list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final startIndex = currentPage * itemsPerPage;
                    final actualIndex = startIndex + index;

                    if (actualIndex >= allDocs.length) {
                      return const SizedBox.shrink();
                    }

                    final doc = allDocs[actualIndex];
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
                      isToday: false,
                      callId: callId,
                    );
                  },
                  childCount: itemsPerPage,
                ),
              ),

              // Pagination controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _PaginationControls(
                    currentPage: currentPage,
                    totalItems: allDocs.length,
                    itemsPerPage: itemsPerPage,
                    onPreviousPage: () {
                      if (currentPage > 0) {
                        setState(() => currentPage--);
                        _scrollController.animateTo(0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      }
                    },
                    onNextPage: () {
                      final totalPages = (allDocs.length / itemsPerPage).ceil();
                      if (currentPage < totalPages - 1) {
                        setState(() => currentPage++);
                        _scrollController.animateTo(0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      }
                    },
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
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
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.2),
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
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, duration: 600.ms);
  }
}

class _EarningTileWithReview extends StatelessWidget {
  final double amount;
  final String status;
  final DateTime date;
  final String userName;
  final String type;
  final Color primaryColor;
  final bool isToday;
  final String callId;

  const _EarningTileWithReview({
    required this.amount,
    required this.status,
    required this.date,
    required this.userName,
    required this.type,
    required this.primaryColor,
    required this.isToday,
    required this.callId,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateStr = '${date.day}/${date.month}/${date.year}';
    IconData typeIcon;
    switch (type) {
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
      future: FirebaseFirestore.instance
          .collection('expert_reviews')
          .where('callId', isEqualTo: callId)
          .limit(1)
          .get(),
      builder: (context, reviewSnap) {
        String review = '';
        double? rating;
        if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
          final reviewData = reviewSnap.data!.docs.first.data() as Map<String, dynamic>;
          review = reviewData['feedback'] ?? '';
          rating = (reviewData['rating'] is num) ? (reviewData['rating'] as num).toDouble() : null;
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFc89c6e).withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(typeIcon, color: const Color(0xFFc89c6e), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        color: const Color(0xFF1c0c1f),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: const Color(0xFFc89c6e),
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
                    isToday ? timeStr : dateStr,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    status == 'ended' ? 'COMPLETED' : status.toUpperCase(),
                    style: TextStyle(
                      color: status == 'completed' || status == 'ended'
                          ? Colors.green
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if ((status == 'completed' || status == 'ended')) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(
                      i < (rating ?? 0).round()
                          ? Icons.star
                          : Icons.star_border,
                      color: const Color(0xFFc89c6e),
                      size: 18,
                    )),
                    const SizedBox(width: 8),
                    Text(
                      rating != null ? rating.toStringAsFixed(1) : 'No rating',
                      style: TextStyle(
                        color: const Color(0xFFc89c6e),
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
                        color: const Color(0xFF1c0c1f),
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
            ],
          ),
        );
      },
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final bool isDark;
  final Color primaryColor;

  const _PaginationControls({
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: currentPage > 0 ? onPreviousPage : null,
          child: Text(
            'Previous',
            style: TextStyle(
              color: currentPage > 0 ? primaryColor : primaryColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          'Page ${currentPage + 1} of $totalPages',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: currentPage < totalPages - 1 ? onNextPage : null,
          child: Text(
            'Next',
            style: TextStyle(
              color: currentPage < totalPages - 1 ? primaryColor : primaryColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
