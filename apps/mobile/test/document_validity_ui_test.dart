import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/document_validity_ui.dart';
import 'package:karta_wallet/services/document_store.dart';

VaultDocument _doc({DateTime? expiresAt}) => VaultDocument(
      id: 'doc',
      type: 'Passaporte',
      title: 'Passaporte',
      createdAt: DateTime.utc(2026, 1, 1),
      expiresAt: expiresAt,
    );

void main() {
  test('kartaDate formats dates consistently', () {
    expect(kartaDate(DateTime(2026, 9, 18)), '18/09/2026');
  });

  test('validity copy distinguishes attention states', () {
    final now = DateTime.utc(2026, 9, 18);

    expect(
      DocumentValidityCopy.forDocument(
        _doc(expiresAt: DateTime.utc(2026, 9, 17)),
        now: now,
      ).label,
      'Expirado',
    );
    expect(
      DocumentValidityCopy.forDocument(
        _doc(expiresAt: DateTime.utc(2026, 11, 1)),
        now: now,
      ).label,
      'A expirar',
    );
    expect(
      DocumentValidityCopy.forDocument(
        _doc(expiresAt: DateTime.utc(2027, 9, 18)),
        now: now,
      ).label,
      'Válido',
    );
    expect(
      DocumentValidityCopy.forDocument(_doc(), now: now).label,
      'Validade não registada',
    );
  });

  testWidgets('badge exposes readable validity information', (tester) async {
    final document = _doc(expiresAt: DateTime.utc(2026, 11, 1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DocumentValidityBadge(
              document: document,
              now: DateTime.utc(2026, 9, 18),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('A expirar'), findsOneWidget);
    expect(find.textContaining('44 dias'), findsOneWidget);
  });

  testWidgets('date field shows current value and can clear it', (tester) async {
    DateTime? value = DateTime(2026, 9, 18);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DocumentDateField(
              label: 'Validade',
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );

    expect(find.text('18/09/2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpar Validade'));
    await tester.pump();
    expect(find.text('Não indicada'), findsOneWidget);
  });
}
