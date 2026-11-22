import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/service_item.dart';
import '../models/service_selection.dart';
import '../services/client_data.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/group_footnote.dart';
import '../widgets/inset_group.dart';
import '../widgets/loaded.dart';
import '../widgets/page_heading.dart';
import '../widgets/press_scale.dart';
import '../widgets/schedule_sheet.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_page.dart';

/// Servicios: the client marks the repairs they need and moves on to choose a time.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _heading =
      PageHeading(AppConstants.servicesTitle, subtitle: AppConstants.servicesSubtitle);

  @override
  Widget build(BuildContext context) {
    return Loaded<Catalog>(
      load: ClientDataScope.of(context).catalog,
      pending: (status) => TabPage(tab: AppTab.services, children: [_heading, status]),
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
        InsetGroup(
          children: [
            for (final service in widget.catalog.services)
              _ServiceRow(
                service,
                isSelected: _selectedIds.contains(service.id),
                onTap: () => _toggle(service),
              ),
          ],
        ),
        const GroupFootnote(AppConstants.servicesDisclaimer),
        const SectionHeader(AppConstants.extrasTitle),
        InsetGroup(children: [_UrgentRow(isUrgent: _isUrgent, onChanged: _setUrgent)]),
        const GroupFootnote(AppConstants.urgentNote),
      ],
    );
  }

  // Marked services keep the catalog's order, whatever order they were tapped in.
  ServiceSelection _currentSelection() {
    return ServiceSelection(
      services: [
        for (final service in widget.catalog.services)
          if (_selectedIds.contains(service.id)) service,
      ],
      isUrgent: _isUrgent,
      urgentSurchargeMxn: widget.catalog.urgentSurchargeMxn,
    );
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

class _ServiceRow extends StatelessWidget {
  const _ServiceRow(this.service, {required this.isSelected, required this.onTap});

  final ServiceItem service;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.pressedCell,
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            child: Row(
              spacing: 12,
              children: [
                Expanded(child: Text(service.title, style: AppText.body)),
                _PriceLabel(service.priceLabel, isQuoted: service.priceMxn == null),
                _CheckCircle(isChecked: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A price in bold ink; something still to be quoted, smaller and gray.
class _PriceLabel extends StatelessWidget {
  const _PriceLabel(this.label, {required this.isQuoted});

  final String label;
  final bool isQuoted;

  @override
  Widget build(BuildContext context) {
    final style = isQuoted
        ? AppText.subhead.copyWith(color: AppColors.onSurfaceVariant)
        : AppText.body.copyWith(fontWeight: FontWeight.w700);
    return Text(label, style: style);
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isChecked ? AppColors.ink : null,
        border: Border.all(color: isChecked ? AppColors.ink : AppColors.checkRing, width: 2),
      ),
      child: isChecked ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
    );
  }
}

class _UrgentRow extends StatelessWidget {
  const _UrgentRow({required this.isUrgent, required this.onChanged});

  final bool isUrgent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isUrgent),
      highlightColor: AppColors.pressedCell,
      splashFactory: NoSplash.splashFactory,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
          child: Row(
            spacing: 12,
            children: [
              Expanded(child: Text(AppConstants.urgentTitle, style: AppText.body)),
              const _PriceLabel(AppConstants.urgentSubtitle, isQuoted: true),
              CupertinoSwitch(
                value: isUrgent,
                onChanged: onChanged,
                activeTrackColor: AppColors.ink,
                inactiveTrackColor: AppColors.switchOffTrack,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
