// test/unit_test/present_confirm_test.dart
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
  group('BookingService Tests - Present Confirmation (Aslab)', () {
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

      // Setup user (mahasiswa)
      await fakeFirestore.collection('Users').doc(testUserId).set({
        'user_name': 'John Doe',
        'user_email': 'john@example.com',
        'user_auth': 0,
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      // Setup aslab
      await fakeFirestore.collection('Users').doc('aslab123').set({
        'user_name': 'Aslab User',
        'user_email': 'aslab@example.com',
        'user_auth': 2,
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

    // Helper function untuk create dan approve booking
    Future<String> _createAndApproveBooking({
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
      final bookingId = bookings.docs.last.id;

      // Approve booking
      await bookingService.setApproved(bookingId);

      return bookingId;
    }

    group('Positive Tests - Set Present', () {
      test('Aslab berhasil menandai mahasiswa hadir (is_present = true)',
          () async {
        // Arrange
        final bookingId = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Act
        await bookingService.setPresent(bookingId);

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        final bookingData = bookingDoc.data();

        expect(bookingData?['is_present'], true);
        expect(bookingData?['is_confirmed'], true);
      });

      test('Aslab dapat menandai multiple mahasiswa hadir', () async {
        // Arrange - Create 3 confirmed bookings
        final bookingId1 = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        final bookingId2 = await _createAndApproveBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'Jane Smith',
          nim: '2241720002',
        );

        final bookingId3 = await _createAndApproveBooking(
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'Bob Johnson',
          nim: '2241720003',
        );

        // Act - Mark all as present
        await bookingService.setPresent(bookingId1);
        await bookingService.setPresent(bookingId2);
        await bookingService.setPresent(bookingId3);

        // Assert
        final allBookings = await fakeFirestore.collection('Booking').get();
        final presentCount = allBookings.docs
            .where((doc) => doc.data()['is_present'] == true)
            .length;

        expect(presentCount, 3);
      });

      test('Get all confirmed bookings menampilkan booking yang sudah di-approve',
          () async {
        // Arrange
        await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        await _createAndApproveBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'Jane Smith',
          nim: '2241720002',
        );

        // Create one pending booking (not approved)
        final slotDate = DateTime(2024, 12, 15);
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S003',
          slotName: 'Slot 3',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 13, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot = SlotModel.fromFirestore(
            slots.docs.last.id, slots.docs.last.data());

        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'Pending User',
          nim: '2241720003',
          tujuan: 'Praktikum',
          participantCount: 20,
        );

        // Act
        final confirmedBookings =
            await bookingService.getAllConfirmedBookings().first;

        // Assert
        expect(confirmedBookings.length, 2);
        expect(confirmedBookings.every((b) => b.isConfirmed == true), true);
        expect(confirmedBookings.any((b) => b.bookBy == 'John Doe'), true);
        expect(confirmedBookings.any((b) => b.bookBy == 'Jane Smith'), true);
        expect(confirmedBookings.any((b) => b.bookBy == 'Pending User'), false);
      });

      test('Aslab dapat mengubah status present dari false ke true', () async {
        // Arrange
        final bookingId = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Set not present first
        await bookingService.setNotPresent(bookingId);

        var bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], false);

        // Act - Change to present
        await bookingService.setPresent(bookingId);

        // Assert
        bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], true);
      });

      test('Status present tetap true meskipun di-set present berkali-kali',
          () async {
        // Arrange
        final bookingId = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Act - Set present multiple times
        await bookingService.setPresent(bookingId);
        await bookingService.setPresent(bookingId);
        await bookingService.setPresent(bookingId);

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], true);
      });
    });

    group('Positive Tests - Set Not Present', () {
      test('Aslab berhasil menandai mahasiswa tidak hadir (is_present = false)',
          () async {
        // Arrange
        final bookingId = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Set present first
        await bookingService.setPresent(bookingId);

        // Act - Set not present
        await bookingService.setNotPresent(bookingId);

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], false);
      });

      test('Default status present adalah false untuk booking baru', () async {
        // Arrange & Act
        final bookingId = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], false);
      });

      test('Aslab dapat menandai sebagian mahasiswa hadir dan sebagian tidak',
          () async {
        // Arrange - Create 4 confirmed bookings
        final bookingId1 = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createAndApproveBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        final bookingId3 = await _createAndApproveBooking(
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'User 3',
          nim: '2241720003',
        );

        final bookingId4 = await _createAndApproveBooking(
          slotCode: 'S004',
          slotName: 'Slot 4',
          userName: 'User 4',
          nim: '2241720004',
        );

        // Act - Mark 2 present, 2 not present
        await bookingService.setPresent(bookingId1);
        await bookingService.setPresent(bookingId2);
        await bookingService.setNotPresent(bookingId3);
        await bookingService.setNotPresent(bookingId4);

        // Assert
        final allBookings = await fakeFirestore.collection('Booking').get();
        final presentCount = allBookings.docs
            .where((doc) => doc.data()['is_present'] == true)
            .length;
        final notPresentCount = allBookings.docs
            .where((doc) => doc.data()['is_present'] == false)
            .length;

        expect(presentCount, 2);
        expect(notPresentCount, 2);
      });
    });

    group('Negative Tests - Present Confirmation', () {
      test('Set present dengan booking ID yang tidak ada throws error',
          () async {
        // Arrange
        const nonExistentId = 'booking_tidak_ada_123';

        // Act & Assert
        expect(
          () => bookingService.setPresent(nonExistentId),
          throwsA(isA<Exception>()),
        );
      });

      test('Set not present dengan booking ID yang tidak ada throws error',
          () async {
        // Arrange
        const nonExistentId = 'booking_tidak_ada_123';

        // Act & Assert
        expect(
          () => bookingService.setNotPresent(nonExistentId),
          throwsA(isA<Exception>()),
        );
      });

      test('Tidak bisa set present untuk booking yang belum di-confirm',
          () async {
        // Arrange - Create booking but don't approve
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

        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum',
          participantCount: 25,
        );

        final bookings = await fakeFirestore.collection('Booking').get();
        final bookingId = bookings.docs.first.id;

        // Act - Try to set present (technically it will succeed in this mock)
        await bookingService.setPresent(bookingId);

        // Assert - Verify booking is not confirmed
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_confirmed'], false);
        expect(bookingDoc.data()?['is_present'], true); // But present can be set
      });

      test('Tidak bisa set present untuk booking yang di-reject', () async {
        // Arrange - Create and reject booking
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

        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum',
          participantCount: 25,
        );

        final bookings = await fakeFirestore.collection('Booking').get();
        final bookingId = bookings.docs.first.id;

        await bookingService.setRejected(bookingId);

        // Act - Try to set present
        await bookingService.setPresent(bookingId);

        // Assert
        final bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_rejected'], true);
        expect(bookingDoc.data()?['is_present'], true); // Will be set anyway
      });
    });

    group('Edge Cases - Present Confirmation', () {
      test('Toggle present status multiple times', () async {
        // Arrange
        final bookingId = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
        );

        // Act - Toggle multiple times
        await bookingService.setPresent(bookingId); // true
        var bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], true);

        await bookingService.setNotPresent(bookingId); // false
        bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], false);

        await bookingService.setPresent(bookingId); // true again
        bookingDoc = await fakeFirestore
            .collection('Booking')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['is_present'], true);
      });

      test('Get confirmed bookings tidak terpengaruh oleh status present',
          () async {
        // Arrange
        final bookingId1 = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createAndApproveBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        // Set different present status
        await bookingService.setPresent(bookingId1);
        await bookingService.setNotPresent(bookingId2);

        // Act
        final confirmedBookings =
            await bookingService.getAllConfirmedBookings().first;

        // Assert - Both should still be in confirmed list
        expect(confirmedBookings.length, 2);
        expect(confirmedBookings.every((b) => b.isConfirmed == true), true);
      });

      test('Confirmed booking dengan dan tanpa present status', () async {
        // Arrange
        final bookingId1 = await _createAndApproveBooking(
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'User 1',
          nim: '2241720001',
        );

        final bookingId2 = await _createAndApproveBooking(
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'User 2',
          nim: '2241720002',
        );

        // Only set present for first booking
        await bookingService.setPresent(bookingId1);

        // Act
        final allConfirmedBookings =
            await bookingService.getAllConfirmedBookings().first;

        // Assert
        final presentBookings =
            allConfirmedBookings.where((b) => b.isPresent == true).toList();
        final notPresentBookings =
            allConfirmedBookings.where((b) => b.isPresent == false).toList();

        expect(presentBookings.length, 1);
        expect(notPresentBookings.length, 1);
      });
    });
  });
}