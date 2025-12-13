// C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\test\unit_test\crash_book_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pbl_peminjaman_lab/service/booking_service.dart';
import 'package:pbl_peminjaman_lab/models/labs/lab_model.dart';
import 'package:pbl_peminjaman_lab/models/slots/slot_model.dart';

void main() {
  group(
    'BookingService Tests - Edge Case - Crash Booking (Concurrent Booking)',
    () {
      late FakeFirebaseFirestore firestore;
      late BookingService bookingService;

      late LabModel lab;
      late SlotModel slot;

      setUp(() async {
        print('Setting up test environment for crash booking test...');
        firestore = FakeFirebaseFirestore();
        bookingService =
            BookingService.testConstructor(firestore: firestore);

        // ===== SETUP LAB =====
        print('Setting up lab data...');
        await firestore.collection('Labs').doc('LAB001').set({
          'lab_kode': 'LAB001',
          'lab_name': 'Lab Komputer',
          'lab_location': 'Gedung A',
          'lab_description': 'Lab Komputer dengan 30 PC',
          'lab_capacity': 30,
          'is_show': true,
        });

        // Create LabModel object properly
        lab = LabModel(
          id: 'LAB001',
          labKode: 'LAB001',
          labName: 'Lab Komputer',
          labLocation: 'Gedung A',
          labDescription: 'Lab Komputer dengan 30 PC',
          labCapacity: 30,
          isShow: true,
        );

        // ===== SETUP SLOT =====
        print('Setting up slot data...');
        final labRef = firestore.doc('Labs/LAB001');
        
        await firestore.collection('Slots').doc('SLOT001').set({
          'slot_code': 'LAB001/S001',
          'slot_name': 'Slot Pagi',
          'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 08, 00)),
          'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 00)),
          'lab_ref': labRef,
          'is_booked': false,
          'is_open': true,
        });

        // Create SlotModel object properly
        slot = SlotModel(
          id: 'SLOT001',
          slotCode: 'LAB001/S001',
          slotName: 'Slot Pagi',
          labRef: labRef,
          slotStart: DateTime(2024, 12, 15, 08, 00),
          slotEnd: DateTime(2024, 12, 15, 10, 00),
          isBooked: false,
          isOpen: true,
        );
        
        print('Test environment setup complete');
      });

      test(
        'Crash Booking - Dua booking dilakukan di waktu yang benar-benar bersamaan, hanya satu yang berhasil',
        () async {
          print('Starting crash booking test...');
          print('Testing concurrent booking by User A and User B');
          
          print('Initiating parallel booking requests...');
          // Jalankan DUA booking SECARA PARALEL
          final results = await Future.wait([
            bookingService.createBooking(
              lab: lab,
              slot: slot,
              userId: 'user_1',
              nama: 'User A',
              nim: '123456',
              tujuan: 'Praktikum Basis Data',
              participantCount: 10,
            ),
            bookingService.createBooking(
              lab: lab,
              slot: slot,
              userId: 'user_2',
              nama: 'User B',
              nim: '654321',
              tujuan: 'Praktikum Basis Data',
              participantCount: 12,
            ),
          ]);

          print('Parallel booking results:');
          print('Result 1 (User A): ${results[0]}');
          print('Result 2 (User B): ${results[1]}');

          // ===== ASSERTION =====
          final successCount =
              results.where((r) => r == "SUCCESS").length;
          final failedCount =
              results.where((r) => r == "SLOT_TIDAK_TERSEDIA").length;

          print('Success count: $successCount');
          print('Failed count: $failedCount');

          expect(successCount, 1, reason: 'Should have exactly 1 successful booking');
          expect(failedCount, 1, reason: 'Should have exactly 1 failed booking due to slot unavailability');

          // ===== VALIDASI DATABASE =====
          print('Validating database state...');
          final bookingSnapshot =
              await firestore.collection('Booking').get();

          // Pastikan hanya 1 booking yang tersimpan
          print('Total bookings in database: ${bookingSnapshot.docs.length}');
          expect(bookingSnapshot.docs.length, 1, 
              reason: 'Should have exactly 1 booking in database');

          final bookingData = bookingSnapshot.docs.first.data();
          
          print('Booking details:');
          print('- Book Code: ${bookingData['book_code']}');
          print('- Booked By: ${bookingData['book_by']}');
          print('- NIM: ${bookingData['book_nim']}');
          print('- Is Rejected: ${bookingData['is_rejected']}');
          print('- Is Confirmed: ${bookingData['is_confirmed']}');

          expect(bookingData['is_rejected'], false, reason: 'Booking should not be rejected');
          expect(bookingData['is_confirmed'], false, reason: 'Booking should be pending (not confirmed yet)');
          expect(bookingData['slotId'], isNotNull, reason: 'Slot reference should exist');
          
          // Verify slot status was updated
          final slotDoc = await firestore.collection('Slots').doc('SLOT001').get();
          final slotData = slotDoc.data();
          
          if (slotData != null) {
            print('Slot status after booking:');
            print('- Slot ID: SLOT001');
            print('- Is Booked: ${slotData['is_booked']}');
            print('- Is Open: ${slotData['is_open']}');
          }

          print('Crash booking test completed successfully');
          print('Test result: One booking succeeded, one failed as expected');
        },
      );

      test(
        'Concurrent booking dengan delay - hanya booking pertama yang sukses',
        () async {
          print('Starting delayed concurrent booking test...');
          
          // Test dengan sedikit delay di antara bookings
          print('Starting first booking...');
          final firstResult = await bookingService.createBooking(
            lab: lab,
            slot: slot,
            userId: 'user_1',
            nama: 'User A',
            nim: '123456',
            tujuan: 'Praktikum Algoritma',
            participantCount: 15,
          );
          
          print('First booking result: $firstResult');
          
          // Tunggu sebentar (simulasi delay)
          await Future.delayed(const Duration(milliseconds: 100));
          
          print('Starting second booking...');
          final secondResult = await bookingService.createBooking(
            lab: lab,
            slot: slot,
            userId: 'user_2',
            nama: 'User B',
            nim: '654321',
            tujuan: 'Praktikum Struktur Data',
            participantCount: 20,
          );
          
          print('Second booking result: $secondResult');
          
          expect(firstResult, "SUCCESS", reason: 'First booking should succeed');
          expect(secondResult, "SLOT_TIDAK_TERSEDIA", reason: 'Second booking should fail - slot already booked');
          
          print('Delayed concurrent booking test completed');
        },
      );

      test(
        'Multiple concurrent bookings (3 users) - hanya satu yang sukses',
        () async {
          print('Starting test with 3 concurrent users...');
          
          print('Initiating 3 parallel booking requests...');
          final results = await Future.wait([
            bookingService.createBooking(
              lab: lab,
              slot: slot,
              userId: 'user_1',
              nama: 'User A',
              nim: '111111',
              tujuan: 'Praktikum 1',
              participantCount: 10,
            ),
            bookingService.createBooking(
              lab: lab,
              slot: slot,
              userId: 'user_2',
              nama: 'User B',
              nim: '222222',
              tujuan: 'Praktikum 2',
              participantCount: 12,
            ),
            bookingService.createBooking(
              lab: lab,
              slot: slot,
              userId: 'user_3',
              nama: 'User C',
              nim: '333333',
              tujuan: 'Praktikum 3',
              participantCount: 8,
            ),
          ]);

          print('Results for 3 concurrent bookings:');
          for (int i = 0; i < results.length; i++) {
            print('User ${i + 1}: ${results[i]}');
          }

          final successCount = results.where((r) => r == "SUCCESS").length;
          final failedCount = results.where((r) => r == "SLOT_TIDAK_TERSEDIA").length;

          print('Success count: $successCount');
          print('Failed count: $failedCount');

          expect(successCount, 1, reason: 'Should have exactly 1 successful booking');
          expect(failedCount, 2, reason: 'Should have exactly 2 failed bookings');
          
          print('Three-user concurrent booking test completed');
        },
      );

      test(
        'Booking setelah slot di-reject masih bisa digunakan',
        () async {
          print('Starting test: Booking after rejection...');
          
          // Buat booking pertama
          print('Creating first booking...');
          final firstBooking = await bookingService.createBooking(
            lab: lab,
            slot: slot,
            userId: 'user_1',
            nama: 'User A',
            nim: '111111',
            tujuan: 'Praktikum',
            participantCount: 10,
          );
          
          print('First booking result: $firstBooking');
          expect(firstBooking, "SUCCESS", reason: 'First booking should succeed');
          
          // Dapatkan booking ID
          final bookingSnapshot = await firestore.collection('Booking').get();
          final bookingId = bookingSnapshot.docs.first.id;
          print('Booking ID: $bookingId');
          
          // Reject booking pertama
          print('Rejecting first booking...');
          final slotId = await bookingService.setRejected(bookingId);
          print('Rejection completed, affected slot ID: $slotId');
          
          // Coba booking lagi dengan user berbeda
          print('Attempting second booking after rejection...');
          final secondBooking = await bookingService.createBooking(
            lab: lab,
            slot: slot,
            userId: 'user_2',
            nama: 'User B',
            nim: '222222',
            tujuan: 'Praktikum Lain',
            participantCount: 15,
          );
          
          print('Second booking result: $secondBooking');
          expect(secondBooking, "SUCCESS", reason: 'Should succeed because previous booking was rejected');
          
          print('Booking after rejection test completed');
        },
      );
    },
  );
}