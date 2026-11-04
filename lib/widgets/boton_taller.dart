import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

/// Botón primario: fondo azul medianoche, texto blanco, sombra ámbar.
class BotonTaller extends StatefulWidget {
  const BotonTaller({
    super.key,
    required this.texto,
    required this.icono,
    required this.onPressed,
  });

  final String texto;
  final IconData icono;
  final VoidCallback? onPressed;

  @override
  State<BotonTaller> createState() => _BotonTallerState();
}

class _BotonTallerState extends State<BotonTaller> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _presionado ? 0.98 : 1,
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ticketYellow,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: _presionado
              ? AppColors.primaryContainer
              : AppColors.borderStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderStrong, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _presionado = value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icono, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      widget.texto,
                      style: AppText.labelLg.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
