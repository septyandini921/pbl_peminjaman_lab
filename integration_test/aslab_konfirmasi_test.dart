import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl_peminjaman_lab/main.dart' as app;
import 'package:flutter/material.dart';

Future<void> scrollUntilFind(
  WidgetTester tester,
  Finder item, {
  double scrollDistance = 300,
  int maxScroll = 40,
}) async {
  final scrollables = find.byType(Scrollable);

  if (scrollables.evaluate().isEmpty) {
    throw Exception("Tidak ada Scrollable di layar!");
  }

  final targetScrollable = scrollables.last;
  int attempts = 0;

  while (tester.widgetList(item).isEmpty && attempts < maxScroll) {
    await tester.drag(targetScrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    attempts++;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Aslab Konfirmasi Kehadiran - Integration Test', () {
    testWidgets('Mahasiswa berhasil konfirmasi kehadiran',
        (WidgetTester tester) async {
      app.main();
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      final welcomeScreen = find.byKey(const Key('welcome_screen'));
      int attempts = 0;

      while (tester.widgetList(welcomeScreen).isEmpty && attempts < 50) {
        await tester.pump(const Duration(milliseconds: 100));
        attempts++;
      }

      final signInBtn = find.byKey(const Key('welcome_signin'));
      if (tester.widgetList(signInBtn).isNotEmpty) {
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();
      }

      /// ============================================================
      /// LOGIN
      /// ============================================================
      final emailField = find.byKey(const Key('login_email'));
      attempts = 0;

      while (tester.widgetList(emailField).isEmpty && attempts < 50) {
        await tester.pump(const Duration(milliseconds: 100));
        attempts++;
      }

      await tester.enterText(emailField, 'aslab@gmail.com');
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'aslab123',
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      /// ============================================================
      /// HOME SCREEN
      /// ============================================================
      final homeScreen = find.byKey(const Key('home_screen'));
      attempts = 0;

      while (tester.widgetList(homeScreen).isEmpty && attempts < 50) {
        await tester.pump(const Duration(milliseconds: 100));
        attempts++;
      }

      expect(homeScreen, findsOneWidget);

      /// ============================================================
      /// MASUK TAB JADWAL
      /// ============================================================
      await tester.tap(find.byKey(const Key('bottomnav_jadwal')));
      await tester.pumpAndSettle();

      /// ============================================================
      /// FILTER TANGGAL
      /// ============================================================
      final datePicker = find.byKey(const Key('tanggal_picker'));
      expect(datePicker, findsOneWidget);

      await tester.tap(datePicker);
      await tester.pumpAndSettle();

      await tester.tap(find.text(DateTime.now().day.toString()));
      await tester.pumpAndSettle();

      if (tester.widgetList(find.text("OK")).isNotEmpty) {
        await tester.tap(find.text("OK"));
      }
      await tester.pumpAndSettle();

      /// ============================================================
      /// CARI CARD "TIDAK HADIR"
      /// ============================================================
      final statusTidakHadir = find.text("Kehadiran: Tidak Hadir");

      await tester.scrollUntilVisible(
        statusTidakHadir,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final bookingCard = find.ancestor(
        of: statusTidakHadir.first,
        matching: find.byType(Card),
      );
      expect(bookingCard, findsOneWidget);

      /// ============================================================
      /// MASUK DETAIL
      /// ============================================================
      await tester.tap(bookingCard);
      await tester.pumpAndSettle();

      expect(find.text("Detail Peminjaman"), findsOneWidget);

      /// ============================================================
      /// KONFIRMASI HADIR
      /// ============================================================
      final btnHadir = find.byKey(const Key('btn_hadir'));

      await tester.scrollUntilVisible(
        btnHadir,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      await tester.tap(btnHadir);
      await tester.pumpAndSettle();

      final dialogYes = find.byKey(const Key('dialog_yes'));
      if (tester.widgetList(dialogYes).isNotEmpty) {
        await tester.tap(dialogYes);
        await tester.pumpAndSettle();
      }

      /// ============================================================
      /// 🔥 FORCE RELOAD LIST (TANPA pageBack)
      /// ============================================================
      await tester.tap(find.byKey(const Key('bottomnav_home')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottomnav_jadwal')));
      await tester.pumpAndSettle();

      /// ============================================================
      /// VERIFIKASI STATUS HADIR
      /// ============================================================
      final statusHadir = find.text("Kehadiran: Hadir");
      attempts = 0;

      while (tester.widgetList(statusHadir).isEmpty && attempts < 30) {
        await tester.pump(const Duration(milliseconds: 300));
        attempts++;
      }

      expect(statusHadir, findsWidgets);
    });
  });
}
