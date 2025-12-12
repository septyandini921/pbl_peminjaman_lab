// test/unit_test/slot_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pbl_peminjaman_lab/service/slot_service.dart';
import 'package:pbl_peminjaman_lab/models/slots/slot_model.dart';
import 'package:pbl_peminjaman_lab/models/labs/lab_model.dart';

void main() {
  group('SlotService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SlotService slotService;
    late LabModel testLab;
    late DocumentReference testLabRef;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      slotService = SlotService.testConstructor(firestore: fakeFirestore);

      // Setup test lab
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

    test('Menambahkan slot baru berhasil', () async {
      // Arrange
      final slotDate = DateTime(2024, 12, 15);
      const startTime = TimeOfDay(hour: 8, minute: 0);
      const endTime = TimeOfDay(hour: 10, minute: 0);

      // Act
      await slotService.addSlot(
        lab: testLab,
        slotCode: 'S001',
        slotName: 'Slot Pagi 1',
        slotDate: slotDate,
        startTime: startTime,
        endTime: endTime,
      );

      // Assert
      final snapshot = await fakeFirestore.collection('Slots').get();
      expect(snapshot.docs.length, 1);

      final slotDoc = snapshot.docs.first;
      final slotData = slotDoc.data();

      expect(slotData['slot_code'], 'LAB001/S001');
      expect(slotData['slot_name'], 'Slot Pagi 1');
      expect(slotData['is_booked'], false);
      expect(slotData['is_open'], true);

      // Verify timestamps
      final slotStart = (slotData['slot_start'] as Timestamp).toDate();
      expect(slotStart.year, 2024);
      expect(slotStart.month, 12);
      expect(slotStart.day, 15);
      expect(slotStart.hour, 8);
      expect(slotStart.minute, 0);

      final slotEnd = (slotData['slot_end'] as Timestamp).toDate();
      expect(slotEnd.hour, 10);
      expect(slotEnd.minute, 0);
    });

    test('Get slots by date berhasil', () async {
      // Arrange - Tambahkan beberapa slot
      final targetDate = DateTime(2024, 12, 15);
      final otherDate = DateTime(2024, 12, 16);

      // Slot pada tanggal target
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': false,
        'is_open': true,
      });

      await fakeFirestore.collection('Slots').doc('slot2').set({
        'slot_code': 'LAB001/S002',
        'slot_name': 'Slot Pagi 2',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 12, 0)),
        'is_booked': false,
        'is_open': true,
      });

      // Slot pada tanggal berbeda (tidak akan muncul)
      await fakeFirestore.collection('Slots').doc('slot3').set({
        'slot_code': 'LAB001/S003',
        'slot_name': 'Slot Siang',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 16, 13, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 16, 15, 0)),
        'is_booked': false,
        'is_open': true,
      });

      // Act
      final slots = await slotService
          .getSlotsStreamByDate(lab: testLab, selectedDate: targetDate)
          .first;

      // Assert
      expect(slots.length, 2);
      expect(slots[0].slotCode, 'LAB001/S001');
      expect(slots[1].slotCode, 'LAB001/S002');
      expect(slots.every((slot) => slot.slotStart.day == 15), true);
    });

    test('Update slot status berhasil', () async {
      // Arrange
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': false,
        'is_open': true,
      });

      // Act
      await slotService.updateSlotStatus(slotId: 'slot1', isOpen: false);

      // Assert
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      expect(slotDoc.data()?['is_open'], false);
    });

    test('Try book slot berhasil - slot tersedia', () async {
      // Arrange
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': false,
        'is_open': true,
      });

      // Act
      final result = await slotService.tryBookSlot(slotId: 'slot1');

      // Assert
      expect(result, true);
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      expect(slotDoc.data()?['is_booked'], true);
    });

    test('Try book slot gagal - slot sudah di-book', () async {
      // Arrange - Slot sudah di-book
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': true,
        'is_open': true,
      });

      // Act
      final result = await slotService.tryBookSlot(slotId: 'slot1');

      // Assert
      expect(result, false);
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      expect(slotDoc.data()?['is_booked'], true); // Tetap booked
    });

    test('Try book slot gagal - slot tidak open', () async {
      // Arrange - Slot tidak open
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': false,
        'is_open': false,
      });

      // Act
      final result = await slotService.tryBookSlot(slotId: 'slot1');

      // Assert
      expect(result, false);
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      expect(slotDoc.data()?['is_booked'], false); // Tetap tidak booked
    });

    test('Release slot berhasil', () async {
      // Arrange - Slot yang sudah di-book
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': true,
        'is_open': true,
      });

      // Act
      final result = await slotService.releaseSlot(slotId: 'slot1');

      // Assert
      expect(result, true);
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      expect(slotDoc.data()?['is_booked'], false);
    });

    test('Update slot booked status berhasil', () async {
      // Arrange
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': false,
        'is_open': true,
      });

      // Act
      final result = await slotService.updateSlotBookedStatus(
        slotId: 'slot1',
        isBooked: true,
      );

      // Assert
      expect(result, true);
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      expect(slotDoc.data()?['is_booked'], true);
    });

    test('Update slot booked status gagal - slot sudah booked', () async {
      // Arrange - Slot sudah booked
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': true,
        'is_open': true,
      });

      // Act - Coba book lagi
      final result = await slotService.updateSlotBookedStatus(
        slotId: 'slot1',
        isBooked: true,
      );

      // Assert
      expect(result, false);
    });

    test('Update slot information berhasil', () async {
      // Arrange
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': false,
        'is_open': true,
      });

      // Act
      final newStart = DateTime(2024, 12, 15, 9, 0);
      final newEnd = DateTime(2024, 12, 15, 11, 0);

      await slotService.updateSlot(
        slotId: 'slot1',
        slotCode: 'LAB001/S001-UPDATED',
        slotName: 'Slot Updated',
        slotStart: newStart,
        slotEnd: newEnd,
      );

      // Assert
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      final slotData = slotDoc.data();

      expect(slotData?['slot_code'], 'LAB001/S001-UPDATED');
      expect(slotData?['slot_name'], 'Slot Updated');
      expect((slotData?['slot_start'] as Timestamp).toDate().hour, 9);
      expect((slotData?['slot_end'] as Timestamp).toDate().hour, 11);
    });

    test('Delete slot berhasil', () async {
      // Arrange
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot Pagi 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(DateTime(2024, 12, 15, 8, 0)),
        'slot_end': Timestamp.fromDate(DateTime(2024, 12, 15, 10, 0)),
        'is_booked': false,
        'is_open': true,
      });

      // Act
      await slotService.deleteSlot(slotId: 'slot1');

      // Assert
      final slotDoc = await fakeFirestore.collection('Slots').doc('slot1').get();
      expect(slotDoc.exists, false);
    });

    test('Get total open slots weekly berhasil', () async {
      // Arrange
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      // Slot dalam 7 hari ke depan dan open
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 1))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 1, hours: 2))),
        'is_booked': false,
        'is_open': true,
      });

      await fakeFirestore.collection('Slots').doc('slot2').set({
        'slot_code': 'LAB001/S002',
        'slot_name': 'Slot 2',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 3))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 3, hours: 2))),
        'is_booked': false,
        'is_open': true,
      });

      // Slot open tapi di luar 7 hari
      await fakeFirestore.collection('Slots').doc('slot3').set({
        'slot_code': 'LAB001/S003',
        'slot_name': 'Slot 3',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 10))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 10, hours: 2))),
        'is_booked': false,
        'is_open': true,
      });

      // Slot dalam 7 hari tapi tidak open
      await fakeFirestore.collection('Slots').doc('slot4').set({
        'slot_code': 'LAB001/S004',
        'slot_name': 'Slot 4',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 2))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 2, hours: 2))),
        'is_booked': false,
        'is_open': false,
      });

      // Act
      final totalOpenSlots = await slotService.getTotalOpenSlotsWeekly().first;

      // Assert
      expect(totalOpenSlots, 2); // Hanya slot1 dan slot2
    });

    test('Get total used slots weekly berhasil', () async {
      // Arrange
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      // Slot booked dalam 7 hari
      await fakeFirestore.collection('Slots').doc('slot1').set({
        'slot_code': 'LAB001/S001',
        'slot_name': 'Slot 1',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 1))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 1, hours: 2))),
        'is_booked': true,
        'is_open': true,
      });

      await fakeFirestore.collection('Slots').doc('slot2').set({
        'slot_code': 'LAB001/S002',
        'slot_name': 'Slot 2',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 4))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 4, hours: 2))),
        'is_booked': true,
        'is_open': true,
      });

      // Slot tidak booked
      await fakeFirestore.collection('Slots').doc('slot3').set({
        'slot_code': 'LAB001/S003',
        'slot_name': 'Slot 3',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 2))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 2, hours: 2))),
        'is_booked': false,
        'is_open': true,
      });

      // Slot booked tapi di luar 7 hari
      await fakeFirestore.collection('Slots').doc('slot4').set({
        'slot_code': 'LAB001/S004',
        'slot_name': 'Slot 4',
        'lab_ref': testLabRef,
        'slot_start': Timestamp.fromDate(startOfToday.add(Duration(days: 10))),
        'slot_end': Timestamp.fromDate(startOfToday.add(Duration(days: 10, hours: 2))),
        'is_booked': true,
        'is_open': true,
      });

      // Act
      final totalUsedSlots = await slotService.getTotalUsedSlotsWeekly().first;

      // Assert
      expect(totalUsedSlots, 2); // Hanya slot1 dan slot2
    });
  });
}