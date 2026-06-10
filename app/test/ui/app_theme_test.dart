import 'package:alaif/main.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('AlaifApp installs the Ink & Paper theme', (tester) async {
    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, isNotNull);
    expect(app.theme!.scaffoldBackgroundColor, AlaifColors.paper);
    expect(app.theme!.colorScheme.primary, AlaifColors.ink);
  });
}
