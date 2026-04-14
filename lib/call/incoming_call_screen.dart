// import 'dart:developer';
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'expert_audio_call.dart';
// import 'expert_video_call.dart';
//
// class IncomingCallScreen extends StatefulWidget {
//   final String callId;
//   final Map<String, dynamic> data;
//
//   const IncomingCallScreen({
//     super.key,
//     required this.callId,
//     required this.data,
//   });
//
//   @override
//   State<IncomingCallScreen> createState() => _IncomingCallScreenState();
// }
//
// class _IncomingCallScreenState extends State<IncomingCallScreen> {
//   bool _navigated = false;
//
//   @override
//   void initState() {
//     super.initState();
//     log("📞 IncomingCallScreen INIT | callId=${widget.callId}");
//   }
//
//   @override
//   void dispose() {
//     log("❌ IncomingCallScreen DISPOSED | callId=${widget.callId}");
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isVideo = widget.data['type'] == 'video';
//
//     log("🧱 BUILD IncomingCallScreen | mounted=$mounted");
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               isVideo ? "Video Call" : "Audio Call",
//               style: const TextStyle(color: Colors.white70),
//             ),
//             const SizedBox(height: 40),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 /// ❌ REJECT
//                 FloatingActionButton(
//                   backgroundColor: Colors.red,
//                   child: const Icon(Icons.call_end),
//                   onPressed: () async {
//                     log("❌ REJECT pressed");
//
//                     await FirebaseFirestore.instance
//                         .collection('call_requests')
//                         .doc(widget.callId)
//                         .update({'status': 'rejected'});
//
//                     log("❌ Call rejected in Firestore");
//                   },
//                 ),
//
//                 /// ✅ ACCEPT
//                 FloatingActionButton(
//                   backgroundColor: Colors.green,
//                   child: const Icon(Icons.call),
//                   onPressed: _navigated
//                       ? null
//                       : () async {
//                     log("✅ ACCEPT pressed");
//
//                     _navigated = true;
//
//                     log("⏳ Updating Firestore status=accepted...");
//                     await FirebaseFirestore.instance
//                         .collection('call_requests')
//                         .doc(widget.callId)
//                         .update({'status': 'accepted'});
//
//                     log("✅ Firestore update DONE");
//
//                     if (!mounted) {
//                       log("⚠️ Widget NOT mounted → abort navigation");
//                       return;
//                     }
//
//                     log("🚀 Navigating to call screen");
//
//                     Navigator.of(context, rootNavigator: true)
//                         .pushReplacement(
//                       MaterialPageRoute(
//                         builder: (_) => isVideo
//                             ? ExpertVideoCall(
//                           channel: widget.data['channel'],
//                           token: widget.data['token'], callId: widget.data['callId'],
//                         )
//                             : ExpertAudioCall(
//                           channel: widget.data['channel'],
//                           token: widget.data['token'],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_birth_details_widget.dart';
import 'expert_audio_call.dart';
import 'expert_video_call.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final Map<String, dynamic> data;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.data,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;
  bool _rejecting = false;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  StreamSubscription<DocumentSnapshot>? _callSub;
  Timer? _autoRejectTimer;

  static const int _autoRejectSeconds = 60;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _callSub = FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .snapshots()
        .listen(
      (doc) {
        if (!doc.exists) return;
        final status = doc.data()?['status'];
        // Auto-dismiss if call was cancelled by user or already ended
        if (status == 'accepted' && mounted && !_navigated) {
          _navigated = true;
          _autoRejectTimer?.cancel();
          _goToCall();
        } else if ((status == 'ended' || status == 'cancelled') && mounted && !_navigated) {
          _navigated = true;
          _autoRejectTimer?.cancel();
          Navigator.of(context).pop();
        }
      },
      onError: (e) => log('IncomingCallScreen stream error: $e'),
    );

    // Auto-reject after 60 seconds if no response
    _autoRejectTimer = Timer(const Duration(seconds: _autoRejectSeconds), () {
      if (mounted && !_navigated) {
        _rejectCall();
      }
    });

    log("📞 IncomingCallScreen INIT | callId=${widget.callId}");
  }

  Future<void> _acceptCall() async {
    if (_navigated) return;
    _navigated = true;
    _autoRejectTimer?.cancel();
    log("✅ ACCEPT pressed → navigating immediately");
    _goToCall();
    // Update Firestore in background
    FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    }).catchError((e) => log('Accept Firestore error: $e'));
  }

  Future<void> _rejectCall() async {
    if (_navigated || _rejecting) return;
    setState(() => _rejecting = true);
    _navigated = true;
    _autoRejectTimer?.cancel();
    final nav = Navigator.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('call_requests')
          .doc(widget.callId)
          .update({
        'status': 'rejected',
        'endedAt': FieldValue.serverTimestamp(),
        'endedBy': 'expert',
      });
    } catch (_) {}
    log("❌ Call rejected");
    if (mounted) nav.pop();
  }

  void _goToCall() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.data['type'] == 'video'
            ? ExpertVideoCall(
                channel: widget.data['channel'],
                token: widget.data['token'],
                callId: widget.callId,
                userId: widget.data['userId'] ?? '',
              )
            : ExpertAudioCall(
                channel: widget.data['channel'],
                token: widget.data['token'],
                callId: widget.callId,
                userId: widget.data['userId'] ?? '',
              ),
      ),
    );
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _autoRejectTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.data['type'] == 'video';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final userName = widget.data['userName'] ?? 'User';
    final callType = isVideo ? 'Video Call' : 'Audio Call';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    primaryColor.withValues(alpha: 0.9),
                    primaryColor.withValues(alpha: 0.6),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Status Header
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
                ),
                child: Column(
                  children: [
                    Text(
                      'Incoming Call',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      callType,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Caller Avatar & Info
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
                ),
                child: Column(
                  children: [
                    // Pulsing Avatar
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.1)
                          .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDark
                                ? AppColors.darkGradient
                                : AppColors.lightGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.call,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Caller Name
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Birth Details Badge
                    if (widget.data['birthDetails'] != null)
                      UserBirthDetailsWidget(
                        userId: widget.data['userId'] ?? '',
                        birthDetailsData: widget.data['birthDetails'] as Map<String, dynamic>?,
                        isCompact: true,
                        textColor: Colors.white,
                      ),
                    const SizedBox(height: 12),

                    // Call Info Card
                    GlassCard(
                      borderRadius: 20,
                      blur: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVideo ? Icons.videocam_outlined : Icons.mic_outlined,
                            color: primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isVideo ? 'Video Call Request' : 'Audio Call Request',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ❌ Reject Button
                      _buildActionButton(
                        icon: Icons.call_end,
                        label: 'Reject',
                        color: Colors.red,
                        onPressed: _rejecting ? () {} : _rejectCall,
                      ),

                      // ✅ Accept Button (Larger)
                      GestureDetector(
                        onTap: _navigated ? null : _acceptCall,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.onlineGreen.withValues(alpha: 0.9),
                                AppColors.onlineGreen.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.onlineGreen.withValues(alpha: 0.5),
                                blurRadius: 25,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // ℹ️ Info Button
                      _buildActionButton(
                        icon: Icons.info_outline,
                        label: 'Details',
                        color: primaryColor,
                        onPressed: () {
                          _showCallDetails(context, isVideo);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCallDetails(BuildContext context, bool isVideo) {
    final userName = widget.data['userName'] ?? 'User';
    final ratePerMinute = widget.data['ratePerMinute'] ?? '0';
    final userId = widget.data['userId'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassCard(
        borderRadius: 28,
        blur: 15,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Call Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              _detailRow('Caller', userName),
              const SizedBox(height: 16),
              _detailRow('Call Type', isVideo ? '📹 Video' : '📞 Audio'),
              const SizedBox(height: 16),
              _detailRow('Rate', '₹$ratePerMinute/min'),
              const SizedBox(height: 24),
              // Birth Details Section
              if (widget.data['birthDetails'] != null) ...[
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                UserBirthDetailsWidget(
                  userId: userId,
                  birthDetailsData: widget.data['birthDetails'] as Map<String, dynamic>?,
                  isCompact: false,
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
