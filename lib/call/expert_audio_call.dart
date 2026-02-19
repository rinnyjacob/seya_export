// import 'package:flutter/material.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../config/agora_config.dart';
//
// class ExpertAudioCall extends StatefulWidget {
//   final String channel;
//   final String token;
//
//   const ExpertAudioCall({
//     super.key,
//     required this.channel,
//     required this.token,
//   });
//
//   @override
//   State<ExpertAudioCall> createState() => _ExpertAudioCallState();
// }
//
// class _ExpertAudioCallState extends State<ExpertAudioCall> {
//   late RtcEngine _engine;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAgora();
//   }
//
//   Future<void> _initAgora() async {
//     _engine = createAgoraRtcEngine();
//
//     await _engine.initialize(
//       const RtcEngineContext(
//         appId: "cdfbd7f0f20a458cbf31445e91172951",
//       ),
//     );
//
//     await _engine.enableAudio();
//
//     await _engine.joinChannel(
//       token: widget.token,
//       channelId: widget.channel,
//       uid: 0,
//       options: const ChannelMediaOptions(
//         // clientRoleType: ClientRoleType.clientRoleBroadcaster,
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _engine.leaveChannel();
//     _engine.release();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             Icon(Icons.call, color: Colors.white, size: 80),
//             SizedBox(height: 20),
//             Text("Connected",
//                 style: TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class ExpertAudioCall extends StatefulWidget {
  final String channel;
  final String token;

  const ExpertAudioCall({
    super.key,
    required this.channel,
    required this.token,
  });

  @override
  State<ExpertAudioCall> createState() => _ExpertAudioCallState();
}

class _ExpertAudioCallState extends State<ExpertAudioCall> {
  RtcEngine? _engine;

  bool _joined = false;
  bool _muted = false;
  bool _speakerOn = true;

  Timer? _timer;
  int _seconds = 0;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  // ─────────────────────────────────────────────
  // AGORA INIT (SAFE)
  // ─────────────────────────────────────────────
  Future<void> _initAgora() async {
    await Permission.microphone.request();

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(
      const RtcEngineContext(
        appId: "cdfbd7f0f20a458cbf31445e91172951",
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          setState(() => _joined = true);
          _startTimer();
        },
        onUserOffline: (_, __, ___) {
          _endCall();
        },
      ),
    );

    await _engine!.enableAudio();
    await _engine!.setEnableSpeakerphone(true);

    await _engine!.joinChannel(
      token: widget.token,
      channelId: widget.channel,
      uid: 0, // 🔥 EXPERT UID
      options: const ChannelMediaOptions(
        // clientRoleType: ClientRoleType.clientRoleBroadcaster,
        // publishMicrophoneTrack: true,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TIMER
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // CONTROLS
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // END CALL
  // ─────────────────────────────────────────────
  Future<void> _endCall() async {
    _timer?.cancel();
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine?.release();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // CALL STATUS
            const Icon(Icons.person, color: Colors.white70, size: 80),
            const SizedBox(height: 16),
            Text(
              _joined ? "Connected" : "Connecting…",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),

            const Spacer(),

            // CONTROLS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _circleButton(
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  color: _muted ? Colors.red : Colors.white,
                  onTap: _toggleMute,
                ),
                _circleButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  size: 70,
                  onTap: _endCall,
                ),
                _circleButton(
                  icon:
                  _speakerOn ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  onTap: _toggleSpeaker,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
