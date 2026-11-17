import 'package:calm_mobil/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app opens on Entrada', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Tus pedidos'), findsOneWidget);
  });
}
