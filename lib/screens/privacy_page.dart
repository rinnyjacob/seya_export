import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyPage extends StatefulWidget {
  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  String privacyHtml = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHtmlContent();
  }

  Future<void> fetchHtmlContent() async {
    try {
      // final termsDoc = await FirebaseFirestore.instance.collection('admin').doc('terms').get();

      final privacyDoc = await FirebaseFirestore.instance.collection('admin').doc('privacy').get();
      setState(() {
        privacyHtml = privacyDoc.data()?['privacy'] ?? '';
        loading = false;
      });
    } catch (e) {
      setState(() {
        privacyHtml = '<p>Error loading privacy policy.</p>';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        // backgroundColor: Color(0xFF1c0c1f),
      ),
      // backgroundColor: Color(0xFFc89c6e),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Html(
                  data: privacyHtml,
                  style: {
                    "body": Style(
                      // color: theme.colorScheme.surface,
                      // backgroundColor: Color(0xFFc89c6e),
                      fontSize: FontSize.large,
                    ),
                  },
                ),
              ),
            ),
    );
  }
}

