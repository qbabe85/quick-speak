import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quick_speek/main.dart';

void main() {
  testWidgets('shows a syllable word, an image and the listen button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuickSpeekApp());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('-'), findsWidgets);
    expect(find.text('czytamy razem'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('repeat button replays without changing the word', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuickSpeekApp());
    await tester.pumpAndSettle();

    List<String?> syllables() => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(FittedBox),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList();

    final before = syllables();
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    expect(syllables(), before);
  });

  testWidgets('opens the word menu and selects a word', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuickSpeekApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Wybierz słowo'), findsOneWidget);
    expect(find.text('auto'), findsOneWidget);
    expect(find.text('baba'), findsOneWidget);

    await tester.tap(find.text('auto'));
    await tester.pumpAndSettle();

    expect(find.text('au'), findsOneWidget);
    expect(find.text('to'), findsOneWidget);
  });
}
