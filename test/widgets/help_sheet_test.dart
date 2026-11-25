import 'package:calm_mobil/services/external_links.dart';
import 'package:calm_mobil/widgets/help_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const mapsLink = 'https://maps.app.goo.gl/nGsvenuYn4VE4rBfA?g_st=aw';
const address = 'Benito Juárez 223, casa 22, Los Héroes, Mz 10, 77517 Cancún, Q.R.';
const whatsAppLink = 'https://wa.me/529983259560';
const callLink = 'tel:+529983259560';

void main() {
  testWidgets('shows the workshop address and hours', (tester) async {
    await pumpSheet(tester, (_) async => true);

    expect(find.text('Taller Cancún · $address · 10:00 a 18:00'), findsOneWidget);
    expect(find.textContaining('['), findsNothing);
  });

  testWidgets('opens the workshop on Maps from "Cómo llegar"', (tester) async {
    final opened = <Uri>[];
    await pumpSheet(tester, (link) async {
      opened.add(link);
      return true;
    });

    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse(mapsLink)]);
    expect(find.textContaining('No pudimos abrir Mapas'), findsNothing);
  });

  testWidgets('says so, with the address, when Maps cannot open', (tester) async {
    await pumpSheet(tester, (_) async => false);

    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos abrir Mapas. Estamos en $address'), findsOneWidget);
  });

  testWidgets('opens WhatsApp with the workshop from "Escribir por WhatsApp"', (tester) async {
    final opened = <Uri>[];
    await pumpSheet(tester, (link) async {
      opened.add(link);
      return true;
    });

    await tester.tap(find.text('Escribir por WhatsApp'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse(whatsAppLink)]);
    expect(find.textContaining('No pudimos abrir'), findsNothing);
  });

  testWidgets('says so, with the number, when WhatsApp cannot open', (tester) async {
    await pumpSheet(tester, (_) async => false);

    await tester.tap(find.text('Escribir por WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos abrir WhatsApp. Escríbenos al 998 325 9560'), findsOneWidget);
  });

  testWidgets('dials the workshop from "Llamar al taller"', (tester) async {
    final opened = <Uri>[];
    await pumpSheet(tester, (link) async {
      opened.add(link);
      return true;
    });

    await tester.tap(find.text('Llamar al taller'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse(callLink)]);
    expect(find.textContaining('No pudimos abrir'), findsNothing);
  });

  testWidgets('says so, with the number, when the call cannot open', (tester) async {
    await pumpSheet(tester, (_) async => false);

    await tester.tap(find.text('Llamar al taller'));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos abrir el teléfono. Llámanos al 998 325 9560'), findsOneWidget);
    expect(find.textContaining('No pudimos abrir WhatsApp'), findsNothing);
  });
}

Future<void> pumpSheet(WidgetTester tester, LinkOpener openLink) async {
  await tester.pumpWidget(
    LinkOpenerScope(
      open: openLink,
      child: const MaterialApp(home: Scaffold(body: HelpSheet())),
    ),
  );
}
