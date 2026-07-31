import 'package:flutter_test/flutter_test.dart';
import 'package:hom_mobile/main.dart';

void main() {
  testWidgets('Fresh install lands on zero-trust owner registration gate, not an admin shell', (WidgetTester tester) async {
    await tester.pumpWidget(const HOMApp());
    expect(find.textContaining('HOM'), findsWidgets);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Welcome to HOM'), findsOneWidget);
  });
}
