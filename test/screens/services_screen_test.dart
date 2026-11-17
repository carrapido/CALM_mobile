import 'package:calm_mobil/screens/services_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the catalog and the urgent extra', (tester) async {
    await pumpServices(tester);

    for (final text in [
      'Marca lo que necesitas y elige tu horario.',
      'Ajuste de cintura',
      r'$180',
      'Ajuste de vestido de fiesta',
      r'$300',
      'Vestido Personalizado',
      'A cotizar',
      'Cambio de cierre',
      r'$130',
      'Dobladillo de pantalón',
      r'$100',
      'Parche',
      r'$40',
      'El precio final se confirma al revisar tu prenda.',
      'Extras',
      'Prenda urgente',
      'Cargo extra',
      'Te la entregamos antes. El cargo se suma a tus arreglos.',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Elegir horario'), findsNothing);
  });

  testWidgets('shows the selection bar once a service is marked', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.pump();

    expect(find.text('1 arreglo'), findsOneWidget);
    expect(find.text(r'$180 MXN'), findsOneWidget);
    expect(find.text('Elegir horario'), findsOneWidget);
  });

  testWidgets('adds up every marked service', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.tap(find.text('Parche'));
    await tester.pump();

    expect(find.text('2 arreglos'), findsOneWidget);
    expect(find.text(r'$220 MXN'), findsOneWidget);
  });

  testWidgets('hides the bar when the last service is unmarked', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.pump();
    await tester.tap(find.text('Ajuste de cintura'));
    await tester.pump();

    expect(find.text('Elegir horario'), findsNothing);
  });

  testWidgets('marks the order as urgent from the whole row', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.tap(find.text('Prenda urgente'));
    await tester.pump();

    expect(find.text('1 arreglo · urgente'), findsOneWidget);
    expect(find.text(r'$180 MXN + cargo por urgencia'), findsOneWidget);
  });
}

Future<void> pumpServices(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: ServicesScreen()));
}
