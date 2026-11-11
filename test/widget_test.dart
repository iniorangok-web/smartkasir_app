
import 'package:flutter_test/flutter_test.dart';
import 'package:smartkasir_app/main.dart';

void main() {
  testWidgets(
    'SmartKasir dapat dijalankan',
    (WidgetTester tester) async {
      // Menjalankan aplikasi SmartKasir
      await tester.pumpWidget(const SmartKasirApp());

      // Menunggu proses rendering aplikasi
      await tester.pumpAndSettle();

      // Memastikan halaman SmartKasir berhasil ditampilkan
      expect(find.text('SmartKasir'), findsWidgets);
    },
  );
}
