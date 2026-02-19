import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/expert_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> loginExpert() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Firebase Auth login
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final uid = cred.user!.uid;

      // 2️⃣ Verify expert role in Firestore
      final expertDoc = await FirebaseFirestore.instance
          .collection('experts')
          .doc(uid)
          .get();

      if (!expertDoc.exists) {
        await FirebaseAuth.instance.signOut();
        throw "Not an expert account";
      }

      if (expertDoc.data()?['role'] != 'expert') {
        await FirebaseAuth.instance.signOut();
        throw "Access denied";
      }

      // ✅ Login success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ExpertHomeScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Expert Login",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : loginExpert,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
