import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/agora_config.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_birth_details_widget.dart';

class ExpertAudioCall extends StatefulWidget {
  final String channel;
  final String token;
  final String callId;
  final String userId;

  const ExpertAudioCall({
    super.key,
    required this.channel,
    required this.token,
    required this.callId,
    required this.userId,
  });

  @override
  State<ExpertAudioCall> createState() => _ExpertAudioCallState();
}

class _ExpertAudioCallState extends State<ExpertAudioCall>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  RtcEngine? _engine;

  bool _joined = false;
  bool _muted = false;
  bool _speakerOn = true;
  bool _initError = false;
  String _initErrorMsg = '';

  Timer? _timer;
  int _seconds = 0;

  bool _callEnded = false;
  StreamSubscription<DocumentSnapshot>? _callSub;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _initAgora();
    _listenCallEnd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When expert minimizes/backgrounds the app, mute mic to avoid accidental audio
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _engine?.muteLocalAudioStream(true);
    } else if (state == AppLifecycleState.resumed) {
      // Restore mute state when app comes back
      _engine?.muteLocalAudioStream(_muted);
    }
  }

  void _listenCallEnd() {
    _callSub = FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || _callEnded) return;

      final status = doc.data()?['status'];
      if (status == 'rejected' || status == 'ended') {
        _endCall();
      }
    });
  }

  Future<void> _initAgora() async {
    // Check microphone permission first
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _endCallDueToError('Microphone permission denied. Cannot start audio call.');
      return;
    }

    try {
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (_, __) {
            if (mounted) setState(() => _joined = true);
            _startTimer();
          },
          onUserOffline: (_, __, ___) {
            _endCall();
          },
          onConnectionStateChanged: (connection, state, reason) {
            if (state == ConnectionStateType.connectionStateFailed && mounted) {
              setState(() {
                _initError = true;
                _initErrorMsg = 'Connection failed. Please check your network.';
              });
            }
          },
        ),
      );

      await _engine!.enableAudio();
      try {
        await _engine!.setEnableSpeakerphone(true);
      } catch (_) {
        // Speakerphone not available on this device — continue silently
      }

      await _engine!.joinChannel(
        token: widget.token,
        channelId: widget.channel,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = true;
          _initErrorMsg = 'Failed to start call: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _endCallDueToError(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Call Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _endCall();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get formattedTime {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _toggleMute() {
    _muted = !_muted;
    _engine?.muteLocalAudioStream(_muted);
    setState(() {});
  }

  void _toggleSpeaker() {
    _speakerOn = !_speakerOn;
    _engine?.setEnableSpeakerphone(_speakerOn);
    setState(() {});
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
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    _callEnded = true;

    _timer?.cancel();
    _callSub?.cancel();
    _pulseController.stop();
    await _engine?.leaveChannel();
    await _engine?.release();

    // Save call duration to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('call_requests')
          .doc(widget.callId)
          .update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'durationSeconds': _seconds,
      });
    } catch (_) {
      // Best-effort save — don't block navigation
    }

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  Future<void> _confirmEndCall() async {
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
      await _endCall();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _callSub?.cancel();
    _pulseController.dispose();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    // Show error screen if init failed
    if (_initError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(_initErrorMsg, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _endCall,
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
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
          await _endCall();
        }
      },
      child: Scaffold(
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
                primaryColor.withValues(alpha: 0.15),
                primaryColor.withValues(alpha: 0.05),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Call',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          // Birth details badge - fetch from call_requests
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
                                    textColor: primaryColor,
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _confirmEndCall(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // const Spacer(),
                  const SizedBox(
                    height: 20,
                  ),

                // Call Status Card
                GlassCard(
                  borderRadius: 32,
                  blur: 15,
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Pulse animation circle
                      ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.2)
                            .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [primaryColor.withValues(alpha: 0.6), primaryColor.withValues(alpha: 0.2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mic_none,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Text
                      Text(
                        _joined ? "Connected" : "Connecting…",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Timer
                      Text(
                        formattedTime,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              letterSpacing: 2,
                            ),
                      ),
                    ],
                  ),
                ),

                // const Spacer(),

                // Full Birth Details Card - Tappable
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: FutureBuilder<DocumentSnapshot>(
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

                      return ElevatedButton(onPressed: (){
                        _showBirthDetailsDialog(birthDetails);
                      }, child: const Text("Birth Details"));
                      // return GestureDetector(
                      //   onTap: () => _showBirthDetailsDialog(birthDetails),
                      //   child: MouseRegion(
                      //     cursor: SystemMouseCursors.click,
                      //     child: Container(
                      //       decoration: BoxDecoration(
                      //         gradient: LinearGradient(
                      //           colors: [
                      //             Colors.blue.withValues(alpha: 0.3),
                      //             Colors.purple.withValues(alpha: 0.2),
                      //           ],
                      //         ),
                      //         borderRadius: BorderRadius.circular(20),
                      //         border: Border.all(
                      //           color: primaryColor.withValues(alpha: 0.2),
                      //           width: 1.5,
                      //         ),
                      //         boxShadow: [
                      //           BoxShadow(
                      //             color: Colors.blue.withValues(alpha: 0.2),
                      //             blurRadius: 16,
                      //             spreadRadius: 2,
                      //           ),
                      //         ],
                      //       ),
                      //       child: Padding(
                      //         padding: const EdgeInsets.all(16),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //           children: [
                      //             Expanded(
                      //               child: UserBirthDetailsWidget(
                      //                 userId: widget.userId,
                      //                 birthDetailsData: birthDetails,
                      //                 isCompact: false,
                      //               ),
                      //             ),
                      //             Container(
                      //               width: 40,
                      //               height: 40,
                      //               decoration: BoxDecoration(
                      //                 shape: BoxShape.circle,
                      //                 gradient: LinearGradient(
                      //                   colors: [
                      //                     Colors.blue.withValues(alpha: 0.5),
                      //                     Colors.purple.withValues(alpha: 0.3),
                      //                   ],
                      //                 ),
                      //               ),
                      //               child: const Icon(
                      //                 Icons.arrow_outward,
                      //                 color: Colors.white,
                      //                 size: 20,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // );
                      // };
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      _buildControlButton(
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        label: _muted ? 'Unmute' : 'Mute',
                        onTap: _toggleMute,
                        color: _muted ? Colors.red : primaryColor,
                        isDark: isDark,
                      ),

                      // End call button (larger)
                      GestureDetector(
                        onTap: _confirmEndCall,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.red.withValues(alpha: 0.8), Colors.red.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),

                      // Speaker button
                      _buildControlButton(
                        icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                        label: _speakerOn ? 'Speaker' : 'Phone',
                        onTap: _toggleSpeaker,
                        color: primaryColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
                        ),
            ),
        ),
      ),
    ));
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.15),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
