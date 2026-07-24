import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/screens/help/help_screen.dart';
import 'package:video_editor_mobile_app/src/screens/legal/privacy_screen.dart';

Widget _wrap(Widget child) => GetMaterialApp(home: child);

void main() {
  testWidgets('HelpScreen renders all how-to guides', (tester) async {
    await tester.pumpWidget(_wrap(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Create a project'), findsOneWidget);
    expect(find.text('Trim & crop'), findsOneWidget);
    // Guides render in a ListView; scroll to the bottom entries.
    await tester.scrollUntilVisible(find.text('Export & share'), 200);
    expect(find.text('Export & share'), findsOneWidget);
  });

  testWidgets('PrivacyScreen renders the data-handling sections',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrivacyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Local-first processing'), findsOneWidget);
    expect(find.textContaining('never leave the phone'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Compliance'), 200);
    expect(find.text('Compliance'), findsOneWidget);
  });
}
