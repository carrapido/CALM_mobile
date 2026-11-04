import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

/// Campo de texto con etiqueta arriba, borde grueso y sombra sólida.
class CampoTaller extends StatelessWidget {
  const CampoTaller({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.hint,
    required this.controller,
    this.ayuda,
    this.teclado = TextInputType.number,
    this.formatters,
    this.validator,
    this.negritaEnValor = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String etiqueta;
  final IconData icono;
  final String hint;
  final String? ayuda; // texto pequeño a la derecha, ej. "10 dígitos"
  final TextEditingController controller;
  final TextInputType teclado;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final bool negritaEnValor;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  OutlineInputBorder _borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: AppColors.borderStrong, size: 24),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                etiqueta,
                style: AppText.headlineSm.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (ayuda != null)
              Text(
                ayuda!,
                style: AppText.labelSm.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.borderStrong,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: teclado,
            inputFormatters: formatters,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            style: AppText.bodyLg.copyWith(
              color: AppColors.borderStrong,
              fontWeight: negritaEnValor ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: negritaEnValor ? 0.5 : 0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.bodyLg.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.surfaceCanvas,
              constraints: const BoxConstraints(minHeight: 54),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: _borde(AppColors.borderStrong),
              enabledBorder: _borde(AppColors.borderStrong),
              focusedBorder: _borde(AppColors.borderStrong),
              errorBorder: _borde(AppColors.errorRed),
              focusedErrorBorder: _borde(AppColors.errorRed),
              errorStyle: AppText.bodySm.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}