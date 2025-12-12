// test/unit_test/lab_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:pbl_peminjaman_lab/service/lab_service.dart';
import 'package:pbl_peminjaman_lab/models/labs/lab_model.dart';

void main() {
  group('LabService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late LabService labService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      labService = LabService.testConstructor(firestore: fakeFirestore);
    });

    test('Menambahkan lab baru', () async {
      // Arrange
      const labKode = 'LAB001';
      const labName = 'Lab Komputer 1';
      const labLocation = 'Gedung A Lantai 2';
      const labCapacity = 40;
      const labDescription = 'Lab untuk praktikum pemrograman';

      // Act
      await labService.addLab(
        labKode: labKode,
        labName: labName,
        labLocation: labLocation,
        labCapacity: labCapacity,
        labDescription: labDescription,
      );

      // Assert
      final snapshot = await fakeFirestore.collection('Labs').get();
      expect(snapshot.docs.length, 1);

      final labDoc = snapshot.docs.first;
      final labData = labDoc.data();

      expect(labData['lab_kode'], labKode);
      expect(labData['lab_name'], labName);
      expect(labData['lab_location'], labLocation);
      expect(labData['lab_capacity'], labCapacity);
      expect(labData['lab_description'], labDescription);
      expect(labData['is_show'], false); // Default value
    });

    test('Update is_show lab menjadi true', () async {
      // Arrange - Tambahkan lab terlebih dahulu
      await fakeFirestore.collection('Labs').doc('1').set({
        'lab_kode': 'LAB001',
        'lab_name': 'Lab Komputer 1',
        'lab_location': 'Gedung A Lantai 2',
        'lab_description': 'Lab untuk praktikum pemrograman',
        'lab_capacity': 40,
        'is_show': false,
      });

      // Act - Update is_show menjadi true
      await labService.updateIsShow('1', true);

      // Assert - Verifikasi is_show sudah berubah menjadi true
      final labDoc = await fakeFirestore.collection('Labs').doc('1').get();
      final labData = labDoc.data();

      expect(labData?['is_show'], true);
    });

    test('Melihat lab yang aktif (is_show = true)', () async {
      // Arrange - Tambahkan beberapa lab dengan is_show berbeda
      await fakeFirestore.collection('Labs').doc('1').set({
        'lab_kode': 'LAB001',
        'lab_name': 'Lab Komputer 1',
        'lab_location': 'Gedung A Lantai 2',
        'lab_description': 'Lab untuk praktikum pemrograman',
        'lab_capacity': 40,
        'is_show': true, // Lab aktif
      });

      await fakeFirestore.collection('Labs').doc('2').set({
        'lab_kode': 'LAB002',
        'lab_name': 'Lab Komputer 2',
        'lab_location': 'Gedung A Lantai 3',
        'lab_description': 'Lab untuk praktikum web',
        'lab_capacity': 35,
        'is_show': false, // Lab tidak aktif
      });

      await fakeFirestore.collection('Labs').doc('3').set({
        'lab_kode': 'LAB003',
        'lab_name': 'Lab Komputer 3',
        'lab_location': 'Gedung B Lantai 1',
        'lab_description': 'Lab untuk praktikum mobile',
        'lab_capacity': 45,
        'is_show': true, // Lab aktif
      });

      // Act - Get lab yang aktif
      final activeLabs = await labService.getActiveLabs().first;

      // Assert
      expect(activeLabs.length, 2); // Hanya 2 lab yang is_show = true
      expect(activeLabs.every((lab) => lab.isShow == true), true);
      expect(activeLabs.any((lab) => lab.labName == 'Lab Komputer 1'), true);
      expect(activeLabs.any((lab) => lab.labName == 'Lab Komputer 3'), true);
      expect(activeLabs.any((lab) => lab.labName == 'Lab Komputer 2'), false);
    });

    test('Menambahkan multiple lab dengan auto increment ID', () async {
      // Arrange & Act - Tambahkan 3 lab
      await labService.addLab(
        labKode: 'LAB001',
        labName: 'Lab Komputer 1',
        labLocation: 'Gedung A Lantai 2',
        labCapacity: 40,
        labDescription: 'Lab 1',
      );

      await labService.addLab(
        labKode: 'LAB002',
        labName: 'Lab Komputer 2',
        labLocation: 'Gedung A Lantai 3',
        labCapacity: 35,
        labDescription: 'Lab 2',
      );

      await labService.addLab(
        labKode: 'LAB003',
        labName: 'Lab Komputer 3',
        labLocation: 'Gedung B Lantai 1',
        labCapacity: 45,
        labDescription: 'Lab 3',
      );

      // Assert
      final snapshot = await fakeFirestore.collection('Labs').get();
      expect(snapshot.docs.length, 3);

      // Verifikasi ID auto increment
      final ids = snapshot.docs.map((doc) => doc.id).toList();
      expect(ids.contains('1'), true);
      expect(ids.contains('2'), true);
      expect(ids.contains('3'), true);
    });

    test('Get semua lab termasuk yang tidak aktif', () async {
      // Arrange - Tambahkan beberapa lab
      await fakeFirestore.collection('Labs').doc('1').set({
        'lab_kode': 'LAB001',
        'lab_name': 'Lab Komputer 1',
        'lab_location': 'Gedung A Lantai 2',
        'lab_description': 'Lab 1',
        'lab_capacity': 40,
        'is_show': true,
      });

      await fakeFirestore.collection('Labs').doc('2').set({
        'lab_kode': 'LAB002',
        'lab_name': 'Lab Komputer 2',
        'lab_location': 'Gedung A Lantai 3',
        'lab_description': 'Lab 2',
        'lab_capacity': 35,
        'is_show': false,
      });

      // Act
      final allLabs = await labService.getLabs().first;

      // Assert
      expect(allLabs.length, 2); // Semua lab, termasuk yang is_show = false
    });

    test('Get lab name by ID berhasil', () async {
      // Arrange
      await fakeFirestore.collection('Labs').doc('1').set({
        'lab_kode': 'LAB001',
        'lab_name': 'Lab Komputer 1',
        'lab_location': 'Gedung A Lantai 2',
        'lab_description': 'Lab 1',
        'lab_capacity': 40,
        'is_show': true,
      });

      // Act
      final labName = await labService.getLabNameById('1');

      // Assert
      expect(labName, 'Lab Komputer 1');
    });

    test('Get lab name by ID tidak ditemukan', () async {
      // Act
      final labName = await labService.getLabNameById('999');

      // Assert
      expect(labName, 'Lab Tidak Ditemukan');
    });

    test('Get lab name dengan ID kosong', () async {
      // Act
      final labName = await labService.getLabNameById('');

      // Assert
      expect(labName, 'Lab Tidak Ditemukan');
    });
  });
}