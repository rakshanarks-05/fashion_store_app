import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke: basic scaffold renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Fashion Store')),
        ),
      ),
    );
    expect(find.text('Fashion Store'), findsOneWidget);
  });
}
