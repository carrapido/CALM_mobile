import 'package:flutter/services.dart';

/// The digits of [text], without spaces or any other character.
String digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

/// The first 10 digits of [text] grouped as the app writes a phone: "998 123 4567".
String groupedPhone(String text) {
  var d = digitsOf(text);
  if (d.length > 10) d = d.substring(0, 10);

  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 3 || i == 6) buf.write(' ');
    buf.write(d[i]);
  }
  return buf.toString();
}

/// Da formato "998 123 4567" mientras se escribe (máx. 10 dígitos).
class TelefonoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = groupedPhone(newValue.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}