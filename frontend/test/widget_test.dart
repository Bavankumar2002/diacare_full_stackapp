import 'package:flutter_test/flutter_test.dart';
import 'package:diacare/main.dart';

void main() {
  testWidgets('DiaCare app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DiaCareApp());
    expect(find.byType(DiaCareApp), findsOneWidget);
  });
}
