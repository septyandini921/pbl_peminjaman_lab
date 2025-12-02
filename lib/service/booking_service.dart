import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/labs/lab_model.dart';
import '../models/slots/slot_model.dart';
import '../models/booking/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = "Booking";

  // CEK SLOT APAKAH MASIH TERSEDIA
  Future<bool> isSlotAvailable({
    required LabModel lab,
    required SlotModel slot,
  }) async {
    final slotRef = _firestore.doc("Slots/${slot.id}");

    final snapshot = await _firestore
        .collection(_collectionName)
        .where("slotId", isEqualTo: slotRef)
        .get();

    return snapshot.docs.isEmpty;
  }

  // GET SLOT PER LAB DAN DATE
  Future<List<SlotModel>> getSlotsForLab({
    required LabModel lab,
    required DateTime date,
  }) async {
    final labRef = _firestore.doc("Labs/${lab.id}");

    final dayStart = DateTime(date.year, date.month, date.day);
    final nextDay = dayStart.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection("Slots")
        .where("lab_ref", isEqualTo: labRef)
        .where("slot_start", isGreaterThanOrEqualTo: dayStart)
        .where("slot_start", isLessThan: nextDay)
        .get();

    return snapshot.docs
        .map((doc) => SlotModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // CEK SLOT YANG SUDAH DI BOOKING PADA TANGGAL TERSEBUT
  Future<List<DocumentReference>> checkBookedSlots({
    required LabModel lab,
    required DateTime date,
  }) async {
    final labRef = _firestore.doc("Labs/${lab.id}");

    final dayStart = DateTime(date.year, date.month, date.day);
    final nextDay = dayStart.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collectionName)
        .where("slot_start", isGreaterThanOrEqualTo: dayStart)
        .where("slot_start", isLessThan: nextDay)
        .get();

    return snapshot.docs
        .map((doc) => doc["slotId"] as DocumentReference)
        .toList();
  }

  // CREATE BOOKING
  Future<String> createBooking({
    required LabModel lab,
    required SlotModel slot,
    required String userId,
    required String nama,
    required String nim,
    required String tujuan,
  }) async {
    final slotRef = _firestore.doc("Slots/${slot.id}");
    final userRef = _firestore.doc("Users/$userId");

    // CEK APAKAH SLOT SUDAH DIBOOKING
    final slotDoc = await slotRef.get();
    if (slotDoc.exists && slotDoc["is_booked"] == true) {
      return "SLOT_TIDAK_TERSEDIA";
    }

    // Hitung BookCode
    final dayStart = DateTime(
      slot.slotStart.year,
      slot.slotStart.month,
      slot.slotStart.day,
    );
    final nextDay = dayStart.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collectionName)
        .where("slot_start", isGreaterThanOrEqualTo: dayStart)
        .where("slot_start", isLessThan: nextDay)
        .get();

    final nomorUrut =
        (snapshot.docs.length + 1).toString().padLeft(4, '0');

    final tanggalFormat =
        "${dayStart.year}-${dayStart.month.toString().padLeft(2, '0')}-${dayStart.day.toString().padLeft(2, '0')}";

    final bookCode = "${slot.slotCode}/$tanggalFormat/$nomorUrut";

    // SIMPAN DATA
    await _firestore.collection(_collectionName).add({
      "book_by": nama,
      "book_nim": nim,
      "book_purpose": tujuan,
      "book_code": bookCode,

      "slotId": slotRef,
      "user_id": userRef,

      "slot_start": Timestamp.fromDate(slot.slotStart),
      "slot_end": Timestamp.fromDate(slot.slotEnd),

      "is_confirmed": false,
      "is_present": false,

      "createdAt": FieldValue.serverTimestamp(),
    });

    // UPDATE SLOT JADI BOOKED
    await slotRef.update({"is_booked": true});

    return "SUCCESS";
  }

  // STREAM BOOKING BELUM DIKONFIRMASI
  Stream<List<BookingModel>> getPendingBookings() {
    return _firestore
        .collection(_collectionName)
        .where("is_confirmed", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // STREAM SEMUA BOOKING
  Stream<List<BookingModel>> getAllBookings() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}
