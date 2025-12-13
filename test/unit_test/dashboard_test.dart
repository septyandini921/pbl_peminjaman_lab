import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pbl_peminjaman_lab/service/booking_service.dart';
import 'package:pbl_peminjaman_lab/service/lab_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late BookingService bookingService;
  late LabService labService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    bookingService = BookingService.testConstructor(firestore: firestore);
    labService = LabService.testConstructor(firestore: firestore);

    await firestore.collection('Labs').doc('1').set({
      'lab_kode': 'LAB001',
      'lab_name': 'Lab Multimedia',
      'lab_location': 'Gedung A',
      'lab_description': 'Lab Multimedia',
      'lab_capacity': 30,
      'is_show': true,
    });

    await firestore.collection('Slots').doc('slot1').set({
      'slot_code': 'LAB001/S001',
      'slot_name': 'Slot Pagi',
      'lab_ref': firestore.doc('Labs/1'),
      'slot_start': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      'slot_end': Timestamp.fromDate(DateTime.now()),
      'is_booked': true,
      'is_open': true,
    });
  });

  group('BookingService Tests - Dashboard - Weekly Statistics', () {
    test(
        'Admin dapat melihat jumlah semua pengajuan booking dalam 7 hari terakhir',
        () async {
      print('Creating booking for weekly count test...');
      await firestore.collection('Booking').add({
        'is_confirmed': false,
        'is_rejected': false,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
      });
      print('Booking created successfully for weekly count test');

      final result = await bookingService.getAllBookingsCountWeekly().first;

      expect(result, 1);
    });

    test(
        'Admin dapat melihat jumlah booking yang sudah dikonfirmasi (tidak direject)',
        () async {
      print('Creating confirmed booking for weekly statistics...');
      await firestore.collection('Booking').add({
        'is_confirmed': true,
        'is_rejected': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      print('Confirmed booking created successfully');

      final result = await bookingService.getConfirmedBookingsCountWeekly().first;

      expect(result, 1);
    });

    test('Admin dapat melihat lab yang paling sering dipinjam minggu ini',
        () async {
      print('Creating booking for most borrowed lab test...');
      await firestore.collection('Booking').add({
        'is_confirmed': true,
        'is_rejected': false,
        'slotId': firestore.doc('Slots/slot1'),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      print('Booking created successfully for most borrowed lab test');

      final result = await bookingService.getMostBorrowedLabWeekly().first;

      expect(result.containsKey('1'), true);
      expect(result['1'], 1);
    });
  });

  group('BookingService Tests - Dashboard - Data Filtering', () {
    test(
        'Booking yang dibuat lebih dari 7 hari tidak dihitung dalam total pengajuan mingguan',
        () async {
      print('Creating booking older than 7 days for filtering test...');
      await firestore.collection('Booking').add({
        'is_confirmed': false,
        'is_rejected': false,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
      });
      print('Old booking created successfully (10 days ago)');

      final result = await bookingService.getAllBookingsCountWeekly().first;

      expect(result, 0);
    });

    test('Booking yang direject tidak dihitung sebagai peminjaman yang dikonfirmasi',
        () async {
      print('Creating rejected booking for filtering test...');
      await firestore.collection('Booking').add({
        'is_confirmed': true,
        'is_rejected': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      print('Rejected booking created successfully');

      final result = await bookingService.getConfirmedBookingsCountWeekly().first;

      expect(result, 0);
    });
  });

  group('BookingService Tests - Dashboard - Data Integrity', () {
    test(
        'Booking tanpa slot reference tidak menyebabkan crash pada dashboard statistik',
        () async {
      print('Creating booking without slot reference for integrity test...');
      await firestore.collection('Booking').add({
        'is_confirmed': true,
        'is_rejected': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      print('Booking without slot reference created successfully');

      final result = await bookingService.getMostBorrowedLabWeekly().first;

      expect(result.isEmpty, true);
    });

    test(
        'Dashboard tetap menampilkan data kosong ketika tidak ada booking dalam 7 hari terakhir',
        () async {
      print('Testing dashboard with no bookings...');
      
      final total = await bookingService.getAllBookingsCountWeekly().first;
      final confirmed = await bookingService.getConfirmedBookingsCountWeekly().first;
      final mostBorrowed = await bookingService.getMostBorrowedLabWeekly().first;

      print('Dashboard results: total=$total, confirmed=$confirmed, mostBorrowed=$mostBorrowed');

      expect(total, 0);
      expect(confirmed, 0);
      expect(mostBorrowed.isEmpty, true);
    });
  });
}