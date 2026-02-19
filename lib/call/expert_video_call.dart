import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class ExpertVideoCall extends StatefulWidget {
  final String channel;
  final String token;
  final String callId;

  const ExpertVideoCall({
    super.key,
    required this.channel,
    required this.token,
    required this.callId,
  });

  @override
  State<ExpertVideoCall> createState() => _ExpertVideoCallState();
}

class _ExpertVideoCallState extends State<ExpertVideoCall> {
  RtcEngine? _engine;
  bool _engineReady = false;

  int? remoteUid;

  Timer? _timer;
  int _seconds = 0;
  bool muted = false;

  bool _callEnded = false; // 🔥 CRITICAL GUARD
  StreamSubscription<DocumentSnapshot>? _callSub;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenCallEnd();
  }

  // ---------------- FIREBASE LISTENER ----------------

  void _listenCallEnd() {
    _callSub = FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      if (doc['status'] == 'ended' && !_callEnded) {
        _callEnded = true;
        _closeAndExit();
      }
    });
  }

  // ---------------- AGORA ----------------

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    final engine = createAgoraRtcEngine();

    await engine.initialize(
      const RtcEngineContext(
        appId: "cdfbd7f0f20a458cbf31445e91172951",
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (_, uid, __) {
          // ✅ USER JOINED → START TIMER
          if (remoteUid == null) {
            setState(() => remoteUid = uid);
            _startTimer();
          }
        },
        onUserOffline: (_, __, ___) {
          _endCall(); // user disconnected
        },
      ),
    );

    await engine.enableVideo();
    await engine.enableAudio();
    await engine.startPreview();

    await engine.joinChannel(
      token: widget.token,
      channelId: widget.channel,
      uid: 0, // EXPERT
      options: const ChannelMediaOptions(
        // clientRoleType: ClientRoleType.clientRoleBroadcaster,
        // publishCameraTrack: true,
        // publishMicrophoneTrack: true,
      ),
    );

    _engine = engine;
    _engineReady = true;

    if (mounted) setState(() {});
  }

  // ---------------- TIMER ----------------

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get formattedTime {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ---------------- END CALL ----------------

  Future<void> _endCall() async {
    if (_callEnded) return;
    _callEnded = true;

    _timer?.cancel();

    // 🔥 EXPERT ENDS → UPDATE FIREBASE
    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'durationSeconds': _seconds,
      'endedBy': 'expert',
    });

    _closeAndExit();
  }

  void _closeAndExit() async {
    _timer?.cancel();
    await _engine?.leaveChannel();
    await _engine?.release();

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callSub?.cancel();
    _engine?.release();
    super.dispose();
  }

  // ---------------- UI ----------------

  Widget _remoteView() {
    if (!_engineReady || remoteUid == null) {
      return const Center(
        child: Text(
          "Waiting for user…",
          style: TextStyle(color: Colors.white70),
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
    if (!_engineReady) return const SizedBox();

    return Positioned(
      top: 40,
      right: 16,
      child: SizedBox(
        width: 110,
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _remoteView()),
          _localPreview(),

          // ⏱ TIMER
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                formattedTime,
                style:
                const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // CONTROLS
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    muted = !muted;
                    _engine?.muteLocalAudioStream(muted);
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.call_end,
                    color: Colors.red,
                    size: 36,
                  ),
                  onPressed: _endCall,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.cameraswitch,
                    color: Colors.white,
                  ),
                  onPressed: () => _engine?.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
