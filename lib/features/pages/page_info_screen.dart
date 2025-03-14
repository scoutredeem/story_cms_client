import 'package:flutter/material.dart';
import 'package:story_cms_client/models/page_model.dart';

class PageInfoScreen extends StatelessWidget {
  final PageModel page;
  final Widget Function(BuildContext context, String title)? titleBuilder;
  final Widget Function(BuildContext context, String text) bodyBuilder;
  const PageInfoScreen({
    super.key,
    required this.page,
    required this.bodyBuilder,
    this.titleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (titleBuilder == null)
          ? AppBar(
              title: Text(page.title),
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
          if (titleBuilder != null) titleBuilder!(context, page.title),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: bodyBuilder(context, page.body),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
