import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

import '../../services/pdf_cache_service.dart';
import 'pages_index.dart' show launchExternalUri;

enum _PdfLoadStatus { loading, success, error }

/// Renders a remote PDF in-app, downloading and caching it locally first.
class PdfViewerScreen extends StatefulWidget {
  /// The remote location of the PDF to render
  final Uri pdfUri;

  /// The title to show in the app bar
  final String title;

  /// Optional title builder, mirrors [PageInfoScreen]'s pattern
  final Widget Function(BuildContext context, String title)? titleBuilder;

  const PdfViewerScreen({
    super.key,
    required this.pdfUri,
    required this.title,
    this.titleBuilder,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _cacheService = PdfCacheService(client: http.Client());

  _PdfLoadStatus _status = _PdfLoadStatus.loading;
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _PdfLoadStatus.loading);

    try {
      final file = await _cacheService.getFile(widget.pdfUri);
      if (!mounted) return;
      setState(() {
        _file = file;
        _status = _PdfLoadStatus.success;
      });
    } catch (e) {
      log('Error while loading PDF: $e');
      if (!mounted) return;
      setState(() => _status = _PdfLoadStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.titleBuilder == null
          ? AppBar(
              title: Text(widget.title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: Column(
        children: [
          if (widget.titleBuilder != null)
            widget.titleBuilder!(context, widget.title),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _PdfLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case _PdfLoadStatus.success:
        return PDFView(
          filePath: _file!.path,
          onError: (error) => log('PDFView error: $error'),
          onPageError: (page, error) => log('PDFView page $page error: $error'),
        );
      case _PdfLoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text("Couldn't load PDF"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => launchExternalUri(
                  widget.pdfUri,
                  launchMode: LaunchMode.externalApplication,
                ),
                child: const Text('Open in Browser'),
              ),
            ],
          ),
        );
    }
  }
}
