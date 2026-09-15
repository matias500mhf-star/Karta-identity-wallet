import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/pdf_viewer_page.dart';
import 'package:karta_wallet/document_vault_page.dart';
import 'package:karta_wallet/services/document_store.dart';

class TestStore extends DocumentStore {
  final bytes = Uint8List.fromList(utf8.encode('%PDF-1.4 test'));
  @override
  Future<Uint8List> readEncrypted(String fileName) async => bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(documentChannel, null),
  );

  testWidgets('PDF opens, navigates and closes the renderer', (tester) async {
    final calls = <String>[];
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(documentChannel, (call) async {
          calls.add(call.method);
          if (call.method == 'openPdf') {
            return 2;
          }
          if (call.method == 'renderPdf') {
            return png;
          }
          return null;
        });
    await tester.pumpWidget(
      MaterialApp(
        home: PdfViewerPage(bytes: Uint8List(0), title: 'teste.pdf'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Página 1 de 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Página seguinte'));
    await tester.pumpAndSettle();
    expect(find.text('Página 2 de 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(calls, ['openPdf', 'renderPdf', 'renderPdf', 'closePdf']);
  });

  testWidgets(
    'export uses existing decrypted attachment and cancellation is not success',
    (tester) async {
      final store = TestStore();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(documentChannel, (call) async {
            expect(call.method, 'exportFile');
            expect(call.arguments['bytes'], store.bytes);
            expect(call.arguments['name'], 'teste.pdf');
            return false;
          });
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailsPage(
            store: store,
            item: VaultDocument(
              id: '1',
              type: 'Passaporte',
              title: 'Teste',
              createdAt: DateTime(2026),
              attachmentFile: 'existing.karta',
              attachmentName: 'teste.pdf',
              attachmentMime: 'application/pdf',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cópia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Cópia guardada.'), findsNothing);
      expect(find.text('Guardar cópia'), findsOneWidget);
    },
  );
  testWidgets(
    'file sharing requires consent and sends the selected PDF to the native chooser',
    (tester) async {
      final store = TestStore();
      var shared = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(documentChannel, (call) async {
            expect(call.method, 'shareFile');
            expect(call.arguments['bytes'], store.bytes);
            expect(call.arguments['mime'], 'application/pdf');
            shared++;
            return null;
          });
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailsPage(
            store: store,
            item: VaultDocument(
              id: '1',
              type: 'Passaporte',
              title: 'Teste',
              createdAt: DateTime(2026),
              attachmentFile: 'existing.karta',
              attachmentName: 'teste.pdf',
              attachmentMime: 'application/pdf',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partilhar ficheiro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(shared, 0);
      await tester.tap(find.text('Partilhar ficheiro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(shared, 1);
      expect(find.text('Cópia guardada.'), findsNothing);
    },
  );
}
