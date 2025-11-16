import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/slots/slot_model.dart';
import '../models/labs/lab_model.dart';
import 'package:flutter/material.dart';

class SlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Slots';

  // Read
  Stream<List<SlotModel>> getSlotsStreamByDate({
    required LabModel lab,
    required DateTime selectedDate,
  }) {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final DocumentReference labRef = _firestore.doc("Labs/${lab.id}");

    return _firestore
        .collection(_collectionName)
        .where('lab_ref', isEqualTo: labRef)
        .where('slot_start', isGreaterThanOrEqualTo: startOfDay)
        .where('slot_start', isLessThan: endOfDay)
        .orderBy('slot_start', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SlotModel.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  // auto increment id
  Future<String> getNextId() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final nextId = (snapshot.docs.length + 1).toString();
    return nextId;
  }

  // tambah slot
  Future<void> addSlot({
    required LabModel lab,
    required String slotCode,
    required DateTime slotDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final startDateTime = DateTime(
      slotDate.year,
      slotDate.month,
      slotDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      slotDate.year,
      slotDate.month,
      slotDate.day,
      endTime.hour,
      endTime.minute,
    );

    final docRef = _firestore.collection(_collectionName).doc(); // <-- AUTO ID
    final DocumentReference labRef = _firestore.doc("Labs/${lab.id}");

    final newSlot = SlotModel(
      id: docRef.id,
      slotCode: "${lab.labKode}/$slotCode",
      labRef: labRef,
      slotStart: startDateTime,
      slotEnd: endDateTime,
      isBooked: false,
      isOpen: true,
    );

    await _firestore
        .collection(_collectionName)
        .doc(docRef.id)
        .set(newSlot.toMap());
  }

  // update slot
  Future<void> updateSlotStatus({
    required String slotId,
    required bool isOpen,
  }) async {
    await _firestore.collection(_collectionName).doc(slotId).update({
      'is_open': isOpen,
    });
  }

  // hapus slot
  Future<void> deleteSlot({required String slotId}) async {
    await _firestore.collection(_collectionName).doc(slotId).delete();
  }
}
