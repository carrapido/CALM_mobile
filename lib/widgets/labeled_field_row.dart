import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

/// Row of an [InsetGroup]: a fixed-width label, red when the field needs attention, and a borderless field.
class LabeledFieldRow extends StatelessWidget {
  const LabeledFieldRow({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isInvalid = false,
    this.minHeight = 52,
    this.labelWidth = 76,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isInvalid;
  final double minHeight;
  final double labelWidth;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: AppText.body.copyWith(
                    color: isInvalid ? AppColors.errorText : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field() {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppText.body,
      cursorColor: AppColors.ink,
      // Hint and text share one line style, so the hint can leave the tree once the field has text.
      decoration: InputDecoration.collapsed(
        hintText: hint,
        hintStyle: AppText.body.copyWith(color: AppColors.tertiaryLabel),
        maintainHintSize: false,
      ),
    );
  }
}
