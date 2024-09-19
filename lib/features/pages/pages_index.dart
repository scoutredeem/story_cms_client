import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../models/page_model.dart';
import '../../services/client_store_service.dart';
import 'page_info_screen.dart';
import 'pages_manager.dart';

typedef PagesLoaderBuilder = Widget Function(
  BuildContext context,
  List<List<PageModel>> groupedPages,
  void Function(PageModel page) onPageSelected,
);

enum TapOption { navigate, select }

class PagesIndex extends StatefulWidget {
  /// A widget that loads the pages from the [PagesManager]
  final PagesLoaderBuilder builder;

  /// A widget to be displayed while the pages are loading
  final Widget loadingWidget;

  /// The client to fetch the pages from
  final CMSClient client;

  /// The optional query parameters to be sent with the request
  final Map<String, String>? queryParameters;

  /// Optinal store box to cache the pages
  final ClientStoreService? storeService;

  /// The tap option to be used when a page is tapped
  final TapOption tapOption;

  /// Page info body builder
  final Widget Function(BuildContext context, String text) infoBodyBuilder;

  const PagesIndex({
    super.key,
    required this.builder,
    required this.client,
    required this.infoBodyBuilder,
    this.queryParameters,
    this.storeService,
    this.tapOption = TapOption.navigate,
    this.loadingWidget = const Center(
      child: CircularProgressIndicator(),
    ),
  });

  @override
  State<PagesIndex> createState() => _PagesIndexState();
}

class _PagesIndexState extends State<PagesIndex> {
  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final pages = $pageManager.pages;

      if (pages.isEmpty) {
        return widget.loadingWidget;
      }

      return widget.builder(
        context,
        _getGroupedPages(pages),
        _onPageSelected,
      );
    });
  }

  List<List<PageModel>> _getGroupedPages(List<PageModel> pages) {
    final groupedPages = <List<PageModel>>[];

    final getAllPageGroups = pages.map((e) => e.group).toSet();

    for (var group in getAllPageGroups) {
      final pagesInGroup = pages.where((e) => e.group == group).toList();
      groupedPages.add(pagesInGroup);
    }
    return groupedPages;
  }

  Future<void> _onPageSelected(PageModel page) async {
    $pageManager.onPageSelected(page);

    if (page.isExternal) {
      final isPdf = page.externalUri.toString().contains('.pdf');
      Uri uri = page.externalUri;
      if (isPdf) {
        // On android, the browser downloads the pdf instead of opening it
        // this embeds the pdf in a google docs viewer
        uri = Uri.parse(
          'https://docs.google.com/gview?embedded=true&url=${Uri.encodeQueryComponent(page.externalUri.toString())}',
        );
      }

      await launchExternalUri(uri);
      return;
    }

    if (widget.tapOption != TapOption.navigate) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return PageInfoScreen(
            page: page,
            bodyBuilder: widget.infoBodyBuilder,
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    $pageManager.init(
      client: widget.client,
      queryParameters: widget.queryParameters,
      storeService: widget.storeService,
    );
  }

  @override
  void dispose() {
    $pageManager.dispose();
    super.dispose();
  }
}

/// Launches the given [uri] in an in-app-browser
Future<void> launchExternalUri(Uri uri, {LaunchMode? launchMode}) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: launchMode ??
          (uri.toString().startsWith('mailto:')
              ? LaunchMode.externalApplication
              : LaunchMode.inAppBrowserView),
    );
  } else {
    log('Could not launch $uri');
  }
}
