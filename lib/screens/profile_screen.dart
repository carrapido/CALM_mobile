import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../routes/app_routes.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/telefono_formatter.dart';
import '../widgets/boton_taller.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import '../widgets/campo_taller.dart';
import '../widgets/top_app_bar_widget.dart';

/// Pantalla "Mi Perfil": datos de contacto, ticket activo y accesos directos.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.profile = UserProfile.mock});

  final UserProfile profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _perfilIndex = 3;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.profile.fullName);
    _telefonoCtrl = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _mostrarMensaje(AppConstants.profileSaved);
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _confirmarSalida() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderStrong, width: 2),
        ),
        title: Text(AppConstants.logoutConfirmTitle, style: AppText.headlineSm),
        content: Text(
          'Se desvinculará el Ticket ${widget.profile.ticket} para ingresar '
          'otro número de cliente.',
          style: AppText.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppConstants.cancelLabel, style: AppText.labelLg),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppConstants.logoutLabelShort,
              style: AppText.labelLg.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    // `mounted` evita usar el BuildContext si la pantalla se cerró durante el await.
    if (confirmado == true && mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.initial, (_) => false);
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.services);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: TopAppBarWidget(
        onHelpPressed: () => _mostrarMensaje('Ayuda del Taller'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              Text(AppConstants.profileTitle, style: AppText.headlineXlMobile),
              const SizedBox(height: 4),
              Text(
                AppConstants.profileSubtitle,
                style: AppText.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _TarjetaTicket(ticket: widget.profile.ticket),
              const SizedBox(height: 24),
              _FormularioDatos(
                formKey: _formKey,
                nombreCtrl: _nombreCtrl,
                telefonoCtrl: _telefonoCtrl,
                onGuardar: _guardar,
              ),
              const SizedBox(height: 24),
              _AccesosDirectos(
                onCitas: () => _mostrarMensaje(AppConstants.appointmentsLabel),
                onSalir: _confirmarSalida,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _perfilIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _TarjetaTicket extends StatelessWidget {
  const _TarjetaTicket({required this.ticket});

  final String ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStrong, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ticketYellow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderStrong, width: 2),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.borderStrong,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.ticketLabel.toUpperCase(),
                style: AppText.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text('#$ticket', style: AppText.ticketBadge),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormularioDatos extends StatelessWidget {
  const _FormularioDatos({
    required this.formKey,
    required this.nombreCtrl,
    required this.telefonoCtrl,
    required this.onGuardar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController telefonoCtrl;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStrong, width: 2),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoTaller(
              etiqueta: AppConstants.nameLabel,
              icono: Icons.person_outline,
              hint: 'Ej: Carlos Ruiz',
              controller: nombreCtrl,
              teclado: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppConstants.nameRequired
                  : null,
            ),
            const SizedBox(height: 20),
            CampoTaller(
              etiqueta: AppConstants.phoneLabel,
              icono: Icons.call_outlined,
              hint: 'Ej: 998 123 4567',
              controller: telefonoCtrl,
              teclado: TextInputType.phone,
              formatters: [TelefonoFormatter()],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onGuardar(),
              validator: (v) {
                final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digitos.length == 10 ? null : AppConstants.phoneRequired;
              },
            ),
            const SizedBox(height: 28),
            BotonTaller(
              texto: AppConstants.saveButton,
              icono: Icons.check_circle_outline,
              onPressed: onGuardar,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccesosDirectos extends StatelessWidget {
  const _AccesosDirectos({required this.onCitas, required this.onSalir});

  final VoidCallback onCitas;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppConstants.shortcutsLabel.toUpperCase(),
            style: AppText.labelSm.copyWith(
              color: AppColors.outline,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderStrong, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _AccesoTile(
                icono: Icons.calendar_month_outlined,
                etiqueta: AppConstants.appointmentsLabel,
                onTap: onCitas,
              ),
              const Divider(
                height: 2,
                thickness: 2,
                color: AppColors.borderSubtle,
              ),
              _AccesoTile(
                icono: Icons.logout_rounded,
                etiqueta: AppConstants.logoutLabel,
                onTap: onSalir,
                color: AppColors.errorRed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccesoTile extends StatelessWidget {
  const _AccesoTile({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.color = AppColors.borderStrong,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  etiqueta,
                  style: AppText.labelMd.copyWith(color: color),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
