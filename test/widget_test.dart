// BYM 360 - Basic Widget Test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bym360/main.dart';

import 'package:bym360/models/models.dart';
import 'package:bym360/services/document_preview_service.dart';

void main() {
  testWidgets('BYM 360 app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Bym360App());

    // Verify the app renders with the title.
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('Test PDF generation with Turkish characters', () async {
    final bytes = await DocumentPreviewService.generateBelgePdf(
      belgeNo: 'M2-000001022',
      belgeTuru: 'Depo Sevk Fişi',
      cariAdi: 'Şirinevler Şubesi / İbrahim Çelik',
      tarih: '12.08.2026 17:31:00',
      genelToplam: 9712.50,
      urunler: [
        GetBelgeIcerik(
          satirId: 1,
          belgeId: 1022,
          stokId: 244,
          stokKodu: '00244',
          stokAdi: 'DOMATES İTHAL SARI',
          barkod: '6256763857045',
          miktar: 85,
          birim: 'KG',
          birimFiyat: 100,
          tutar: 8500,
        ),
      ],
      paperFormat: '80mm',
      aciklama: 'Örnek açıklama Türkçe: Ş, Ğ, Ç, Ö, Ü, İ',
    );
    expect(bytes.isNotEmpty, true);

    final bytesA4 = await DocumentPreviewService.generateBelgePdf(
      belgeNo: 'M2-000001022',
      belgeTuru: 'Depo Sevk Fişi',
      cariAdi: 'Şirinevler Şubesi / İbrahim Çelik',
      tarih: '12.08.2026 17:31:00',
      genelToplam: 9712.50,
      urunler: [
        GetBelgeIcerik(
          satirId: 1,
          belgeId: 1022,
          stokId: 244,
          stokKodu: '00244',
          stokAdi: 'DOMATES İTHAL SARI',
          barkod: '6256763857045',
          miktar: 85,
          birim: 'KG',
          birimFiyat: 100,
          tutar: 8500,
        ),
      ],
      paperFormat: 'A4',
      aciklama: 'Örnek açıklama Türkçe: Ş, Ğ, Ç, Ö, Ü, İ',
    );
    expect(bytesA4.isNotEmpty, true);
  });
}
