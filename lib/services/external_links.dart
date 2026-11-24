import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_constants.dart';

/// Opens [link] outside the app; true when something took it.
typedef LinkOpener = Future<bool> Function(Uri link);

/// Hands the Maps app or the browser the link, never an in-app web view. A platform that cannot
/// open it answers false instead of failing.
Future<bool> openExternally(Uri link) async {
  try {
    return await launchUrl(link, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// "Cómo llegar": the workshop on Google Maps, in the Maps app or the browser.
Future<bool> openWorkshopMap(BuildContext context) {
  return LinkOpenerScope.of(context)(Uri.parse(AppConstants.workshopMapsUrl));
}

/// Gives the screens below it the way links leave the app; tests put a stand-in here to see the
/// link without opening anything.
class LinkOpenerScope extends InheritedWidget {
  const LinkOpenerScope({super.key, required this.open, required super.child});

  final LinkOpener open;

  /// [openExternally] when no scope is above [context], as in the running app.
  static LinkOpener of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<LinkOpenerScope>()?.open ?? openExternally;
  }

  @override
  bool updateShouldNotify(LinkOpenerScope oldWidget) => open != oldWidget.open;
}
