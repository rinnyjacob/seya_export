// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
// import 'package:path_provider/path_provider.dart';
//
// class DocPreviewScreen extends StatefulWidget {
//   final String docUrl;
//   final String? fileName;
//
//   const DocPreviewScreen({
//     super.key,
//     required this.docUrl,
//     this.fileName,
//   });
//
//   @override
//   State<DocPreviewScreen> createState() => _DocPreviewScreenState();
// }
//
// class _DocPreviewScreenState extends State<DocPreviewScreen> {
//
//   String? localPath;
//   bool loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     downloadFile();
//   }
//
//   Future<void> downloadFile() async {
//     try {
//
//       final dir = await getTemporaryDirectory();
//
//       final filePath = "${dir.path}/${widget.fileName ?? "document"}";
//
//       await Dio().download(widget.docUrl, filePath);
//
//       setState(() {
//         localPath = filePath;
//         loading = false;
//       });
//
//     } catch (e) {
//       debuglog(e.toString());
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     final colorScheme = Theme.of(context).colorScheme;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.fileName ?? "Document"),
//       ),
//
//       body: loading
//           ? Center(
//         child: CircularProgressIndicator(
//           color: colorScheme.tertiary,
//         ),
//       )
//
//         lePath: localPath!,
//       ),
//     );
//   }
// }
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';

class DocPreviewScreen extends StatefulWidget {
  final String url;
  final String? fileName;

  const DocPreviewScreen({
    super.key,
    required this.url,
    this.fileName,
  });

  @override
  State<DocPreviewScreen> createState() => _DocPreviewScreenState();
}

class _DocPreviewScreenState extends State<DocPreviewScreen> {
  late final WebViewController _controller;

  bool isLoading = true;
  bool hasError = false;
  bool isDownloading = false;
  String? downloadError;
  String? localPath;

  String get fileName {
    if (widget.fileName != null && widget.fileName!.isNotEmpty) {
      return widget.fileName!;
    }
    return widget.url.split('/').last.split('?').first;
  }

  String get extension {
    final name = fileName.toLowerCase();
    if (!name.contains(".")) return "";
    return name.split('.').last;
  }

  bool get isPdf => extension == "pdf";

  bool get isImage =>
      ["png", "jpg", "jpeg", "webp"].contains(extension);

  bool get isDoc =>
      ["doc", "docx", "xls", "xlsx", "ppt", "pptx"].contains(extension);

  String get googleViewerUrl =>
      "https://docs.google.com/gview?embedded=true&url=${widget.url}";

  @override
  void initState() {
    super.initState();

    if (!isPdf && !isImage) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              setState(() {
                isLoading = true;
                hasError = false;
              });
            },
            onPageFinished: (_) {
              setState(() => isLoading = false);
            },
            onWebResourceError: (_) {
              setState(() {
                hasError = true;
                isLoading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(googleViewerUrl));
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _downloadAndOpen() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => isDownloading = true);

    log("📥 Starting download...");
    log("🔗 URL: ${widget.url}");

    try {
      Directory? dir;

      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory(); // ✅ SAFE
        log("📱 Android path: ${dir?.path}");
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
        log("📱 iOS path: ${dir.path}");
      } else {
        dir = await getDownloadsDirectory();
        log("💻 Other path: ${dir?.path}");
      }

      if (dir == null) throw Exception("Directory not found");

      final fileName = widget.url.split('/').last.split('?').first;
      final filePath = "${dir.path}/$fileName";

      log("📄 File path: $filePath");

      /// 🔽 DOWNLOAD AS BYTES (most stable)
      final response = await Dio().get(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            log("⬇️ ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      final file = File(filePath);
      await file.writeAsBytes(response.data);

      log("✅ File saved: ${file.existsSync()}");

      setState(() {
        localPath = filePath;
        isDownloading = false;
      });

      /// 📂 OPEN FILE
      log("📂 Opening file...");
      final result = await OpenFilex.open(filePath);

      log("📄 Open result: ${result.type}");

      if (result.type != ResultType.done) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Cannot open file: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e, stack) {
      log("❌ Download error: $e");
      log(stack.toString());

      setState(() => isDownloading = false);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: isDownloading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            tooltip: 'Download',
            onPressed: isDownloading ? null : _downloadAndOpen,
            // color: colorScheme.primary,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (localPath != null)
            _buildLocalPreview(localPath!, theme)
          else if (isPdf)
            PdfViewer.uri(
              Uri.parse(widget.url),
              params: const PdfViewerParams(),
            )
          else if (isImage)
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    widget.url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        Future.microtask(() => setState(() => isLoading = false));
                        return child;
                      }
                      return const SizedBox();
                    },
                    errorBuilder: (_, __, ___) {
                      return const Text("Failed to load image");
                    },
                  ),
                ),
              )
            else
              WebViewWidget(controller: _controller),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          if (hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 10),
                  Text("Failed to load document", style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _openExternally,
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
                    child: const Text("Open in browser"),
                  )
                ],
              ),
            ),
          if (downloadError != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: colorScheme.error, size: 40),
                  const SizedBox(height: 8),
                  Text(downloadError!, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalPreview(String path, ThemeData theme) {
    if (isPdf) {
      return PdfViewer.file(
        path, // Pass path as String, not File
        params: const PdfViewerParams(),
      );
    } else if (isImage) {
      return Center(
        child: InteractiveViewer(
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      // For docs, open externally
      Future.microtask(() => OpenFilex.open(path));
      return Center(child: Text('Opening file...', style: theme.textTheme.bodyMedium));
    }
  }
}