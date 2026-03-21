import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_mandir_app/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GopalMandirApp());
    expect(find.text('श्री गोपाल मंदिर'), findsOneWidget);
  });
}
