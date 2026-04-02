import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_mandir_app/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GopalMandirApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('श्री गोपाल वैष्णव पीठ गोपाल मंदिर'), findsOneWidget);
  });
}
