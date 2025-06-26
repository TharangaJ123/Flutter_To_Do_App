import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_do_list/main.dart';

void main() {
  testWidgets('Add and display a task', (WidgetTester tester) async {
    await tester.pumpWidget(const ToDoApp());

    // Enter a task
    await tester.enterText(find.byType(TextField), 'Test Task');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify the task appears
    expect(find.text('Test Task'), findsOneWidget);
  });
} 