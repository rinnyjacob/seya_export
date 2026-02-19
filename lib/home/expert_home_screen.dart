import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../call/incoming_call_screen.dart';
// import '../chat/expert_chat_screen.dart';
import '../chat/expert_chat_screen.dart';
import '../earnings/earnings_screen.dart';
// import '../profile/expert_profile.dart';

class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  final String expertId = FirebaseAuth.instance.currentUser!.uid;
  bool _dialogOpen = false;

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

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Logout failed")));
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

  /// 💬 SHOW CHAT REQUEST DIALOG
  void _showChatDialog(
      BuildContext context,
      String callId,
      Map<String, dynamic> data,
      ) {
    if (_dialogOpen) return;
    _dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("New Chat Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("User: ${data['userName'] ?? 'User'}"),
            const SizedBox(height: 6),
            Text("Rate: ₹${data['ratePerMinute']}/min"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _rejectChat(callId);
              if (mounted) Navigator.pop(context);
              _dialogOpen = false;
            },
            child: const Text("Reject"),
          ),
          ElevatedButton(
            onPressed: () => _acceptChat(context, callId, data),
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expert Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarningsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ExpertEditProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),

      /// 🔄 EXPERT STATUS STREAM
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

          if (!isOnline) {
            return const Center(
              child: Text(
                "You are Offline",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          /// 🔔 LISTEN FOR INCOMING CHAT / CALL
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('call_requests')
                .where('expertId', isEqualTo: expertId)
                .where('status', whereIn: ['created','ringing'])
                .limit(1)
                .snapshots(),
            builder: (context, callSnap) {
              if (!callSnap.hasData || callSnap.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Waiting for requests…"),
                );
              }

              final doc = callSnap.data!.docs.first;
              final data = doc.data() as Map<String, dynamic>;

              log('kbfgdjksghfsw4785 ${data['type']}');
              /// 📞 CALL → FULL SCREEN
              if (data['type'] == 'audio' || data['type'] == 'video') {
                return IncomingCallScreen(
                  callId: doc.id,
                  data: data,
                );
              }

              /// 💬 CHAT → DIALOG
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showChatDialog(context, doc.id, data);
              });

              return const Center(
                child: Text("Incoming chat request…"),
              );
            },
          );
        },
      ),
    );
  }
}
