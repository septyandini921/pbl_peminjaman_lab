// booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final DocumentReference userId;
  final DocumentReference slotRef;
  final String bookCode;
  final String bookBy;
  final String bookNim;
  final String bookPurpose;
  final bool isConfirmed;
  final bool isPresent;

  BookingModel({
    required this.id,
    required this.userId,
    required this.slotRef,
    required this.bookCode, 
    required this.bookBy,
    required this.bookNim,
    required this.bookPurpose,
    required this.isConfirmed,
    required this.isPresent,
  });

  factory BookingModel.fromFirestore(String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      userId: data['user_id'] as DocumentReference,
      slotRef: data['slot_ref'] as DocumentReference,
      bookCode: data['book_code'] ?? '', 
      bookBy: data['book_by'] ?? '',
      bookNim: data['book_nim'] ?? '',
      bookPurpose: data['book_purpose'] ?? '',
      isConfirmed: data['is_confirmed'] ?? false,
      isPresent: data['is_present'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'slotId': slotRef,
      'book_code': bookCode,
      'book_by': bookBy,
      'book_nim': bookNim,
      'book_purpose': bookPurpose,
      'is_confirmed': isConfirmed,
      'is_present': isPresent,
    };
  }
}
