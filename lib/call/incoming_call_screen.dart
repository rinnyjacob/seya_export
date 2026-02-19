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
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      if (doc['status'] == 'accepted' && mounted) {
        _goToCall();
      }
    });
    log("📞 IncomingCallScreen INIT | callId=${widget.callId}");
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
        )
            : ExpertAudioCall(
          channel: widget.data['channel'],
          token: widget.data['token'],
          callId: widget.callId,

        ),
      ),
    );
  }

  @override
  void dispose() {
    log("❌ IncomingCallScreen DISPOSED | callId=${widget.callId}");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.data['type'] == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isVideo ? "Incoming Video Call" : "Incoming Audio Call",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// ❌ REJECT
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                  onPressed: () async {
                    log("❌ REJECT pressed");

                    await FirebaseFirestore.instance
                        .collection('call_requests')
                        .doc(widget.callId)
                        .update({
                      'status': 'rejected',
                      'endedAt': FieldValue.serverTimestamp(),
                      'endedBy': 'expert',
                    });

                    log("❌ Call rejected");
                  },
                ),

                /// ✅ ACCEPT
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.call),
                  onPressed: _navigated
                      ? null
                      : () async {
                    log("✅ ACCEPT pressed");

                    // _navigated = true;

                    // 1️⃣ NAVIGATE FIRST (CRITICAL)
                    // Navigator.of(context, rootNavigator: true)
                    //     .pushReplacement(
                    //   MaterialPageRoute(
                    //     builder: (_) => isVideo
                    //         ? ExpertVideoCall(
                    //       channel: widget.data['channel'],
                    //       token: widget.data['token'],
                    //       callId: widget.callId,
                    //     )
                    //         : ExpertAudioCall(
                    //       channel: widget.data['channel'],
                    //       token: widget.data['token'],
                    //     ),
                    //   ),
                    // );
                    if (_navigated) return;
                    _navigated = true;

                    await FirebaseFirestore.instance
                        .collection('call_requests')
                        .doc(widget.callId)
                        .update({'status': 'accepted',
                      'acceptedAt': FieldValue.serverTimestamp(),
                    });

                    // 2️⃣ UPDATE FIRESTORE AFTER (SAFE)
                    // await FirebaseFirestore.instance
                    //     .collection('call_requests')
                    //     .doc(widget.callId)
                    //     .update({
                    //   'status': 'accepted',
                    //   'acceptedAt': FieldValue.serverTimestamp(),
                    // });

                    log("✅ Firestore updated → accepted");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
