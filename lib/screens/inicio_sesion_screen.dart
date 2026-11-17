import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes/app_routes.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/telefono_formatter.dart';
import '../widgets/top_app_bar_widget.dart';

class InicioSesionScreen extends StatefulWidget {
  const InicioSesionScreen({super.key, this.onIngresar});

  final void Function(String telefono, String nip)? onIngresar;

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _nipCtrl.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final telefono = _telefonoCtrl.text.replaceAll(RegExp(r'\D'), '');
    final nip = _nipCtrl.text.trim();
    widget.onIngresar?.call(telefono, nip);

    Navigator.of(context).pushReplacementNamed(AppRoutes.services);
  }

  void _mostrarAyuda() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ayuda del taller', style: AppText.headlineSm),
        content: Text(
          'Escribe tu número de celular y tu NIP de 4 dígitos para consultar tus pedidos.',
          style: AppText.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido', style: TextStyle(color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopAppBarWidget(
        showBrand: true,
        onHelpPressed: _mostrarAyuda,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 32),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.loginTitle,
                            style: AppText.headlineXlMobile.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppConstants.loginSubtitle,
                            style: AppText.bodyMd.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Tarjeta contenedora de Celular y NIP
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCanvas,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          AppConstants.labelPhone,
                                          style: AppText.labelLg.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _telefonoCtrl,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.next,
                                          inputFormatters: [TelefonoFormatter()],
                                          style: AppText.bodyLg.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: AppConstants.hintPhone,
                                            hintStyle: AppText.bodyLg.copyWith(
                                              color: AppColors.textSubtle,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          validator: (v) {
                                            final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                                            return d.length == 10
                                                ? null
                                                : 'Ingresa los 10 dígitos';
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, thickness: 1, color: AppColors.dividerColor),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          AppConstants.labelNip,
                                          style: AppText.labelLg.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _nipCtrl,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                          obscureText: true,
                                          maxLength: 4,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          style: AppText.bodyLg.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            counterText: '',
                                            hintText: AppConstants.hintNip,
                                            hintStyle: AppText.bodyLg.copyWith(
                                              color: AppColors.textSubtle,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          validator: (v) => (v == null || v.trim().length != 4)
                                              ? 'Ingresa tu NIP de 4 dígitos'
                                              : null,
                                          onFieldSubmitted: (_) => _enviar(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Botón "Ver mis pedidos"
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _enviar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                AppConstants.btnVerPedidos,
                                style: AppText.labelLg.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Enlace "Olvidé mi NIP"
                          Center(
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Comunícate con el taller para recuperar tu NIP.'),
                                  ),
                                );
                              },
                              child: Text(
                                AppConstants.btnOlvideNip,
                                style: AppText.labelLg.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Sección inferior "¿Primera vez?"
                          Text(
                            AppConstants.labelPrimeraVez,
                            style: AppText.labelSm.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          InkWell(
                            onTap: () {
                              Navigator.of(context).pushReplacementNamed(AppRoutes.services);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppConstants.titleAgendaCita,
                                          style: AppText.bodyLg.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppConstants.subtitleAgendaCita,
                                          style: AppText.bodySm.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSubtle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}