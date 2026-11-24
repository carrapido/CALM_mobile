import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/service_item.dart';
import '../models/service_selection.dart';
import '../services/client_data.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/loaded.dart';
import '../widgets/page_heading.dart';
import '../widgets/press_scale.dart';
import '../widgets/schedule_sheet.dart';
import '../widgets/service_picker.dart';
import '../widgets/tab_page.dart';

/// Servicios: the client marks the repairs they need and moves on to choose a time.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _heading =
      PageHeading(AppConstants.servicesTitle, subtitle: AppConstants.servicesSubtitle);

  @override
  Widget build(BuildContext context) {
    final data = ClientDataScope.of(context);
    return Loaded<Catalog>(
      load: data.catalog,
      // A failure without a session shows no tabs: they would lead to screens that are not hers.
      pending: (status, hasFailed) => TabPage(
        tab: AppTab.services,
        showsTabBar: !hasFailed || data.isSignedIn,
        children: [_heading, status],
      ),
      builder: (_, catalog) => _CatalogView(catalog),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView(this.catalog);

  final Catalog catalog;

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  final _selectedIds = <String>{};
  bool _isUrgent = false;

  @override
  Widget build(BuildContext context) {
    final selection = _currentSelection();
    return TabPage(
      tab: AppTab.services,
      floatingBar: selection.isEmpty
          ? null
          : _SelectionBar(selection: selection, onChooseSchedule: () => _openSchedule(selection)),
      children: [
        ServicesScreen._heading,
        ServicePicker(
          catalog: widget.catalog,
          selectedIds: _selectedIds,
          isUrgent: _isUrgent,
          onToggle: _toggle,
          onUrgentChanged: _setUrgent,
        ),
      ],
    );
  }

  ServiceSelection _currentSelection() {
    return ServiceSelection.fromCatalog(widget.catalog, selectedIds: _selectedIds, isUrgent: _isUrgent);
  }

  void _openSchedule(ServiceSelection selection) => showScheduleSheet(context, selection);

  void _toggle(ServiceItem service) {
    setState(() {
      final wasSelected = _selectedIds.remove(service.id);
      if (!wasSelected) _selectedIds.add(service.id);
    });
  }

  void _setUrgent(bool isUrgent) => setState(() => _isUrgent = isUrgent);
}

/// Floats above the tab bar while something is marked: what was chosen, its quote, and the next step.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.selection, required this.onChooseSchedule});

  final ServiceSelection selection;
  final VoidCallback onChooseSchedule;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const [
          BoxShadow(color: AppColors.floatingShadow, offset: Offset(0, 10), blurRadius: 30),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
            decoration: BoxDecoration(
              color: AppColors.barMaterial,
              borderRadius: shape,
              border: Border.all(color: AppColors.floatingBarEdge),
            ),
            child: Row(
              spacing: 12,
              children: [
                Expanded(child: _texts()),
                _ChooseScheduleButton(onPressed: onChooseSchedule),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _texts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(selection.summary, style: AppText.subhead.copyWith(fontWeight: FontWeight.w700)),
        Text(selection.quote, style: AppText.footnoteStrong),
      ],
    );
  }
}

class _ChooseScheduleButton extends StatelessWidget {
  const _ChooseScheduleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppText.button.copyWith(fontSize: 16),
          splashFactory: NoSplash.splashFactory,
        ),
        child: const Text(AppConstants.btnElegirHorario),
      ),
    );
  }
}
