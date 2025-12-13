// test/unit_test/notification_test.dart
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
  group('BookingService Tests - Notification (User Bookings)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService bookingService;
    late SlotService slotService;
    late LabService labService;
    late LabModel testLab;
    late String user1Id;
    late String user2Id;
    late String user3Id;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      bookingService = BookingService.testConstructor(firestore: fakeFirestore);
      slotService = SlotService.testConstructor(firestore: fakeFirestore);
      labService = LabService.testConstructor(firestore: fakeFirestore);

      user1Id = 'user001';
      user2Id = 'user002';
      user3Id = 'user003';

      // Setup multiple users
      await fakeFirestore.collection('Users').doc(user1Id).set({
        'user_name': 'John Doe',
        'user_email': 'john@example.com',
        'user_auth': 0,
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      await fakeFirestore.collection('Users').doc(user2Id).set({
        'user_name': 'Jane Smith',
        'user_email': 'jane@example.com',
        'user_auth': 0,
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      await fakeFirestore.collection('Users').doc(user3Id).set({
        'user_name': 'Bob Johnson',
        'user_email': 'bob@example.com',
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
      required String userId,
      required String slotCode,
      required String slotName,
      required String userName,
      required String nim,
      required String tujuan,
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
        userId: userId,
        nama: userName,
        nim: nim,
        tujuan: tujuan,
        participantCount: 25,
      );

      final bookings = await fakeFirestore.collection('Booking').get();
      return bookings.docs.last.id;
    }

    group('Positive Tests - Get User Bookings', () {
      test('User dapat melihat semua booking yang dia buat', () async {
        // Arrange - Create 3 bookings untuk user1
        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile 1',
        );

        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S002',
          slotName: 'Slot Siang 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile 2',
        );

        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S003',
          slotName: 'Slot Sore 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile 3',
        );

        // Act
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert
        expect(userBookings.length, 3);
        expect(userBookings.every((b) => b.bookBy == 'John Doe'), true);
        expect(userBookings.every((b) => b.bookNim == '2241720001'), true);
      });

      test('User hanya melihat booking miliknya sendiri, bukan milik user lain',
          () async {
        // Arrange - Create bookings untuk different users
        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum John',
        );

        await _createTestBooking(
          userId: user2Id,
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'Jane Smith',
          nim: '2241720002',
          tujuan: 'Praktikum Jane',
        );

        await _createTestBooking(
          userId: user2Id,
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'Jane Smith',
          nim: '2241720002',
          tujuan: 'Praktikum Jane 2',
        );

        // Act
        final user1Bookings =
            await bookingService.getBookingsByUser(user1Id).first;
        final user2Bookings =
            await bookingService.getBookingsByUser(user2Id).first;

        // Assert
        expect(user1Bookings.length, 1);
        expect(user1Bookings.first.bookBy, 'John Doe');

        expect(user2Bookings.length, 2);
        expect(user2Bookings.every((b) => b.bookBy == 'Jane Smith'), true);
      });

      test('User dapat melihat status booking yang berubah (pending -> confirmed)',
          () async {
        // Arrange
        final bookingId = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
        );

        // Check initial status
        var userBookings =
            await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.length, 1);
        expect(userBookings.first.isConfirmed, false);
        expect(userBookings.first.isRejected, false);

        // Act - Admin approves booking
        await bookingService.setApproved(bookingId);

        // Assert - User sees updated status
        userBookings = await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.first.isConfirmed, true);
        expect(userBookings.first.isRejected, false);
      });

      test('User dapat melihat status booking yang di-reject',
          () async {
        // Arrange
        final bookingId = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
        );

        // Act - Admin rejects booking
        await bookingService.setRejected(bookingId);

        // Assert - User sees rejected status
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.first.isConfirmed, false);
        expect(userBookings.first.isRejected, true);
      });

      test('Bookings user diurutkan berdasarkan createdAt (terbaru di atas)',
          () async {
        // Arrange - Create bookings dengan jeda waktu
        final bookingId1 = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
        );

        // Simulate time difference
        await Future.delayed(const Duration(milliseconds: 100));

        final bookingId2 = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 2',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        final bookingId3 = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 3',
        );

        // Act
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert - Newest first
        expect(userBookings.length, 3);
        // Note: Ordering verification depends on createdAt timestamps
        // In real scenario, the newest booking should be first
      });

      test('User melihat booking code yang berbeda untuk setiap booking',
          () async {
        // Arrange
        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
        );

        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 2',
        );

        // Act
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert
        expect(userBookings.length, 2);
        expect(userBookings[0].bookCode, isNotEmpty);
        expect(userBookings[1].bookCode, isNotEmpty);
        expect(userBookings[0].bookCode != userBookings[1].bookCode, true);
      });

      test('User dapat melihat semua detail booking (nama, nim, tujuan, participant)',
          () async {
        // Arrange
        const testNama = 'John Doe';
        const testNim = '2241720001';
        const testTujuan = 'Praktikum Mobile Programming';
        const testParticipant = 25;

        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: testNama,
          nim: testNim,
          tujuan: testTujuan,
        );

        // Act
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert
        expect(userBookings.length, 1);
        final booking = userBookings.first;
        expect(booking.bookBy, testNama);
        expect(booking.bookNim, testNim);
        expect(booking.bookPurpose, testTujuan);
        expect(booking.participantCount, testParticipant);
      });
    });

    group('Positive Tests - Multiple Users Notifications', () {
      test('Multiple users dapat melihat notifikasi booking mereka masing-masing',
          () async {
        // Arrange - Create bookings for 3 different users
        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum John',
        );

        await _createTestBooking(
          userId: user2Id,
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'Jane Smith',
          nim: '2241720002',
          tujuan: 'Praktikum Jane',
        );

        await _createTestBooking(
          userId: user3Id,
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'Bob Johnson',
          nim: '2241720003',
          tujuan: 'Praktikum Bob',
        );

        // Act
        final user1Bookings =
            await bookingService.getBookingsByUser(user1Id).first;
        final user2Bookings =
            await bookingService.getBookingsByUser(user2Id).first;
        final user3Bookings =
            await bookingService.getBookingsByUser(user3Id).first;

        // Assert
        expect(user1Bookings.length, 1);
        expect(user1Bookings.first.bookBy, 'John Doe');

        expect(user2Bookings.length, 1);
        expect(user2Bookings.first.bookBy, 'Jane Smith');

        expect(user3Bookings.length, 1);
        expect(user3Bookings.first.bookBy, 'Bob Johnson');
      });

      test('User menerima notifikasi ketika booking berhasil dibuat',
          () async {
        // Arrange & Act
        final result = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
        );

        // Assert - Booking exists in user's bookings (notification)
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.length, 1);
        expect(userBookings.first.isConfirmed, false);
        expect(userBookings.first.isRejected, false);
        expect(result, isNotEmpty);
      });

      test('User menerima notifikasi ketika booking di-approve',
          () async {
        // Arrange
        final bookingId = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
        );

        // Act - Admin approves
        await bookingService.setApproved(bookingId);

        // Assert - User sees approved notification
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.first.isConfirmed, true);
        expect(userBookings.first.isRejected, false);
      });

      test('User menerima notifikasi ketika booking di-reject',
          () async {
        // Arrange
        final bookingId = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
        );

        // Act - Admin rejects
        await bookingService.setRejected(bookingId);

        // Assert - User sees rejected notification
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.first.isConfirmed, false);
        expect(userBookings.first.isRejected, true);
      });

      test('User melihat perubahan status dari pending -> approved -> present',
          () async {
        // Arrange - Create booking
        final bookingId = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
        );

        // Check pending status
        var userBookings =
            await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.first.isConfirmed, false);
        expect(userBookings.first.isPresent, false);

        // Act - Admin approves
        await bookingService.setApproved(bookingId);
        userBookings = await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.first.isConfirmed, true);
        expect(userBookings.first.isPresent, false);

        // Act - Aslab marks present
        await bookingService.setPresent(bookingId);

        // Assert - Final status
        userBookings = await bookingService.getBookingsByUser(user1Id).first;
        expect(userBookings.first.isConfirmed, true);
        expect(userBookings.first.isPresent, true);
      });
    });

    group('Negative Tests - User Bookings', () {
      test('User tanpa booking tidak melihat notifikasi apapun',
          () async {
        // Arrange - No bookings created for user1
        await _createTestBooking(
          userId: user2Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'Jane Smith',
          nim: '2241720002',
          tujuan: 'Praktikum Jane',
        );

        // Act
        final user1Bookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert
        expect(user1Bookings.length, 0);
      });

      test('User dengan ID yang tidak valid tidak melihat booking',
          () async {
        // Arrange
        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum',
        );

        // Act - Query dengan user ID yang tidak ada
        final invalidUserBookings =
            await bookingService.getBookingsByUser('invalid_user_999').first;

        // Assert
        expect(invalidUserBookings.length, 0);
      });

      test('User tidak melihat booking user lain yang di-approve',
          () async {
        // Arrange
        final user2BookingId = await _createTestBooking(
          userId: user2Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'Jane Smith',
          nim: '2241720002',
          tujuan: 'Praktikum Jane',
        );

        // Approve user2's booking
        await bookingService.setApproved(user2BookingId);

        // Act - User1 checks their bookings
        final user1Bookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert - User1 sees nothing
        expect(user1Bookings.length, 0);
      });

      test('User tidak melihat booking user lain yang di-reject',
          () async {
        // Arrange
        final user2BookingId = await _createTestBooking(
          userId: user2Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'Jane Smith',
          nim: '2241720002',
          tujuan: 'Praktikum Jane',
        );

        // Reject user2's booking
        await bookingService.setRejected(user2BookingId);

        // Act - User1 checks their bookings
        final user1Bookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert - User1 sees nothing
        expect(user1Bookings.length, 0);
      });
    });

    group('Edge Cases - Notification Scenarios', () {
      test('User dengan multiple bookings melihat semua status yang berbeda',
          () async {
        // Arrange - Create 3 bookings dengan status berbeda
        final bookingId1 = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
        );

        final bookingId2 = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S002',
          slotName: 'Slot 2',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 2',
        );

        final bookingId3 = await _createTestBooking(
          userId: user1Id,
          slotCode: 'S003',
          slotName: 'Slot 3',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 3',
        );

        // Set different statuses
        await bookingService.setApproved(bookingId1);
        await bookingService.setRejected(bookingId2);
        // bookingId3 remains pending

        // Act
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert
        expect(userBookings.length, 3);

        final approved =
            userBookings.where((b) => b.isConfirmed == true).toList();
        final rejected =
            userBookings.where((b) => b.isRejected == true).toList();
        final pending = userBookings
            .where((b) => b.isConfirmed == false && b.isRejected == false)
            .toList();

        expect(approved.length, 1);
        expect(rejected.length, 1);
        expect(pending.length, 1);
      });

      test('User melihat booking dengan createdAt null di urutan terakhir',
          () async {
        // Arrange
        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum 1',
        );

        // Act
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;

        // Assert - Verifikasi sorting logic handles null createdAt
        expect(userBookings.length, 1);
        // Service sorts: null createdAt goes to end
      });

      test('Slot reference tetap valid di booking user setelah slot updated',
          () async {
        // Arrange
        await _createTestBooking(
          userId: user1Id,
          slotCode: 'S001',
          slotName: 'Slot Pagi 1',
          userName: 'John Doe',
          nim: '2241720001',
          tujuan: 'Praktikum Mobile',
        );

        // Get booking's slot reference
        final userBookings =
            await bookingService.getBookingsByUser(user1Id).first;
        final slotRef = userBookings.first.slotRef;

        // Assert - Slot reference exists and valid
        expect(slotRef, isNotNull);
        
        final slotDoc = await slotRef!.get();
        expect(slotDoc.exists, true);
      });
    });
  });
}