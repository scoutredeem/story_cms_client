import 'package:flutter/material.dart';
import 'package:story_cms_client/models/page_models.dart';

class PageInfoScreen extends StatelessWidget {
  final PageModel page;
  final Widget Function(BuildContext context, String text) bodyBuilder;
  const PageInfoScreen({
    super.key,
    required this.page,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(page.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
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
