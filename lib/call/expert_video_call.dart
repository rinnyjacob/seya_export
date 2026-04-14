import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/agora_config.dart';
import '../theme/app_colors.dart';
import '../widgets/user_birth_details_widget.dart';

class ExpertVideoCall extends StatefulWidget {
  final String channel;
  final String token;
  final String callId;
  final String userId;

  const ExpertVideoCall({
    super.key,
    required this.channel,
    required this.token,
    required this.callId,
    required this.userId,
  });

  @override
  State<ExpertVideoCall> createState() => _ExpertVideoCallState();
}

class _ExpertVideoCallState extends State<ExpertVideoCall>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  RtcEngine? _engine;
  bool _engineReady = false;
  bool _initError = false;
  String _initErrorMsg = '';

  int? remoteUid;

  Timer? _timer;
  int _seconds = 0;
  bool _muted = false;
  bool _cameraOn = true;

  bool _callEnded = false;
  bool _showControls = true;
  late AnimationController _controlsController;

  StreamSubscription<DocumentSnapshot>? _callSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controlsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initAgora();
    _listenCallEnd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Disable camera when backgrounded, keep audio
      _engine?.enableLocalVideo(false);
    } else if (state == AppLifecycleState.resumed) {
      // Restore camera state when foregrounded
      if (_cameraOn) _engine?.enableLocalVideo(true);
    }
  }

  void _listenCallEnd() {
    _callSub = FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      if (doc.data()?['status'] == 'ended' && !_callEnded) {
        _callEnded = true;
        _closeAndExit();
      }
    });
  }

  Future<void> _initAgora() async {
    // Check permissions first
    final statuses = await [Permission.microphone, Permission.camera].request();
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final camGranted = statuses[Permission.camera]?.isGranted ?? false;

    if (!micGranted || !camGranted) {
      if (mounted) {
        setState(() {
          _initError = true;
          _initErrorMsg = !micGranted
              ? 'Microphone permission denied.'
              : 'Camera permission denied.';
        });
      }
      return;
    }

    try {
      final engine = createAgoraRtcEngine();

      await engine.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (_, uid, __) {
            if (remoteUid == null) {
              if (mounted) setState(() => remoteUid = uid);
              _startTimer();
            }
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

      await engine.enableVideo();
      await engine.enableAudio();
      await engine.startPreview();

      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channel,
        uid: 0,
        options: const ChannelMediaOptions(),
      );

      if (mounted) {
        setState(() {
          _engine = engine;
          _engineReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = true;
          _initErrorMsg = 'Failed to start video call: ${e.toString()}';
        });
      }
    }
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


  Future<void> _endCall() async {
    if (_callEnded) return;
    _callEnded = true;

    _timer?.cancel();
    _callSub?.cancel();
    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'durationSeconds': _seconds,
      'endedBy': 'expert',
    });

    await _engine?.leaveChannel();
    await _engine?.release();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  Future<void> _closeAndExit() async {
    _timer?.cancel();
    _callSub?.cancel();
    await _engine?.leaveChannel();
    await _engine?.release();
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
    _controlsController.dispose();
    _engine?.release();
    super.dispose();
  }

  Widget _remoteView() {
    if (!_engineReady || remoteUid == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white30, size: 60),
              const SizedBox(height: 16),
              Text(
                "Waiting for user…",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: widget.channel),
      ),
    );
  }

  Widget _localPreview() {
    if (!_engineReady || !_cameraOn) return const SizedBox();

    return Positioned(
      top: 40,
      right: 16,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine!,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    if (_initError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(_initErrorMsg, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Please grant permissions in Settings and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
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
      child: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) {
            _controlsController.forward();
          } else {
            _controlsController.reverse();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Remote video
              Positioned.fill(child: _remoteView()),

              // Local preview
              _localPreview(),

              // Top controls - Timer & status
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timer and status row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Timer
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                formattedTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),

                            // Status indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreen.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Live',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Birth details badge - fetch from call_requests
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FutureBuilder<DocumentSnapshot>(
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
                                    textColor: Colors.white,
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom controls
              // if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(parent: _controlsController, curve: Curves.easeOut),
                        ),
                        child: Column(
                          children: [
                            // Full Birth Details Card - Tappable
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
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
                                  //           color: Colors.white.withValues(alpha: 0.2),
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
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Mute button
                                _buildVideoControlButton(
                                  icon: _muted ? Icons.mic_off : Icons.mic,
                                  label: _muted ? 'Unmute' : 'Mute',
                                  onTap: _toggleMute,
                                  color: _muted ? Colors.red : primaryColor,
                                  isActive: !_muted,
                                ),

                                // End call (larger)
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

                                // Camera button
                                Tooltip(
                                  message: _cameraOn ? 'Turn camera off' : 'Turn camera on',
                                  child: _buildVideoControlButton(
                                    icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                                    label: _cameraOn ? 'Camera' : 'Off',
                                    onTap: () async {
                                      if (_engine != null) {
                                        try {
                                          _cameraOn = !_cameraOn;
                                          await _engine!.enableLocalVideo(_cameraOn);
                                          setState(() {});
                                        } catch (e) {
                                          // Optionally show error to user
                                        }
                                      }
                                    },
                                    color: _cameraOn ? primaryColor : Colors.red,
                                    isActive: _cameraOn,
                                  ),
                                ),
                                // Swap camera button
                                Tooltip(
                                  message: 'Switch camera',
                                  child: _buildVideoControlButton(
                                    icon: Icons.cameraswitch,
                                    label: 'Swap',
                                    onTap: () async {
                                      if (_engine != null) {
                                        try {
                                          await _engine!.switchCamera();
                                        } catch (e) {
                                          // Optionally show error to user
                                        }
                                      }
                                    },
                                    color: primaryColor,
                                    isActive: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isActive,
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
              color: Colors.black.withValues(alpha: 0.6),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
