import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String bookBy;
  final String bookCode;
  final String bookNim;
  final String bookPurpose;
  final bool isConfirmed;
  final bool isPresent;
  final DocumentReference? slotRef;
  final DocumentReference? userRef;

  BookingModel({
    required this.id,
    required this.bookBy,
    required this.bookCode,
    required this.bookNim,
    required this.bookPurpose,
    required this.isConfirmed,
    required this.isPresent,
    required this.slotRef,
    required this.userRef,
  });

  // FROM FIRESTORE
  factory BookingModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      bookBy: data['book_by'] ?? "",
      bookCode: data['book_code'] ?? "",
      bookNim: data['book_nim'] ?? "",
      bookPurpose: data['book_purpose'] ?? "",
      isConfirmed: data['is_confirmed'] ?? false,
      isPresent: data['is_present'] ?? false,
      slotRef: data['slotId'],    // sudah DocumentReference
      userRef: data['user_id'],   // sudah DocumentReference
    );
  }

  // KE FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'book_by': bookBy,
      'book_code': bookCode,
      'book_nim': bookNim,
      'book_purpose': bookPurpose,
      'is_confirmed': isConfirmed,
      'is_present': isPresent,
      'slotId': slotRef,
      'user_id': userRef,
    };
  }
}
