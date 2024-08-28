import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:http/http.dart' as http;
import 'package:story_cms_client/story_cms_client.dart';

Future<void> main() async {
  await Hive.initFlutter();
  final box = await Hive.openBox('app');

  runApp(ExampleApp(box: box));
}

class ExampleApp extends StatelessWidget {
  final Box box;
  const ExampleApp({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PagesLoader(
                client: StoryCMSClient(
                  NetworkService(http.Client()),
                  baseUrl: 'https://content.openthebible.org.uk/api/v1',
                ),
                storeService: ClientStoreService(box),
                builder: (context, groupedPages, onPageSelected) {
                  return Column(
                    children: [
                      for (var group in groupedPages)
                        Column(
                          children: [
                            PageGroupItem(
                              group: group,
                              onPageSelected: onPageSelected,
                            ),
                            if (group != groupedPages.last) const Divider(),
                            const SizedBox(height: 32),
                          ],
                        ),
                    ],
                  );
                },
                tapOption: TapOption.navigate,
                infoBodyBuilder: (context, text) {
                  return Text(text);
                },
              ),
              const Divider(),
              const Spacer(),
              const Text('Selected Page:'),
              SelectedPageLoader(
                builder: (context, page) {
                  return Text(page.title);
                },
                nullWidget: const Text('No page selected'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PageGroupItem extends StatelessWidget {
  final List<PageModel> group;
  final void Function(PageModel page) onPageSelected;
  const PageGroupItem({
    super.key,
    required this.group,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var page in group)
          Column(
            children: [
              ListTile(
                title: Text(page.title),
                subtitle: Text(page.description),
                onTap: () => onPageSelected(page),
                trailing: page.isExternal
                    ? const Icon(Icons.open_in_new)
                    : const Icon(Icons.arrow_forward_ios),
              ),
              const SizedBox(height: 32),
            ],
          ),
      ],
    );
  }
}
