import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expertId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Earnings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('call_requests')
            .where('expertId', isEqualTo: expertId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const CircularProgressIndicator();

          double total = 0;
          for (var d in snap.data!.docs) {
            total += (d['totalAmount'] ?? 0).toDouble();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Total Earnings: ₹$total",
                    style: const TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: ListView(
                  children: snap.data!.docs.map((d) {
                    return ListTile(
                      title: Text("₹${d['totalAmount']}"),
                      subtitle: Text("Duration: ${(d['durationSeconds'] / 60).ceil()} min"),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
