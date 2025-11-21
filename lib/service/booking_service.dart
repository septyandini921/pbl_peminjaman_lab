import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/labs/lab_model.dart';
import '../models/slots/slot_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = "Bookings";

  // CEK SLOT APAKAH MASIH TERSEDIA
  Future<bool> isSlotAvailable({
    required LabModel lab,
    required SlotModel slot,
  }) async {
    final labRef = _firestore.doc("Labs/${lab.id}");
    final slotRef = _firestore.doc("Slots/${slot.id}");

    final snapshot = await _firestore
        .collection(_collectionName)
        .where("labId", isEqualTo: labRef)
        .where("slotId", isEqualTo: slotRef)
        .get();

    return snapshot.docs.isEmpty; 
  }

  // SLOT PER LAB BERDASARKAN TANGGAL
  Future<List<SlotModel>> getSlotsForLab({
    required LabModel lab,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final labRef = _firestore.doc("Labs/${lab.id}");

    final snapshot = await _firestore
        .collection("Slots")
        .where("lab_ref", isEqualTo: labRef)
        .where("slot_start", isGreaterThanOrEqualTo: dayStart)
        .where("slot_start", isLessThan: dayEnd)
        .get();

    return snapshot.docs
        .map((doc) => SlotModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // CEK SLOT YANG SUDAH DIBOOKING PADA TANGGAL TERSEBUT
  Future<List<DocumentReference>> checkBookedSlots({
    required LabModel lab,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final labRef = _firestore.doc("Labs/${lab.id}");

    final snapshot = await _firestore
        .collection(_collectionName)
        .where("labId", isEqualTo: labRef)
        .where("is_open", isEqualTo: true)
        .where("date", isGreaterThanOrEqualTo: dayStart)
        .where("date", isLessThan: dayEnd)
        .get();

    // Ambil ID slotRef (Slots/{id})
    return snapshot.docs
        .map((doc) => (doc["slotId"] as DocumentReference))
        .toList();
  }

  // MENYIMPAN BOOKING DENGAN NOMOR URUT (BOOKCODE)
  Future<String> createBooking({
    required LabModel lab,
    required SlotModel slot,
    required String userId,
    required String nama,
    required String nim,
    required String tujuan,
    required int jumlahOrang,
  }) async {
    final labRef = _firestore.doc("Labs/${lab.id}");
    final slotRef = _firestore.doc("Slots/${slot.id}");
    final userRef = _firestore.doc("Users/$userId");
    final slotDoc = await slotRef.get();
    if (slotDoc.exists && slotDoc["is_booked"] == true) {
      return "SLOT_TIDAK_TERSEDIA";
    }

    // Hitung bookCode seperti biasa
    final dayStart = DateTime(
      slot.slotStart.year,
      slot.slotStart.month,
      slot.slotStart.day,
    );
    final nextDay = dayStart.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collectionName)
        .where("date", isGreaterThanOrEqualTo: dayStart)
        .where("date", isLessThan: nextDay)
        .get();

    final nomorUrut = (snapshot.docs.length + 1).toString().padLeft(3, '0');
    final dateKey =
        "${dayStart.year}${dayStart.month.toString().padLeft(2, '0')}${dayStart.day.toString().padLeft(2, '0')}";

    final bookCode = "${slot.slotCode}/$dateKey/$nomorUrut";

    // SIMPAN BOOKING
    await _firestore.collection(_collectionName).add({
      "labId": labRef,
      "slotId": slotRef,
      "userId": userRef,
      "labName": lab.labName,
      "slot_start": Timestamp.fromDate(slot.slotStart),
      "slot_end": Timestamp.fromDate(slot.slotEnd),
      "date": Timestamp.fromDate(dayStart),
      "bookCode": bookCode,
      "nama": nama,
      "nim": nim,
      "tujuan": tujuan,
      "jumlahOrang": jumlahOrang,
      "createdAt": FieldValue.serverTimestamp(),
      "isConfirmed": false,
      "isPresent": false,
    });

    // UPDATE SLOT JADI BOOKED
    await slotRef.update({"is_booked": true});

    return "SUCCESS";
  }
}
