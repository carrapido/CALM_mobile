import 'catalog.dart';
import 'service_item.dart';

/// The repairs the client marked, and whether the garment is urgent.
class ServiceSelection {
  const ServiceSelection({
    required this.services,
    this.isUrgent = false,
    this.urgentSurchargeMxn = 0,
  });

  /// The [catalog]'s repairs marked in [selectedIds], in the catalog's order whatever order they
  /// were tapped in, with its urgency charge.
  factory ServiceSelection.fromCatalog(
    Catalog catalog, {
    required Set<String> selectedIds,
    required bool isUrgent,
  }) {
    return ServiceSelection(
      services: [
        for (final service in catalog.services)
          if (selectedIds.contains(service.id)) service,
      ],
      isUrgent: isUrgent,
      urgentSurchargeMxn: catalog.urgentSurchargeMxn,
    );
  }

  final List<ServiceItem> services;
  final bool isUrgent;

  /// The urgency charge is not defined yet; while it is 0 the quote only mentions it.
  final int urgentSurchargeMxn;

  bool get isEmpty => services.isEmpty;

  String get summary {
    final repairs = services.length == 1 ? '1 arreglo' : '${services.length} arreglos';
    return isUrgent ? '$repairs · urgente' : repairs;
  }

  String get names {
    final names = services.map((service) => service.title).join(', ');
    return isUrgent ? '$names · Urgente' : names;
  }

  /// Preliminary total of the priced repairs; unpriced ones and an unset surcharge are named, not added.
  String get quote {
    final parts = <String>[];
    final total = totalMxn;
    if (total > 0) parts.add('\$$total MXN');
    if (services.any((service) => service.priceMxn == null)) {
      parts.add(parts.isEmpty ? 'A cotizar en el taller' : 'a cotizar');
    }
    if (isUrgent && urgentSurchargeMxn == 0) {
      parts.add(parts.isEmpty ? 'Cargo por urgencia' : 'cargo por urgencia');
    }
    return parts.join(' + ');
  }

  /// Priced repairs plus the urgency charge, in pesos.
  int get totalMxn {
    final repairs = services.fold(0, (sum, service) => sum + (service.priceMxn ?? 0));
    return repairs + (isUrgent ? urgentSurchargeMxn : 0);
  }
}
