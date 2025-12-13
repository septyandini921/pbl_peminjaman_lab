// test/unit_test/booking_test.dart
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
  group('BookingService Tests - Booking Focus', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService bookingService;
    late SlotService slotService;
    late LabService labService;
    late LabModel testLab;
    late DocumentReference testLabRef;
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

      testLabRef = fakeFirestore.doc('Labs/lab1');
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

    group('Positive Tests - Create Booking', () {
      test('Create booking berhasil dengan slot tersedia', () async {
        // Arrange - Tambahkan slot yang tersedia
        final slotDate = DateTime(2024, 12, 15);
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        // Get slot yang baru dibuat
        final slots = await fakeFirestore.collection('Slots').get();
        final slotDoc = slots.docs.first;
        final slot = SlotModel.fromFirestore(slotDoc.id, slotDoc.data());

        // Act - Create booking
        final result = await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile Programming',
          participantCount: 25,
        );

        // Assert
        expect(result, 'SUCCESS');

        // Verify booking tersimpan
        final bookings = await fakeFirestore.collection('Booking').get();
        expect(bookings.docs.length, 1);

        final bookingData = bookings.docs.first.data();
        expect(bookingData['book_by'], 'John Doe');
        expect(bookingData['book_nim'], '2241720001');
        expect(bookingData['book_purpose'], 'Praktikum Mobile Programming');
        expect(bookingData['participant_count'], 25);
        expect(bookingData['is_confirmed'], false);
        expect(bookingData['is_rejected'], false);
        expect(bookingData['is_present'], false);
      });

      test('Get slots for lab berhasil menampilkan slot pada tanggal tertentu',
          () async {
        // Arrange
        final targetDate = DateTime(2024, 12, 15);
        final otherDate = DateTime(2024, 12, 16);

        // Tambah slot pada tanggal target
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          slotDate: targetDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S002',
          slotName: 'Slot Siang 1',
          slotDate: targetDate,
          startTime: const TimeOfDay(hour: 13, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
        );

        // Tambah slot pada tanggal berbeda
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S003',
          slotName: 'Slot Pagi 2',
          slotDate: otherDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        // Act
        final slots = await bookingService.getSlotsForLab(
          lab: testLab,
          date: targetDate,
        );

        // Assert
        expect(slots.length, 2);
        expect(slots.every((slot) => slot.slotStart.day == 15), true);
      });

      test('Check slot availability - slot tersedia', () async {
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

        // Act
        final isAvailable = await bookingService.isSlotAvailable(
          lab: testLab,
          slot: slot,
        );

        // Assert
        expect(isAvailable, true);
      });

      test('Multiple bookings pada slot dan tanggal berbeda berhasil',
          () async {
        // Arrange - Create multiple slots
        final date1 = DateTime(2024, 12, 15);
        final date2 = DateTime(2024, 12, 16);

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot 1',
          slotDate: date1,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S002',
          slotName: 'Slot 2',
          slotDate: date2,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot1 = SlotModel.fromFirestore(
            slots.docs[0].id, slots.docs[0].data());
        final slot2 = SlotModel.fromFirestore(
            slots.docs[1].id, slots.docs[1].data());

        // Act - Book both slots
        final result1 = await bookingService.createBooking(
          lab: testLab,
          slot: slot1,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
          participantCount: 20,
        );

        final result2 = await bookingService.createBooking(
          lab: testLab,
          slot: slot2,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 2',
          participantCount: 25,
        );

        // Assert
        expect(result1, 'SUCCESS');
        expect(result2, 'SUCCESS');

        final bookings = await fakeFirestore.collection('Booking').get();
        expect(bookings.docs.length, 2);
      });
    });

    group('Negative Tests - Create Booking', () {
      test('Create booking gagal - slot sudah di-book (ada booking aktif)',
          () async {
        // Arrange - Create slot and first booking
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

        // First booking (akan diterima)
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
          participantCount: 25,
        );

        // Act - Try to book same slot (should fail)
        final result = await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: 'user456',
          nama: 'Jane Doe',
          nim: '2241720002',
          tujuan: 'Praktikum Web',
          participantCount: 20,
        );

        // Assert
        expect(result, 'SLOT_TIDAK_TERSEDIA');

        // Verify hanya ada 1 booking
        final bookings = await fakeFirestore.collection('Booking').get();
        expect(bookings.docs.length, 1);
        expect(bookings.docs.first.data()['book_by'], 'John Doe');
      });

      test('Create booking gagal - slot tidak open (is_open = false)',
          () async {
        // Arrange - Create closed slot
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

        // Close the slot
        await slotService.updateSlotStatus(slotId: slot.id, isOpen: false);

        // Act - Try to book closed slot
        final result = await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
          participantCount: 25,
        );

        // Assert
        expect(result, 'SLOT_DITUTUP');

        final bookings = await fakeFirestore.collection('Booking').get();
        expect(bookings.docs.length, 0);
      });

      test(
          'Create booking berhasil pada slot yang sebelumnya di-reject (is_rejected = true)',
          () async {
        // Arrange - Create slot and rejected booking
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

        // Create first booking
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
          participantCount: 25,
        );

        // Get booking and reject it
        final firstBookings = await fakeFirestore.collection('Booking').get();
        final bookingId = firstBookings.docs.first.id;
        await bookingService.setRejected(bookingId);

        // Act - Try to book same slot after rejection (should succeed)
        final result = await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: 'user456',
          nama: 'Jane Doe',
          nim: '2241720002',
          tujuan: 'Praktikum Web',
          participantCount: 20,
        );

        // Assert
        expect(result, 'SUCCESS');

        final allBookings = await fakeFirestore.collection('Booking').get();
        expect(allBookings.docs.length, 2);

        // Verify rejected booking exists
        final rejectedBooking =
            allBookings.docs.firstWhere((doc) => doc.id == bookingId);
        expect(rejectedBooking.data()['is_rejected'], true);

        // Verify new booking is not rejected
        final newBooking =
            allBookings.docs.firstWhere((doc) => doc.id != bookingId);
        expect(newBooking.data()['is_rejected'], false);
        expect(newBooking.data()['book_by'], 'Jane Doe');
      });

      test('Check slot availability - slot tidak tersedia (ada booking aktif)',
          () async {
        // Arrange - Create slot and booking
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

        // Create booking
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum',
          participantCount: 25,
        );

        // Act
        final isAvailable = await bookingService.isSlotAvailable(
          lab: testLab,
          slot: slot,
        );

        // Assert
        expect(isAvailable, false);
      });
    });

    group('Booking Code Generation', () {
      test('Booking code format benar dengan nomor urut', () async {
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

        // Act - Create multiple bookings
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'User 1',
          nim: '2241720001',
          tujuan: 'Test 1',
          participantCount: 20,
        );

        // Get different slot for second booking
        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S002',
          slotName: 'Slot Siang 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 13, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
        );

        final slots2 = await fakeFirestore.collection('Slots').get();
        final slot2 =
            SlotModel.fromFirestore(slots2.docs[1].id, slots2.docs[1].data());

        await bookingService.createBooking(
          lab: testLab,
          slot: slot2,
          userId: testUserId,
          nama: 'User 2',
          nim: '2241720002',
          tujuan: 'Test 2',
          participantCount: 25,
        );

        // Assert
        final bookings = await fakeFirestore.collection('Booking').get();
        final bookingCodes =
            bookings.docs.map((doc) => doc.data()['book_code']).toList();

        // Format: LAB001/S001/2024-12-15/0001
        expect(bookingCodes[0], contains('LAB001/S001/2024-12-15/0001'));
        expect(bookingCodes[1], contains('LAB001/S002/2024-12-15/0002'));
      });
    });

    group('Get Bookings', () {
      test('Get pending bookings berhasil', () async {
        // Arrange - Create bookings dengan status berbeda
        final slotDate = DateTime(2024, 12, 15);

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S002',
          slotName: 'Slot 2',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot1 = SlotModel.fromFirestore(
            slots.docs[0].id, slots.docs[0].data());
        final slot2 = SlotModel.fromFirestore(
            slots.docs[1].id, slots.docs[1].data());

        // Create pending booking
        await bookingService.createBooking(
          lab: testLab,
          slot: slot1,
          userId: testUserId,
          nama: 'User Pending',
          nim: '2241720001',
          tujuan: 'Test Pending',
          participantCount: 20,
        );

        // Create confirmed booking
        await bookingService.createBooking(
          lab: testLab,
          slot: slot2,
          userId: testUserId,
          nama: 'User Confirmed',
          nim: '2241720002',
          tujuan: 'Test Confirmed',
          participantCount: 25,
        );

        final allBookings = await fakeFirestore.collection('Booking').get();
        await bookingService.setApproved(allBookings.docs[1].id);

        // Act
        final pendingBookings =
            await bookingService.getPendingBookings().first;

        // Assert
        expect(pendingBookings.length, 1);
        expect(pendingBookings.first.bookBy, 'User Pending');
        expect(pendingBookings.first.isConfirmed, false);
        expect(pendingBookings.first.isRejected, false);
      });

      test('Get bookings by user berhasil', () async {
        // Arrange
        final slotDate = DateTime(2024, 12, 15);

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot = SlotModel.fromFirestore(
            slots.docs.first.id, slots.docs.first.data());

        // Create booking
        await bookingService.createBooking(
          lab: testLab,
          slot: slot,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Test',
          participantCount: 20,
        );

        // Act
        final userBookings =
            await bookingService.getBookingsByUser(testUserId).first;

        // Assert
        expect(userBookings.length, 1);
        expect(userBookings.first.bookBy, 'John Doe');
      });
    });

    group('Check Booked Slots', () {
      test('Check booked slots mengembalikan slot yang sudah di-book',
          () async {
        // Arrange
        final slotDate = DateTime(2024, 12, 15);

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S001',
          slotName: 'Slot 1',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        );

        await slotService.addSlot(
          lab: testLab,
          slotCode: 'S002',
          slotName: 'Slot 2',
          slotDate: slotDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
        );

        final slots = await fakeFirestore.collection('Slots').get();
        final slot1 = SlotModel.fromFirestore(
            slots.docs[0].id, slots.docs[0].data());

        // Book first slot
        await bookingService.createBooking(
          lab: testLab,
          slot: slot1,
          userId: testUserId,
          nama: 'John Doe',
          nim: '2241720001',
          tujuan: 'Test',
          participantCount: 20,
        );

        // Act
        final bookedSlots = await bookingService.checkBookedSlots(
          lab: testLab,
          date: slotDate,
        );

        // Assert
        expect(bookedSlots.length, 1);
        expect(bookedSlots.first.id, slot1.id);
      });
    });
  });
}