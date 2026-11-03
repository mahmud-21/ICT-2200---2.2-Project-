import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_bazar/app.dart';

void main() {
  testWidgets('KrishiBazarApp initializes smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KrishiBazarApp());
    expect(find.byType(KrishiBazarApp), findsOneWidget);
  });

  testWidgets('price comparison tab shows market price listings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KrishiBazarApp());
    await tester.tap(find.text('দাম তুলনা'));
    await tester.pumpAndSettle();

    expect(find.text('বাজারভেদে দামের তুলনা'), findsOneWidget);
    expect(find.text('খুচরা দাম'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('বাজারের দাম'), findsOneWidget);
  });
}
