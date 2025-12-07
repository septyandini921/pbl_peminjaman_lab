import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/slots/slot_model.dart';
import '../models/labs/lab_model.dart';
import 'package:flutter/material.dart';

class SlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Slots';

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

  Future<String> getNextId() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final nextId = (snapshot.docs.length + 1).toString();
    return nextId;
  }

  Future<void> addSlot({
    required LabModel lab,
    required String slotCode,
    required String slotName,
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

    final docRef = _firestore.collection(_collectionName).doc();
    final DocumentReference labRef = _firestore.doc("Labs/${lab.id}");

    final newSlot = SlotModel(
      id: docRef.id,
      slotCode: "${lab.labKode}/$slotCode",
      slotName: slotName,
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

  Future<void> updateSlotStatus({
    required String slotId,
    required bool isOpen,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(slotId).update({
        'is_open': isOpen,
      });
    } catch (e) {
      print('Error updating slot status: $e');
      rethrow;
    }
  }

  Future<bool> updateSlotBookedStatus({
    required String slotId,
    required bool isBooked,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final slotRef = _firestore.collection(_collectionName).doc(slotId);
        final slotSnapshot = await transaction.get(slotRef);

        if (!slotSnapshot.exists) {
          throw Exception('Slot tidak ditemukan');
        }

        if (isBooked) {
          final currentIsBooked = slotSnapshot.data()?['is_booked'] ?? false;
          if (currentIsBooked) {
            return false;
          }
        }

        transaction.update(slotRef, {
          'is_booked': isBooked,
        });

        return true;
      });
    } catch (e) {
      print('Error updating slot booked status: $e');
      return false;
    }
  }

  Future<bool> tryBookSlot({
    required String slotId,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final slotRef = _firestore.collection(_collectionName).doc(slotId);
        final slotSnapshot = await transaction.get(slotRef);

        if (!slotSnapshot.exists) {
          throw Exception('Slot tidak ditemukan');
        }

        final data = slotSnapshot.data()!;
        final isBooked = data['is_booked'] ?? false;
        final isOpen = data['is_open'] ?? true;

        if (isBooked || !isOpen) {
          return false;
        }

        transaction.update(slotRef, {
          'is_booked': true,
        });

        return true;
      });
    } catch (e) {
      print('Error booking slot: $e');
      return false;
    }
  }

  Future<bool> releaseSlot({
    required String slotId,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final slotRef = _firestore.collection(_collectionName).doc(slotId);
        final slotSnapshot = await transaction.get(slotRef);

        if (!slotSnapshot.exists) {
          throw Exception('Slot tidak ditemukan');
        }

        transaction.update(slotRef, {
          'is_booked': false,
        });

        return true;
      });
    } catch (e) {
      print('Error releasing slot: $e');
      return false;
    }
  }

  Future<void> updateSlot({
    required String slotId,
    required String slotCode,
    required String slotName,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(slotId).update({
        'slot_code': slotCode,
        'slot_name': slotName,
        'slot_start': slotStart,
        'slot_end': slotEnd,
      });
    } catch (e) {
      print('Error updating slot: $e');
      rethrow;
    }
  }

  Future<void> deleteSlot({required String slotId}) async {
    try {
      await _firestore.collection(_collectionName).doc(slotId).delete();
    } catch (e) {
      print('Error deleting slot: $e');
      rethrow;
    }
  }

  Stream<int> getTotalOpenSlotsWeekly() {
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final sevenDaysFromNow = startOfToday.add(const Duration(days: 7));

    return _firestore
        .collection(_collectionName)
        .where('is_open', isEqualTo: true)
        .where('slot_start', isGreaterThanOrEqualTo: startOfToday)
        .where('slot_start', isLessThan: sevenDaysFromNow)
        .orderBy('slot_start')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalUsedSlotsWeekly() {
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final sevenDaysFromNow = startOfToday.add(const Duration(days: 7));

    return _firestore
        .collection(_collectionName)
        .where('is_booked', isEqualTo: true)
        .where('slot_start', isGreaterThanOrEqualTo: startOfToday)
        .where('slot_start', isLessThan: sevenDaysFromNow)
        .orderBy('slot_start')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}