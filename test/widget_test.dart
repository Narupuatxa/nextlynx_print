import 'package:flutter_test/flutter_test.dart';
import 'package:reprografia_nextlynx/main.dart';

void main() {
  testWidgets('MyApp renders correctly', (WidgetTester tester) async {
    // Passa isDark: false (ou true, se preferir)
    await tester.pumpWidget(const MyApp(isDark: false));

    // Aguarda o frame
    await tester.pumpAndSettle();

    // Verifica se o título aparece
    expect(find.text('NetLynx Print'), findsOneWidget);
  });
}