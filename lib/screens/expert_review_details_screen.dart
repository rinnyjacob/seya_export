import 'package:flutter/material.dart';

class ExpertReviewDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> review;
  const ExpertReviewDetailsScreen({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFFC89C6E);
    final Color background = const Color(0xFF1C0C1F);
    final String userPhoto = review['userPhoto'] ?? '';
    final String userName = review['userName'] ?? '';
    final String userEmail = review['userEmail'] ?? '';
    final String userPhone = review['userPhone'] ?? '';
    final String expertName = review['expertName'] ?? '';
    final String callType = review['callType'] ?? '';
    final int? rating = review['rating'] is int ? review['rating'] : int.tryParse('${review['rating']}');
    final String feedback = review['feedback'] ?? '';
    final int? totalAmount = review['totalAmount'] is int ? review['totalAmount'] : int.tryParse('${review['totalAmount']}');
    final int? durationSeconds = review['durationSeconds'] is int ? review['durationSeconds'] : int.tryParse('${review['durationSeconds']}');
    final DateTime? createdAt = review['createdAt'] is DateTime ? review['createdAt'] : (review['createdAt']?.toDate?.call() ?? null);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        title: Text('Review Details', style: TextStyle(color: primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: primary.withOpacity(0.2),
                  backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                  child: userPhoto.isEmpty ? Icon(Icons.person, color: primary, size: 32) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
                      if (userEmail.isNotEmpty)
                        Text(userEmail, style: TextStyle(fontSize: 14, color: Colors.white70)),
                      if (userPhone.isNotEmpty)
                        Text(userPhone, style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow('Expert', expertName, primary),
            _detailRow('Call Type', callType, primary),
            if (createdAt != null)
              _detailRow('Date', '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}', primary),
            if (durationSeconds != null)
              _detailRow('Duration', '${durationSeconds}s', primary),
            if (totalAmount != null)
              _detailRow('Amount', '₹$totalAmount', primary),
            if (rating != null)
              Row(
                children: [
                  Text('Rating:', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ...List.generate(5, (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: primary,
                    size: 22,
                  )),
                ],
              ),
            const SizedBox(height: 20),
            Text('Feedback', style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                feedback.isNotEmpty ? feedback : 'No feedback provided.',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15))),
        ],
      ),
    );
  }
}

