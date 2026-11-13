import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quick_speek/main.dart';

void main() {
  testWidgets('shows a syllable word and the image placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuickSpeekApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.textContaining('-'), findsWidgets);
  });
}
