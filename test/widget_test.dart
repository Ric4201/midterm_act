import 'package:flutter_test/flutter_test.dart';
import 'package:midterm_act/main.dart';

void main() {
  testWidgets('MidtermApiApp smoke test renders navigation and screens',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MidtermApiApp());

    // Verify navigation tabs are present
    expect(find.text('The Order (Future)'), findsOneWidget);
    expect(find.text('The Belt (Stream)'), findsOneWidget);
  });
}
