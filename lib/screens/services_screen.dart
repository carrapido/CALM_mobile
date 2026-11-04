import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/top_app_bar_widget.dart';
import '../widgets/service_card_widget.dart';
import '../widgets/bottom_nav_bar_widget.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _currentNavIndex = 0;
  final List<ServiceItem> services = ServiceItem.mockServices;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: TopAppBarWidget(
        onHelpPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ayuda del Taller')),
          );
        },
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              Text(
                AppConstants.servicesTitle,
                style: AppText.headlineXlMobile,
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.servicesSubtitle,
                style: AppText.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              ...services.map(
                (service) => ServiceCardWidget(
                  service: service,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Servicio: ${service.title}')),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppConstants.disclaimerText,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }
}