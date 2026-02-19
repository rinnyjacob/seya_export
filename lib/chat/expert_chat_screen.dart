import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ExpertEditProfileScreen extends StatefulWidget {
  const ExpertEditProfileScreen({super.key});

  @override
  State<ExpertEditProfileScreen> createState() =>
      _ExpertEditProfileScreenState();
}

class _ExpertEditProfileScreenState extends State<ExpertEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool isOnline = false;
  bool loading = true;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc =
    await FirebaseFirestore.instance.collection('experts').doc(uid).get();

    final data = doc.data()!;
    _nameCtrl.text = data['name'] ?? '';
    _skillCtrl.text = data['skill'] ?? '';
    _expCtrl.text = data['experience']?.toString() ?? '';
    _priceCtrl.text = data['price_per_minute']?.toString() ?? '';
    isOnline = data['is_online'] ?? false;

    setState(() => loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('experts').doc(uid).update({
      'name': _nameCtrl.text.trim(),
      'skill': _skillCtrl.text.trim(),
      'experience': int.parse(_expCtrl.text),
      'price_per_minute': int.parse(_priceCtrl.text),
      'is_online': isOnline,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field("Name", _nameCtrl),
              _field("Skill", _skillCtrl),
              _numberField("Experience (years)", _expCtrl),
              _numberField("₹ / Minute", _priceCtrl),

              const SizedBox(height: 16),

              SwitchListTile(
                value: isOnline,
                title: Text(isOnline ? "Online" : "Offline"),
                onChanged: (v) => setState(() => isOnline = v),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        validator: (v) => int.tryParse(v ?? '') == null ? "Invalid" : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}


class ExpertChatScreen extends StatefulWidget {
  final String callId;
  final String userName;

  const ExpertChatScreen({
    super.key,
    required this.callId,
    required this.userName,
  });

  @override
  State<ExpertChatScreen> createState() => _ExpertChatScreenState();
}

class _ExpertChatScreenState extends State<ExpertChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenForEnd();
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => setState(() => _seconds++),
    );
  }

  /// 👀 CLOSE IF USER ENDS CHAT
  void _listenForEnd() {
    FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['status'] == 'ended' && mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .collection('messages')
        .add({
      'senderRole': 'expert',
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _msgCtrl.clear();
  }

  Future<void> _endChat() async {
    _timer?.cancel();

    await FirebaseFirestore.instance
        .collection('call_requests')
        .doc(widget.callId)
        .update({
      'status': 'ended',
      'endedBy': 'expert',
      'endedAt': FieldValue.serverTimestamp(),
      'durationSeconds': _seconds,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _endChat,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Text("Chat Time: ${m}m ${s}s"),
          ),
          Expanded(child: _messages()),
          _input(),
        ],
      ),
    );
  }

  Widget _messages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('call_requests')
          .doc(widget.callId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snap.data!.docs.map((d) {
            final m = d.data() as Map<String, dynamic>;
            final isExpert = m['senderRole'] == 'expert';

            return Align(
              alignment:
              isExpert ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  isExpert ? Colors.green : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  m['message'],
                  style: TextStyle(
                    color: isExpert ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _input() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration:
              const InputDecoration(hintText: "Reply…"),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _send,
          )
        ],
      ),
    );
  }
}
