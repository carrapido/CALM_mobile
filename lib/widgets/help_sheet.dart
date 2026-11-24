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
  bool _directionsFailed = false;

  // Maps takes over when it opens; when nothing takes the link, the sheet says so.
  Future<void> _openDirections() async {
    final opened = await openWorkshopMap(context);
    if (!mounted) return;
    setState(() => _directionsFailed = !opened);
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
            // WhatsApp and the call still need the workshop's phone, which the design leaves open.
            InsetGroup(
              separatorIndent: 58,
              children: [
                const IconRow(icon: Icons.chat_bubble_outline_rounded, title: AppConstants.helpWhatsApp),
                const IconRow(icon: Icons.phone_outlined, title: AppConstants.helpCall),
                IconRow(
                  icon: Icons.location_on_outlined,
                  title: AppConstants.helpDirections,
                  onTap: _openDirections,
                ),
              ],
            ),
            if (_directionsFailed) ...[
              const SizedBox(height: 10),
              const FormAlert(AppConstants.directionsFailed),
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
