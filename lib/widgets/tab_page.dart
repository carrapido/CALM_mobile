import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import 'app_tab_bar.dart';
import 'help_sheet.dart';
import 'top_app_bar_widget.dart';

/// Skeleton of the screens with the tab bar: help (and an optional back link) on top,
/// content that scrolls under the translucent tab bar, and an optional bar floating above it.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.tab,
    required this.children,
    this.backLabel,
    this.floatingBar,
    this.showsTabBar = true,
  });

  final AppTab tab;
  final List<Widget> children;
  final String? backLabel;
  final Widget? floatingBar;

  /// False when the tabs would lead a client without a session to screens that are not hers.
  final bool showsTabBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.groupedBackground,
      extendBody: true,
      appBar: TopAppBarWidget(
        showBrand: false,
        backLabel: backLabel,
        onHelpPressed: () => showHelpSheet(context),
      ),
      bottomNavigationBar: showsTabBar ? AppTabBar(current: tab) : null,
      body: _ScrollingContent(floatingBar: floatingBar, children: children),
    );
  }
}

class _ScrollingContent extends StatelessWidget {
  const _ScrollingContent({required this.floatingBar, required this.children});

  final Widget? floatingBar;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // With extendBody, the bottom padding already includes the tab bar.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + (floatingBar == null ? 24 : 96)),
      children: children,
    );
    if (floatingBar == null) return list;
    return Stack(
      children: [
        list,
        Positioned(left: 12, right: 12, bottom: bottomInset + 12, child: floatingBar!),
      ],
    );
  }
}
