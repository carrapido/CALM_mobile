import 'package:flutter/material.dart';

import '../models/service_item.dart';
import '../routes/app_routes.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import '../widgets/service_card_widget.dart';
import '../widgets/top_app_bar_widget.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final int _currentNavIndex = 1; // 1 = Servicios
  final List<ServiceItem> _services = ServiceItem.mockServices;

  // Servicios seleccionados por ID (por defecto 1 y 2 como en la imagen)
  final Set<String> _selectedServiceIds = {'1', '2'};
  bool _prendaUrgente = true;

  void _toggleService(String id) {
    setState(() {
      if (_selectedServiceIds.contains(id)) {
        _selectedServiceIds.remove(id);
      } else {
        _selectedServiceIds.add(id);
      }
    });
  }

  double get _totalPrice {
    double total = 0;
    for (final service in _services) {
      if (_selectedServiceIds.contains(service.id) && service.price != null) {
        total += service.price!;
      }
    }
    return total;
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    if (index == 0) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.orders);
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedCount = _selectedServiceIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopAppBarWidget(
        showBrand: false,
        onHelpPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ayuda con los servicios')),
          );
        },
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  Text(
                    AppConstants.servicesTitle,
                    style: AppText.headlineXlMobile.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.servicesSubtitle,
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contenedor blanco con la lista de servicios
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _services.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return ServiceCardWidget(
                          service: service,
                          isSelected: _selectedServiceIds.contains(service.id),
                          onTap: () => _toggleService(service.id),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Disclaimer
                  Text(
                    AppConstants.servicesDisclaimer,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección "Extras"
                  Text(
                    AppConstants.extrasTitle,
                    style: AppText.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppConstants.urgentTitle,
                          style: AppText.bodyLg.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          AppConstants.urgentSubtitle,
                          style: AppText.bodyMd.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _prendaUrgente,
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.primaryDark,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppColors.borderUnselected,
                          onChanged: (val) => setState(() => _prendaUrgente = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    AppConstants.urgentNote,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra / Tarjeta flotante inferior de resumen
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$selectedCount arreglos${_prendaUrgente ? ' · urgente' : ''}',
                              style: AppText.labelLg.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${_totalPrice.toStringAsFixed(0)} MXN${_prendaUrgente ? ' + cargo por urgencia' : ''}',
                              style: AppText.bodySm.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: selectedCount == 0
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ir a elegir horario')),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppConstants.btnElegirHorario,
                          style: AppText.labelLg.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}