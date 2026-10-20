import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbole/main.dart';
import 'package:futbole/screens/home_screen.dart';

void main() {
  testWidgets('FutboLE smoke test loads app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify HomeScreen is loaded and FutboLE brand is present
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('Futbo', findRichText: true), findsWidgets);
  });
}
