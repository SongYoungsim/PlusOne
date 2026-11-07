import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('기본 위젯 테스트가 동작한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('PlusOne'),
        ),
      ),
    );

    expect(find.text('PlusOne'), findsOneWidget);
  });
}
