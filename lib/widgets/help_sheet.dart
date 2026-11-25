import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../services/external_links.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import 'form_alert.dart';
import 'icon_row.dart';
import 'inset_group.dart';
import 'sheet_parts.dart';

/// Opens "¿Te ayudamos?", the workshop's contact options, as a sheet over the current screen.
Future<void> showHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.groupedBackground,
    barrierColor: AppColors.sheetScrim,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    sheetAnimationStyle: sheetMotion(context),
    builder: (_) => const HelpSheet(),
  );
}

class HelpSheet extends StatefulWidget {
  const HelpSheet({super.key});

  @override
  State<HelpSheet> createState() => _HelpSheetState();
}

class _HelpSheetState extends State<HelpSheet> {
  // What could not open, with the way to reach the workshop by hand; one at a time.
  String? _failure;

  // The app that takes the link takes over; when nothing takes it, the sheet says so.
  Future<void> _open(Future<bool> Function(BuildContext) open, String failure) async {
    final opened = await open(context);
    if (!mounted) return;
    setState(() => _failure = opened ? null : failure);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetGrabber(),
            const SizedBox(height: 16),
            _Header(onDone: () => Navigator.of(context).pop()),
            const SizedBox(height: 16),
            InsetGroup(
              separatorIndent: 58,
              children: [
                IconRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: AppConstants.helpWhatsApp,
                  onTap: () => _open(openWorkshopWhatsApp, AppConstants.whatsAppFailed),
                ),
                IconRow(
                  icon: Icons.phone_outlined,
                  title: AppConstants.helpCall,
                  onTap: () => _open(callWorkshop, AppConstants.callFailed),
                ),
                IconRow(
                  icon: Icons.location_on_outlined,
                  title: AppConstants.helpDirections,
                  onTap: () => _open(openWorkshopMap, AppConstants.directionsFailed),
                ),
              ],
            ),
            if (_failure case final failure?) ...[
              const SizedBox(height: 10),
              FormAlert(failure),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(AppConstants.helpWorkshopInfo, style: AppText.footnote),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(AppConstants.helpTitle, style: AppText.sheetTitle)),
        TextButton(
          onPressed: onDone,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            textStyle: AppText.button,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(AppConstants.helpDone),
        ),
      ],
    );
  }
}
