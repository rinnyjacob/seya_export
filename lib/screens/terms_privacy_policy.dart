import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class TermsPrivacyPolicyScreen extends StatefulWidget {
  const TermsPrivacyPolicyScreen({super.key});
  @override
  State<TermsPrivacyPolicyScreen> createState() => _TermsPrivacyPolicyScreenState();
}

class _TermsPrivacyPolicyScreenState extends State<TermsPrivacyPolicyScreen> {
  String privacyHtml = "";
  String termsHtml = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHtmlContent();
  }

  Future<void> fetchHtmlContent() async {
    try {
      final privacyDoc = await FirebaseFirestore.instance.collection('admin').doc('privacy').get();
      final termsDoc = await FirebaseFirestore.instance.collection('admin').doc('terms').get();
      if (!mounted) return;
      setState(() {
        privacyHtml = privacyDoc.data()?['privacy'] ?? '';
        termsHtml = termsDoc.data()?['terms'] ?? '';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        privacyHtml = '<p>Error loading privacy policy.</p>';
        termsHtml = '<p>Error loading terms & conditions.</p>';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Terms & Conditions / Privacy Policy'),
        backgroundColor: bgColor,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terms & Conditions',
                        style: TextStyle(
                          color: primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Html(
                      data: termsHtml,
                      style: {
                        "body": Style(
                          color: textColor,
                          fontSize: FontSize.large,
                        ),
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('Privacy Policy',
                        style: TextStyle(
                          color: primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Html(
                      data: privacyHtml,
                      style: {
                        "body": Style(
                          color: textColor,
                          fontSize: FontSize.large,
                        ),
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
