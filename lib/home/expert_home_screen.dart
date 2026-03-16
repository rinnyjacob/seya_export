import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../call/incoming_call_screen.dart';
import '../chat/expert_chat_screen.dart';
import '../earnings/earnings_screen.dart';
import '../profile/expert_profile_screen.dart';
import '../screens/all_experts_screen.dart';
import '../screens/terms_page.dart';
import '../screens/privacy_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_provider.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
import '../widgets/user_birth_details_widget.dart';

class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  final String expertId = FirebaseAuth.instance.currentUser!.uid;
  bool _dialogOpen = false;

  /// 🔴 LOGOUT WITH CONFIRMATION
  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          'Logout?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to logout? You will no longer receive incoming requests.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔴 LOGOUT
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('experts')
          .doc(expertId)
          .update({
        'is_online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Clear local terms acceptance on logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('termsAccepted_' + expertId);

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      // Navigator.pushNamedAndRemoveUntil(
      //   context,
      //   '/login',
      //   (_) => false,
      // );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed")),
      );
    }
  }

  /// 🟢 ACCEPT CHAT
  Future<void> _acceptChat(
    BuildContext context,
    String callId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(callId)
        .update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pop(context); // close dialog
    _dialogOpen = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpertChatScreen(
          callId: callId,
          userName: data['userName'] ?? 'User',
          userId: data['userId'] ?? '',
        ),
      ),
    );
  }

  /// ❌ REJECT CHAT
  Future<void> _rejectChat(String callId) async {
    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(callId)
        .update({
      'status': 'rejected',
      'endedBy': 'expert',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 📋 SHOW CHAT REQUEST DETAILS
  void _showChatRequestDetails(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Request Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User info card
              ModernCard(
                showGradient: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(context, 'User', data['userName'] ?? 'Anonymous'),
                    const SizedBox(height: 12),
                    _detailRow(context, 'Request Type', '💬 Chat'),
                    const SizedBox(height: 12),
                    _detailRow(context, 'Rate', '₹${data['ratePerMinute'] ?? 0}/min'),
                  ],
                ),
              ),

              // Birth Details Section
              if (data['birthDetails'] != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                UserBirthDetailsWidget(
                  userId: data['userId'] ?? '',
                  birthDetailsData: data['birthDetails'] as Map<String, dynamic>?,
                  isCompact: false,
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  label: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 💬 SHOW MODERN CHAT REQUEST DIALOG
  void _showChatDialog(
    BuildContext context,
    String callId,
    Map<String, dynamic> data,
  ) {
    if (_dialogOpen) return;
    _dialogOpen = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightAccent.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.lightAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Chat Request',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ModernCard(
                showGradient: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['userName'] ?? 'Anonymous',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Birth Details Section
                    if (data['birthDetails'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: UserBirthDetailsWidget(
                          userId: data['userId'] ?? '',
                          birthDetailsData: data['birthDetails'] as Map<String, dynamic>?,
                          isCompact: true,
                          textColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: AppColors.lightAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${data['ratePerMinute'] ?? 0}/min',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      label: 'Reject',
                      isOutlined: true,
                      onPressed: () async {
                        await _rejectChat(callId);
                        if (mounted) Navigator.pop(context);
                        _dialogOpen = false;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernButton(
                      label: 'Accept',
                      onPressed: () => _acceptChat(context, callId, data),
                    ),
                  ),
                ],
              ),
              // Details button
              if (data['birthDetails'] != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _showChatRequestDetails(context, data),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('View Full Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 BUILD ANIMATED MODERN DRAWER
  Widget _buildAnimatedDrawer(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expertId = FirebaseAuth.instance.currentUser!.uid;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header Section with gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expert avatar and name (would fetch from Firestore)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('experts')
                      .doc(expertId)
                      .get(),
                  builder: (context, snapshot) {
                    final expertData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final name = expertData['name'] ?? 'Expert';
                    final avatar = expertData['profile_photo'] ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                            border: Border.all(color: Colors.white, width: 2),
                            image: avatar.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(avatar),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: avatar.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome, $name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expert Dashboard',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // Earnings
                _buildDrawerMenuItem(
                  context,
                  icon: Icons.monetization_on_outlined,
                  label: 'Earnings',
                  subtitle: 'Track your earnings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EarningsScreen()),
                    );
                  },
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),

                // Profile
                _buildDrawerMenuItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  subtitle: 'Edit your profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpertEditProfileScreen()),
                    );
                  },
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),

                // Terms & Conditions
                _buildDrawerMenuItem(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  subtitle: 'View terms',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TermsPage()),
                    );
                  },
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),

                // Privacy Policy
                _buildDrawerMenuItem(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  subtitle: 'View privacy policy',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PrivacyPage()),
                    );
                  },
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),

                // All Experts
                // _buildDrawerMenuItem(
                //   context,
                //   icon: Icons.people_outline,
                //   label: 'All Experts',
                //   subtitle: 'Browse other experts',
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (_) => const AllExpertsScreen()),
                //     );
                //   },
                //   isDark: isDark,
                //   primaryColor: primaryColor,
                // ),



                const Divider(indent: 16, endIndent: 16, height: 20),

                // Theme Toggle
                _buildThemeToggleItem(context, isDark, primaryColor),

                const Divider(indent: 16, endIndent: 16, height: 20),

                // Logout
                _buildDrawerMenuItem(
                  context,
                  icon: Icons.logout,
                  label: 'Logout',
                  subtitle: 'Sign out',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                  isDark: isDark,
                  primaryColor: Colors.red,
                  isDestructive: true,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              children: [
                // Row(
                //   children: [
                //     Container(
                //       width: 8,
                //       height: 8,
                //       decoration: const BoxDecoration(
                //         shape: BoxShape.circle,
                //         color: Colors.green,
                //       ),
                //     ),
                //     const SizedBox(width: 8),
                //     Text(
                //       'Status: Online',
                //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 BUILD DRAWER MENU ITEM WITH ANIMATION
  Widget _buildDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          fontSize: 11,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: primaryColor.withValues(alpha: 0.1),
    );
  }

  /// 🌙 BUILD THEME TOGGLE ITEM
  Widget _buildThemeToggleItem(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            'Theme',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 11,
            ),
          ),
          trailing: Switch.adaptive(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.setDarkMode(value);
            },
            activeColor: primaryColor,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          hoverColor: primaryColor.withValues(alpha: 0.1),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      drawer: _buildAnimatedDrawer(context,primaryColor),
      appBar: AppBar(
        elevation: 0,
        title: Column(
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('experts')
            .doc(expertId)
            .snapshots(),
        builder: (context, expertSnap) {
          if (!expertSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expertData =
              expertSnap.data!.data() as Map<String, dynamic>;
          final isOnline = expertData['is_online'] == true;
          final expertName = expertData['name'] ?? 'Expert';
          // final isOnline = expertData['is_online'] == true;
          // final expertName = expertData['name'] ?? 'Expert';

          final allowAudio = expertData['allow_audio'] == true;
          final allowVideo = expertData['allow_video'] == true;
          final allowChat = expertData['allow_chat'] == true;

          final canAudio = expertData['can_audio'] == true;
          final canVideo = expertData['can_video'] == true;
          final canChat = expertData['can_chat'] == true;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('call_requests')
                .where('expertId', isEqualTo: expertId)
                .where('status', whereIn: ['created', 'ringing'])
                .limit(1)
                .snapshots(),
            builder: (context, callSnap) {
              final hasIncomingRequest = callSnap.hasData && callSnap.data!.docs.isNotEmpty;

              // If there's an incoming call/video request, show it fullscreen
              if (hasIncomingRequest) {
                final doc = callSnap.data!.docs.first;
                final data = doc.data() as Map<String, dynamic>;

                log('kbfgdjksghfsw4785 ${data['type']}');

                if (data['type'] == 'audio' || data['type'] == 'video') {
                  return IncomingCallScreen(
                    callId: doc.id,
                    data: data,
                    // Pass birthDetails to IncomingCallScreen if not already handled
                    // If IncomingCallScreen does not show birth details, update it to do so
                  );
                }

                // For chat requests, show dialog
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showChatDialog(context, doc.id, data);
                });
              }

              // Normal dashboard view
              return CustomScrollView(
                slivers: [
                  // Status card - only show when no incoming call
                  if (!hasIncomingRequest || (hasIncomingRequest && callSnap.data!.docs.first.data() is Map && (callSnap.data!.docs.first.data() as Map)['type'] == 'chat'))
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: .25),
                              blurRadius: 12,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// HEADER
                            Row(
                              children: [

                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline ? Colors.green : Colors.red,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    "Welcome, $expertName",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                Switch(
                                  value: isOnline,
                                  onChanged: (value) async {
                                    await FirebaseFirestore.instance
                                        .collection('experts')
                                        .doc(expertId)
                                        .update({
                                      'is_online': value,
                                      'lastSeen': FieldValue.serverTimestamp(),
                                    });
                                  },
                                  activeColor: Colors.white,
                                )
                              ],
                            ),

                            const SizedBox(height: 24),

                            /// MODES
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                _modeChip(
                                  label: "Audio",
                                  icon: Icons.headset,
                                  enabled: expertData['can_audio'] == true,
                                  allowed: expertData['allow_audio'] == true,
                                  field: "can_audio",
                                  primaryColor:primaryColor,
                                ),

                                _modeChip(
                                  label: "Video",
                                  icon: Icons.videocam,
                                  enabled: expertData['can_video'] == true,
                                  allowed: expertData['allow_video'] == true,
                                  field: "can_video",
                                  primaryColor:primaryColor,

                                ),

                                _modeChip(
                                  label: "Chat",
                                  icon: Icons.chat,
                                  enabled: expertData['can_chat'] == true,
                                  allowed: expertData['allow_chat'] == true,
                                  field: "can_chat",
                                  primaryColor:primaryColor,

                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    // SliverToBoxAdapter(
                    //   child: Container(
                    //     margin: const EdgeInsets.all(16),
                    //     padding: const EdgeInsets.all(20),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(16),
                    //       gradient: LinearGradient(
                    //         colors: [
                    //           primaryColor,
                    //           primaryColor.withValues(alpha: 0.7),
                    //         ],
                    //       ),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: primaryColor.withValues(alpha: 0.3),
                    //           blurRadius: 12,
                    //           spreadRadius: 2,
                    //         ),
                    //       ],
                    //     ),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Expanded(
                    //               child: Column(
                    //                 crossAxisAlignment: CrossAxisAlignment.start,
                    //                 children: [
                    //                   Text(
                    //                     'Welcome, $expertName',
                    //                     style: Theme.of(context)
                    //                         .textTheme
                    //                         .titleLarge
                    //                         ?.copyWith(
                    //                           color: Colors.white,
                    //                           fontWeight: FontWeight.w700,
                    //                         ),
                    //                   ),
                    //                   const SizedBox(height: 8),
                    //                   Text(
                    //                     isOnline
                    //                         ? '🟢 Online & Available'
                    //                         : '🔴 Offline',
                    //                     style: Theme.of(context)
                    //                         .textTheme
                    //                         .bodyMedium
                    //                         ?.copyWith(
                    //                           color: Colors.white70,
                    //                         ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             // Online/Offline Toggle Switch
                    //             Switch(
                    //               value: isOnline,
                    //               onChanged: (value) async {
                    //                 await FirebaseFirestore.instance
                    //                     .collection('experts')
                    //                     .doc(expertId)
                    //                     .update({
                    //                   'is_online': value,
                    //                   'lastSeen': FieldValue.serverTimestamp(),
                    //                 });
                    //               },
                    //               activeColor: Colors.white,
                    //               activeTrackColor: Colors.green.withValues(alpha: 0.8),
                    //               inactiveThumbColor: Colors.white,
                    //               inactiveTrackColor: Colors.red.withValues(alpha: 0.5),
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                  // Main content
                  if (!isOnline)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.phone_disabled,
                                size: 40,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'You are Offline',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Go online to accept requests',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (!hasIncomingRequest)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.hourglass_bottom,
                                size: 50,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Waiting for Requests',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ll be notified when a client requests your service',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverFillRemaining(
                      child: const Center(
                        child: Text("Incoming chat request…"),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool enabled,
    required bool allowed,
    required String field, required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: allowed
          ? () async {
        await FirebaseFirestore.instance
            .collection('experts')
            .doc(expertId)
            .update({field: !enabled});
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: enabled ? Colors.white : Colors.white.withValues(alpha: .15),
        ),
        child: Column(
          children: [

            Icon(
              icon,
              color: enabled ? primaryColor : Colors.white,
            ),

            const SizedBox(height: 6),

            Text(
              label,
              style: TextStyle(
                color: enabled ? primaryColor : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen to display all reviews for the expert
class _AllReviewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final expertId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expert_reviews')
            .where('expertId', isEqualTo: expertId)
            // .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No reviews found.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (data['userPhoto'] ?? '').isNotEmpty
                      ? NetworkImage(data['userPhoto'])
                      : null,
                  child: (data['userPhoto'] ?? '').isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(data['userName'] ?? 'User'),
                subtitle: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('${data['rating'] ?? '-'}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/reviewDetails',
                    arguments: data,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

