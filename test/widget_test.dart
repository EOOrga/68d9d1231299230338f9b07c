import 'package:cachia_michel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates and opens a shipment record', (tester) async {
    final store = OperationsStore.memory();

    await tester.pumpWidget(OperationsApp(store: store));

    expect(find.text('CACHIA MICHEL'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-shipments')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-shipments')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('primary-field')),
      'CM-9001 outbound',
    );
    await tester.enterText(
      find.byKey(const ValueKey('detail-field')),
      'Main warehouse to Gate 2',
    );
    await tester.enterText(find.byKey(const ValueKey('owner-field')), 'Amina');
    await tester.enterText(
      find.byKey(const ValueKey('due-field')),
      'Today 15:00',
    );

    await tester.ensureVisible(find.byKey(const ValueKey('save-record')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-record')));
    await tester.pumpAndSettle();

    expect(find.text('CM-9001 outbound'), findsOneWidget);
    await tester.tap(find.text('CM-9001 outbound'));
    await tester.pumpAndSettle();

    expect(find.text('Shipment detail'), findsOneWidget);
    expect(find.text('Main warehouse to Gate 2'), findsWidgets);
  });

  testWidgets('opens settings and privacy screen', (tester) async {
    final store = OperationsStore.memory();

    await tester.pumpWidget(OperationsApp(store: store));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings and privacy'), findsOneWidget);
    expect(find.textContaining('stores shipment logs'), findsOneWidget);
    expect(find.textContaining('No account registration'), findsOneWidget);
  });
}
