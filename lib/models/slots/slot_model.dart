import 'package:cloud_firestore/cloud_firestore.dart';

class SlotModel {
  final String id;
  final String slotCode;
  final DocumentReference labRef; // Reference ke Labs/<id>
  final DateTime slotStart;
  final DateTime slotEnd;
  final bool isBooked;
  final bool isOpen;

  SlotModel({
    required this.id,
    required this.slotCode,
    required this.labRef,
    required this.slotStart,
    required this.slotEnd,
    required this.isBooked,
    required this.isOpen,
  });

  factory SlotModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SlotModel(
      id: id,
      slotCode: data['slot_code'] ?? '',
      labRef: data['lab_ref'] as DocumentReference,
      slotStart: (data['slot_start'] as Timestamp).toDate(),
      slotEnd: (data['slot_end'] as Timestamp).toDate(),
      isBooked: data['is_booked'] ?? false,
      isOpen: data['is_open'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slot_code': slotCode,
      'lab_ref': labRef,
      'slot_start': slotStart,
      'slot_end': slotEnd,
      'is_booked': isBooked,
      'is_open': isOpen,
    };
  }
}
