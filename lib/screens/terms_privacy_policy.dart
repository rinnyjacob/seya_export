import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsPrivacyPolicyScreen extends StatefulWidget {
  @override
  _TermsPrivacyPolicyScreenState createState() => _TermsPrivacyPolicyScreenState();
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
      final privacyDoc = await FirebaseFirestore.instance.collection('privacy').doc('privacy').get();
      final termsDoc = await FirebaseFirestore.instance.collection('terms').doc('terms').get();
      setState(() {
        privacyHtml = privacyDoc.data()?['privacy'] ?? '';
        termsHtml = termsDoc.data()?['terms'] ?? '';
        loading = false;
      });
    } catch (e) {
      setState(() {
        privacyHtml = '<p>Error loading privacy policy.</p>';
        termsHtml = '<p>Error loading terms & conditions.</p>';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions / Privacy Policy'),
        backgroundColor: Color(0xFF1c0c1f),
      ),
      // backgroundColor: Color(0xFFc89c6e),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terms & Conditions',
                        style: TextStyle(
                          color: Color(0xFF1c0c1f),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Html(
                      data: termsHtml,
                      style: {
                        "body": Style(
                          color: Color(0xFF1c0c1f),
                          backgroundColor: Color(0xFFc89c6e),
                          fontSize: FontSize.large,
                        ),
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF1c0c1f),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Html(
                      data: privacyHtml,
                      style: {
                        "body": Style(
                          color: Color(0xFF1c0c1f),
                          backgroundColor: Color(0xFFc89c6e),
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
