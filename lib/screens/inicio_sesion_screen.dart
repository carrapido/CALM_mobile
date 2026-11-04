import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/telefono_formatter.dart';
import '../widgets/boton_taller.dart';
import '../widgets/campo_taller.dart';

class InicioSesionScreen extends StatefulWidget {
  const InicioSesionScreen({super.key, this.onIngresar});

  /// Se llama con el teléfono (solo dígitos) y el número de ticket
  /// cuando el formulario es válido. Aquí conectas tu API / navegación.
  final void Function(String telefono, String ticket)? onIngresar;

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();
  final _ticketCtrl = TextEditingController();

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _ticketCtrl.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final telefono = _telefonoCtrl.text.replaceAll(RegExp(r'\D'), '');
    final ticket = _ticketCtrl.text.trim();
    widget.onIngresar?.call(telefono, ticket);
    // TODO: validar con tu backend y navegar, por ejemplo:
    // Navigator.of(context).pushReplacement(...);
  }

  void _mostrarAyuda() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderStrong, width: 2),
        ),
        title: Text('Ayuda del taller', style: AppText.headlineSm),
        content: Text(
          'Escriba su número de teléfono y el número de ticket que viene '
          'en su comprobante. No necesita contraseña.',
          style: AppText.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido', style: AppText.labelLg),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: _BarraSuperior(onAyuda: _mostrarAyuda),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 24),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _InsigniaCalm(),
                        const SizedBox(height: 12),
                        Text('Bienvenido a su Taller',
                            style: AppText.headlineXlMobile),
                        const SizedBox(height: 8),
                        Text(
                          'Consulte el avance de su ropa sin necesidad de '
                          'contraseñas.',
                          style: AppText.bodyMd
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CampoTaller(
                                etiqueta: 'Número de teléfono',
                                icono: Icons.call_outlined,
                                ayuda: '10 dígitos',
                                hint: 'Ej: 998 123 4567',
                                controller: _telefonoCtrl,
                                teclado: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                formatters: [TelefonoFormatter()],
                                validator: (v) {
                                  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                                  return d.length == 10
                                      ? null
                                      : 'Escriba los 10 dígitos de su teléfono';
                                },
                              ),
                              const SizedBox(height: 20),
                              CampoTaller(
                                etiqueta: 'Número de Ticket',
                                icono: Icons.confirmation_number_outlined,
                                hint: 'Ej: 7720',
                                controller: _ticketCtrl,
                                negritaEnValor: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _enviar(),
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Escriba el número de su ticket'
                                        : null,
                              ),
                              const SizedBox(height: 28),
                              BotonTaller(
                                texto: 'Entrar a mis prendas',
                                icono: Icons.check_circle_outline,
                                onPressed: _enviar,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const _PieTaller(),
                      ],
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

/// Barra superior con logo, nombre y botón de ayuda (borde inferior grueso).
class _BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const _BarraSuperior({required this.onAyuda});

  final VoidCallback onAyuda;

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(
          bottom: BorderSide(color: AppColors.borderStrong, width: 2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.precision_manufacturing_outlined,
                    color: AppColors.borderStrong, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'COSTURANDO A LA MEDIDA',
                    overflow: TextOverflow.ellipsis,
                    style: AppText.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ayuda del taller',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: onAyuda,
                  icon: const Icon(Icons.help_outline,
                      color: AppColors.borderStrong, size: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Insignia amarilla tipo etiqueta de taller ("CALM").
class _InsigniaCalm extends StatelessWidget {
  const _InsigniaCalm();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ticketYellow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderStrong,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.content_cut,
              color: AppColors.borderStrong, size: 20),
          const SizedBox(width: 8),
          Text('CALM', style: AppText.labelMd),
        ],
      ),
    );
  }
}

class _PieTaller extends StatelessWidget {
  const _PieTaller();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Text(
        'COSTURANDO A LA MEDIDA',
        textAlign: TextAlign.center,
        style: AppText.labelSm.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}