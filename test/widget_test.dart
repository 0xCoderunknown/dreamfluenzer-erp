import 'package:dreamfluenzer_erp/widgets/common/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DreamStatusChip displays its label and custom color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DreamStatusChip(label: 'Active', customColor: Colors.green),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Active'));
    expect(label.style?.color, Colors.green);
  });
}
