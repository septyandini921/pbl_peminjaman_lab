//C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\lib\service\lab_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/labs/lab_model.dart';

class LabService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference labsRef = FirebaseFirestore.instance.collection(
    'Labs',
  );

  /// Get semua data lab
  Stream<List<LabModel>> getLabs() {
    return labsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return LabModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Stream<List<LabModel>> getActiveLabs() {
    return labsRef
        .where('is_show', isEqualTo: true) 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LabModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }

  /// Toggle is_show field
  Future<void> updateIsShow(String labId, bool value) {
    return labsRef.doc(labId).update({'is_show': value});
  }

  /// generate auto increment id
  Future<String> getNextId() async {
    final snapshot = await labsRef.get();
    final nextId = (snapshot.docs.length + 1).toString();
    return nextId;
  }

  /// tambah lab baru
  Future<void> addLab({
    required String labKode,
    required String labName,
    required String labLocation,
    required int labCapacity,
    required String labDescription,
  }) async {
    final newId = await getNextId();

    await labsRef.doc(newId).set({
      'lab_kode': labKode,
      'lab_name': labName,
      'lab_location': labLocation,
      'lab_description': labDescription,
      'lab_capacity': labCapacity,
      'is_show': false,
    });
  }

  Future<String> getLabNameById(String labId) async {
    if (labId.isEmpty) return 'Lab Tidak Ditemukan';
    try {
        final DocumentSnapshot doc = await labsRef.doc(labId).get();
        if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            return data['lab_name'] as String? ?? 'Nama Lab Tidak Ditemukan';
        }
        return 'Lab Tidak Ditemukan';
    } catch (e) {
        return 'Error: $e';
    }
}
}
