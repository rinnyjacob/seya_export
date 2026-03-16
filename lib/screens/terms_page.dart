import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsPage extends StatefulWidget {
  @override
  _TermsPageState createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  String termsHtml = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHtmlContent();
  }

  Future<void> fetchHtmlContent() async {
    try {
      final termsDoc = await FirebaseFirestore.instance.collection('admin').doc('terms').get();
      log('sdfgjdflkg ${ termsDoc.data()?['terms']}');
      setState(() {
        termsHtml = termsDoc.data()?['terms'] ?? '';
        loading = false;
      });
    } catch (e) {
      setState(() {
        termsHtml = '<p>Error loading terms & conditions.</p>';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions'),
        // backgroundColor: Color(0xFF1c0c1f),
      ),
      // backgroundColor: Color(0xFFc89c6e),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : (termsHtml.trim().isEmpty
              ? Center(child: Text('No Terms & Conditions found.', style: TextStyle( fontSize: 18)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Html(
                      data: termsHtml,
                      style: {
                        "body": Style(
                          // color: Color(0xFF1c0c1f),
                          // backgroundColor: Color(0xFFc89c6e),
                          fontSize: FontSize.large,
                        ),
                      },
                    ),
                  ),
                )
            ),
    );
  }
}
