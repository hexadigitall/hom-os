import 'package:flutter_test/flutter_test.dart';
import 'package:hom_mobile/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HOMApp());
    expect(find.text('HOM'), findsOneWidget);
  });
}
