import 'package:flutter/services.dart';

/// The digits of [text], without spaces or any other character.
String digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

/// Da formato "998 123 4567" mientras se escribe (máx. 10 dígitos).
class TelefonoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = digitsOf(newValue.text);
    if (d.length > 10) d = d.substring(0, 10);

    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) buf.write(' ');
      buf.write(d[i]);
    }
    final texto = buf.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}