import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/service_item.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import 'group_footnote.dart';
import 'inset_group.dart';
import 'section_header.dart';

/// The workshop's active repairs to mark, and "Prenda urgente": the same choice on Servicios and
/// on the first-time Agendar sheet.
class ServicePicker extends StatelessWidget {
  const ServicePicker({
    super.key,
    required this.catalog,
    required this.selectedIds,
    required this.isUrgent,
    required this.onToggle,
    required this.onUrgentChanged,
  });

  final Catalog catalog;
  final Set<String> selectedIds;
  final bool isUrgent;
  final ValueChanged<ServiceItem> onToggle;
  final ValueChanged<bool> onUrgentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsetGroup(
          children: [
            for (final service in catalog.services)
              _ServiceRow(
                service,
                isSelected: selectedIds.contains(service.id),
                onTap: () => onToggle(service),
              ),
          ],
        ),
        const GroupFootnote(AppConstants.servicesDisclaimer),
        const SectionHeader(AppConstants.extrasTitle),
        InsetGroup(children: [_UrgentRow(isUrgent: isUrgent, onChanged: onUrgentChanged)]),
        const GroupFootnote(AppConstants.urgentNote),
      ],
    );
  }
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
