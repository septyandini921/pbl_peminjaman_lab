//C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\lib\models\booking\booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String bookBy;
  final String bookCode;
  final String bookNim;
  final String bookPurpose;
  final int participantCount;
  final bool isConfirmed;
  final bool isRejected;    // <-- TAMBAH
  final bool isPresent;
  final DocumentReference? slotRef;
  final DocumentReference? userRef;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.bookBy,
    required this.bookCode,
    required this.bookNim,
    required this.bookPurpose,
    required this.participantCount,
    required this.isConfirmed,
    required this.isRejected,    // <-- TAMBAH
    required this.isPresent,
    required this.slotRef,
    required this.userRef,
    this.createdAt,
  });

  factory BookingModel.fromFirestore(String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      bookBy: data['book_by'] ?? "",
      bookCode: data['book_code'] ?? "",
      bookNim: data['book_nim'] ?? "",
      bookPurpose: data['book_purpose'] ?? "",
      participantCount: data['participant_count'] ?? 1,
      isConfirmed: data['is_confirmed'] ?? false,
      isRejected: data['is_rejected'] ?? false,     // <-- TAMBAH
      isPresent: data['is_present'] ?? false,
      slotRef: data['slotId'],
      userRef: data['user_id'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'book_by': bookBy,
      'book_code': bookCode,
      'book_nim': bookNim,
      'book_purpose': bookPurpose,
      'participant_count': participantCount,
      'is_confirmed': isConfirmed,
      'is_rejected': isRejected,    // <-- TAMBAH
      'is_present': isPresent,
      'slotId': slotRef,
      'user_id': userRef,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
