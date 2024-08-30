import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../models/page_model.dart';
import 'pages_manager.dart';

class SelectedPageLoader extends StatelessWidget {
  /// A widget that loads the selected page from the [PagesManager]
  final Widget Function(BuildContext context, PageModel page) builder;

  /// A widget to be displayed when the selected page is null
  final Widget nullWidget;
  const SelectedPageLoader({
    super.key,
    required this.builder,
    this.nullWidget = const SizedBox(),
  });

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final page = $pageManager.selectedPage;

      if (page == null) {
        return nullWidget;
      }

      return builder(context, page);
    });
  }
}
