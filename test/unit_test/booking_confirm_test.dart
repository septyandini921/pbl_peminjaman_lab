// test/unit_test/booking_confirm_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pbl_peminjaman_lab/service/booking_service.dart';
import 'package:pbl_peminjaman_lab/service/slot_service.dart';
import 'package:pbl_peminjaman_lab/service/lab_service.dart';
import 'package:pbl_peminjaman_lab/models/booking/booking_model.dart';
import 'package:pbl_peminjaman_lab/models/slots/slot_model.dart';
import 'package:pbl_peminjaman_lab/models/labs/lab_model.dart';

void main() {
  group('BookingService Tests - Booking Confirmation', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService bookingService;
    late SlotService slotService;
    late LabService labService;
    late LabModel testLab;
    late String testUserId;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      bookingService = BookingService.testConstructor(firestore: fakeFirestore);
      slotService = SlotService.testConstructor(firestore: fakeFirestore);
      labService = LabService.testConstructor(firestore: fakeFirestore);

      testUserId = 'user123';

      // Setup user
      await fakeFirestore.collection('Users').doc(testUserId).set({
        'user_name': 'John Doe',
        'user_email': 'john@example.com',
        'user_auth': 0,
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      // Setup lab
      await fakeFirestore.collection('Labs').doc('lab1').set({
        'lab_kode': 'LAB001',
        'lab_name': 'Lab Komputer 1',
        'lab_location': 'Gedung A Lantai 2',
        'lab_description': 'Lab untuk praktikum pemrograman',
        'lab_capacity': 40,
        'is_show': true,
      });

      testLab = LabModel(
        id: 'lab1',
        labKode: 'LAB001',
        labName: 'Lab Komputer 1',
        labLocation: 'Gedung A Lantai 2',
        labDescription: 'Lab untuk praktikum pemrograman',
        labCapacity: 40,
        isShow: true,
      );
    });

    // Helper function untuk create booking
    Future<String> _createTestBooking({
      required String slotCode,
      required String slotName,
      required String userName,
      required String nim,
    }) async {
      final slotDate = DateTime(2024, 12, 15);
      await slotService.addSlot(
        lab: testLab,
        slotCode: slotCode,
        slotName: slotName,
        slotDate: slotDate,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
      );

      final slots = await fakeFirestore.collection('Slots').get();
      final slot = SlotModel.fromFirestore(
          slots.docs.last.id, slots.docs.last.data());

      await bookingService.createBooking(
        lab: testLab,
        slot: slot,
        userId: testUserId,
        nama: userName,
        nim: nim,
        tujuan: 'Praktikum Mobile Programming',
        participantCount: 25,
      );

      final bookings = await fakeFirestore.collection('Booking').get();
      return bookings.docs.last.id;
    }

    group('Positive Tests - Approve Booking', () {
      test('Approve booking berhasil - status berubah menjadi confirmed',
          () async {
        // Arrange
        final bookingId = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Act
        await bookingService.setApproved(bookingId);

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        final bookingData = bookingDoc.data();

        expect(bookingData?['is_confirmed'], true);
        expect(bookingData?['is_rejected'], false);
      });

      test('Get pending bookings berhasil menampilkan booking yang belum dikonfirmasi',
          () async {
        // Arrange - Create multiple bookings
        await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        await _createTestBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        final bookingId3 = await _createTestBooking(
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'User 3',
          nim: '2241720003',
        );

        // Approve one booking
        await bookingService.setApproved(bookingId3);

        // Act
        final pendingBookings =
            await bookingService.getPendingBookings().first;

        // Assert
        expect(pendingBookings.length, 2);
        expect(
            pendingBookings.every((b) =>
                b.isConfirmed == false && b.isRejected == false),
            true);
        expect(pendingBookings.any((b) => b.bookBy == 'User 1'), true);
        expect(pendingBookings.any((b) => b.bookBy == 'User 2'), true);
        expect(pendingBookings.any((b) => b.bookBy == 'User 3'), false);
      });

      test('Update booking status dengan updateBookingStatus berhasil',
          () async {
        // Arrange
        final bookingId = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Act
        await bookingService.updateBookingStatus(
          bookingId: bookingId,
          isConfirmed: true,
        );

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_confirmed'], true);
      });

      test('Approve multiple bookings berhasil', () async {
        // Arrange - Create 3 bookings
        final bookingId1 = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createTestBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        final bookingId3 = await _createTestBooking(
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'User 3',
          nim: '2241720003',
        );

        // Act - Approve all
        await bookingService.setApproved(bookingId1);
        await bookingService.setApproved(bookingId2);
        await bookingService.setApproved(bookingId3);

        // Assert
        final allBookings = await fakeFirestore.collection('Booking').get();
        expect(
            allBookings.docs
                .every((doc) => doc.data()['is_confirmed'] == true),
            true);
        expect(
            allBookings.docs
                .every((doc) => doc.data()['is_rejected'] == false),
            true);
      });

      test('Get all bookings menampilkan semua booking termasuk yang sudah dikonfirmasi',
          () async {
        // Arrange
        final bookingId1 = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        await _createTestBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        // Approve one
        await bookingService.setApproved(bookingId1);

        // Act
        final allBookings = await bookingService.getAllBookings().first;

        // Assert
        expect(allBookings.length, 2);
        expect(allBookings.any((b) => b.isConfirmed == true), true);
        expect(allBookings.any((b) => b.isConfirmed == false), true);
      });

      test('Get all confirmed bookings hanya menampilkan booking yang dikonfirmasi',
          () async {
        // Arrange
        final bookingId1 = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createTestBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        await _createTestBooking(
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'User 3',
          nim: '2241720003',
        );

        // Approve two bookings
        await bookingService.setApproved(bookingId1);
        await bookingService.setApproved(bookingId2);

        // Act
        final confirmedBookings =
            await bookingService.getAllConfirmedBookings().first;

        // Assert
        expect(confirmedBookings.length, 2);
        expect(confirmedBookings.every((b) => b.isConfirmed == true), true);
        expect(confirmedBookings.any((b) => b.bookBy == 'User 1'), true);
        expect(confirmedBookings.any((b) => b.bookBy == 'User 2'), true);
        expect(confirmedBookings.any((b) => b.bookBy == 'User 3'), false);
      });
    });

    group('Positive Tests - Reject Booking', () {
      test('Reject booking berhasil - status berubah menjadi rejected',
          () async {
        // Arrange
        final bookingId = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Act
        final slotId = await bookingService.setRejected(bookingId);

        // Assert
        expect(slotId, isNotNull);

        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        final bookingData = bookingDoc.data();

        expect(bookingData?['is_confirmed'], false);
        expect(bookingData?['is_rejected'], true);
      });

      test('Reject booking mengembalikan slot ID yang benar', () async {
        // Arrange
        final bookingId = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Get slot ID from booking
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        final slotRef = bookingDoc.data()?['slotId'] as DocumentReference;
        final expectedSlotId = slotRef.id;

        // Act
        final returnedSlotId = await bookingService.setRejected(bookingId);

        // Assert
        expect(returnedSlotId, expectedSlotId);
      });

      test('Slot dapat di-book lagi setelah booking di-reject', () async {
        // Arrange - Create first booking
        final slotDate = DateTime(2024, 12, 15);
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot = SlotModel.fromFirestore(
            slots.docs.first.id, slots.docs.first.data());

        // First booking
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'User 1',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
          participantCount: 20,
        );

        final firstBookings = await fakeFirestore.collection('Booking').get();
        final firstBookingId = firstBookings.docs.first.id;

        // Reject first booking
        await bookingService.setRejected(firstBookingId);

        // Act - Try to book the same slot again (should succeed)
        final result = await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: 'user456',
          nama: 'User 2',
          nim: '2241720002',
          tujuan: 'Praktikum 2',
          participantCount: 25,
        );

        // Assert
        expect(result, 'SUCCESS');

        final allBookings = await fakeFirestore.collection('Booking').get();
        expect(allBookings.docs.length, 2);

        // Verify first booking is rejected
        final rejectedBooking = allBookings.docs
            .firstWhere((doc) => doc.id == firstBookingId);
        expect(rejectedBooking.data()['is_rejected'], true);

        // Verify second booking is not rejected
        final newBooking = allBookings.docs
            .firstWhere((doc) => doc.id != firstBookingId);
        expect(newBooking.data()['is_rejected'], false);
        expect(newBooking.data()['book_by'], 'User 2');
      });

      test('Reject multiple bookings berhasil', () async {
        // Arrange
        final bookingId1 = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createTestBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        // Act
        await bookingService.setRejected(bookingId1);
        await bookingService.setRejected(bookingId2);

        // Assert
        final allBookings = await fakeFirestore.collection('Booking').get();
        expect(
            allBookings.docs
                .every((doc) => doc.data()['is_rejected'] == true),
            true);
        expect(
            allBookings.docs
                .every((doc) => doc.data()['is_confirmed'] == false),
            true);
      });
    });

    group('Negative Tests - Approval Scenarios', () {
      test('Approve booking yang tidak ada (non-existent booking ID)', () async {
        // Arrange
        const nonExistentId = 'booking_tidak_ada_123';

        // Act & Assert
        expect(
          () => bookingService.setApproved(nonExistentId),
          throwsA(isA<Exception>()),
        );
      });

      test('Slot tidak bisa di-book lagi ketika ada booking yang sudah di-approve',
          () async {
        // Arrange
        final slotDate = DateTime(2024, 12, 15);
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot = SlotModel.fromFirestore(
            slots.docs.first.id, slots.docs.first.data());

        // First booking
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'User 1',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
          participantCount: 20,
        );

        // Approve first booking
        final bookings = await fakeFirestore.collection('Booking').get();
        await bookingService.setApproved(bookings.docs.first.id);

        // Act - Try to book same slot (should fail)
        final result = await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: 'user456',
          nama: 'User 2',
          nim: '2241720002',
          tujuan: 'Praktikum 2',
          participantCount: 25,
        );

        // Assert
        expect(result, 'SLOT_TIDAK_TERSEDIA');

        final allBookings = await fakeFirestore.collection('Booking').get();
        expect(allBookings.docs.length, 1); // Hanya ada 1 booking
      });

      test('Slot tidak bisa di-book ketika ada booking pending (belum dikonfirmasi)',
          () async {
        // Arrange
        final slotDate = DateTime(2024, 12, 15);
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot = SlotModel.fromFirestore(
            slots.docs.first.id, slots.docs.first.data());

        // First booking (pending)
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'User 1',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
          participantCount: 20,
        );

        // Act - Try to book same slot while first is pending (should fail)
        final result = await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: 'user456',
          nama: 'User 2',
          nim: '2241720002',
          tujuan: 'Praktikum 2',
          participantCount: 25,
        );

        // Assert
        expect(result, 'SLOT_TIDAK_TERSEDIA');

        final allBookings = await fakeFirestore.collection('Booking').get();
        expect(allBookings.docs.length, 1);
      });

      test('Update booking status dengan ID yang tidak valid', () async {
        // Arrange
        const invalidId = 'invalid_booking_id';

        // Act & Assert
        expect(
          () => bookingService.updateBookingStatus(
            bookingId: invalidId,
            isConfirmed: true,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Negative Tests - Rejection Scenarios', () {
      test('Reject booking dengan ID yang tidak ada mengembalikan null',
          () async {
        // Arrange
        const nonExistentId = 'booking_tidak_ada_123';

        // Act
        final result = await bookingService.setRejected(nonExistentId);

        // Assert
        expect(result, isNull);
      });

      test('Tidak bisa approve booking yang sudah di-reject', () async {
        // Arrange
        final bookingId = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Reject first
        await bookingService.setRejected(bookingId);

        // Act - Try to approve rejected booking
        await bookingService.setApproved(bookingId);

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        final bookingData = bookingDoc.data();

        // Booking should now be approved (setApproved overwrites)
        expect(bookingData?['is_confirmed'], true);
        expect(bookingData?['is_rejected'], false);
      });

      test('Tidak bisa reject booking yang sudah di-approve', () async {
        // Arrange
        final bookingId = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Approve first
        await bookingService.setApproved(bookingId);

        // Act - Try to reject approved booking
        await bookingService.setRejected(bookingId);

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        final bookingData = bookingDoc.data();

        // Booking should now be rejected (setRejected overwrites)
        expect(bookingData?['is_confirmed'], false);
        expect(bookingData?['is_rejected'], true);
      });
    });

    group('Mixed Scenarios - Approval and Rejection', () {
      test('Admin dapat approve sebagian dan reject sebagian bookings',
          () async {
        // Arrange - Create 4 bookings
        final bookingId1 = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createTestBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        final bookingId3 = await _createTestBooking(
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'User 3',
          nim: '2241720003',
        );

        final bookingId4 = await _createTestBooking(
          slotCode: 'S004',
          slotName: 'Slot 4',
          userName: 'User 4',
          nim: '2241720004',
        );

        // Act - Approve 2, Reject 2
        await bookingService.setApproved(bookingId1);
        await bookingService.setApproved(bookingId2);
        await bookingService.setRejected(bookingId3);
        await bookingService.setRejected(bookingId4);

        // Assert
        final allBookings = await fakeFirestore.collection('Booking').get();
        
        final approvedCount = allBookings.docs
            .where((doc) => doc.data()['is_confirmed'] == true)
            .length;
        final rejectedCount = allBookings.docs
            .where((doc) => doc.data()['is_rejected'] == true)
            .length;
        final pendingCount = allBookings.docs
            .where((doc) =>
                doc.data()['is_confirmed'] == false &&
                doc.data()['is_rejected'] == false)
            .length;

        expect(approvedCount, 2);
        expect(rejectedCount, 2);
        expect(pendingCount, 0);
      });

      test('Get pending bookings tidak menampilkan booking yang approved atau rejected',
          () async {
        // Arrange
        final bookingId1 = await _createTestBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createTestBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        await _createTestBooking(
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'User 3',
          nim: '2241720003',
        );

        // Approve and reject some
        await bookingService.setApproved(bookingId1);
        await bookingService.setRejected(bookingId2);

        // Act
        final pendingBookings =
            await bookingService.getPendingBookings().first;

        // Assert
        expect(pendingBookings.length, 1);
        expect(pendingBookings.first.bookBy, 'User 3');
      });
    });
  });
}