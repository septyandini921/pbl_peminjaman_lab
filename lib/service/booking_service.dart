//C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\lib\service\booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/labs/lab_model.dart';
import '../models/slots/slot_model.dart';
import '../models/booking/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = "Booking";

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

  Future<String> createBooking({
    required LabModel lab,
    required SlotModel slot,
    required String userId,
    required String nama,
    required String nim,
    required String tujuan,
    required int participantCount,
  }) async {
    final slotRef = _firestore.doc("Slots/${slot.id}");
    final userRef = _firestore.doc("Users/$userId");

    final slotDoc = await slotRef.get();
    if (slotDoc.exists && slotDoc["is_booked"] == true) {
      return "SLOT_TIDAK_TERSEDIA";
    }

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

    final nomorUrut = (snapshot.docs.length + 1).toString().padLeft(4, '0');

    final tanggalFormat =
        "${dayStart.year}-${dayStart.month.toString().padLeft(2, '0')}-${dayStart.day.toString().padLeft(2, '0')}";

    final bookCode = "${slot.slotCode}/$tanggalFormat/$nomorUrut";

    await _firestore.collection(_collectionName).add({
      "book_by": nama,
      "book_nim": nim,
      "book_purpose": tujuan,
      "book_code": bookCode,
      "participant_count": participantCount,

      "slotId": slotRef,
      "user_id": userRef,

      "slot_start": Timestamp.fromDate(slot.slotStart),
      "slot_end": Timestamp.fromDate(slot.slotEnd),

      "is_confirmed": false,
      "is_rejected": false,
      "is_present": false,

      "createdAt": FieldValue.serverTimestamp(),
    });

    await slotRef.update({"is_booked": true});

    return "SUCCESS";
  }

  Stream<List<BookingModel>> getPendingBookings() {
    return _firestore
        .collection(_collectionName)
        .where("is_confirmed", isEqualTo: false)
        .where("is_rejected", isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<BookingModel>> getAllBookings() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required bool isConfirmed,
  }) async {
    await _firestore.collection(_collectionName).doc(bookingId).update({
      "is_confirmed": isConfirmed,
    });
  }

  Future<void> setApproved(String bookingId) async {
    await _firestore.collection(_collectionName).doc(bookingId).update({
      'is_confirmed': true,
      'is_rejected': false,
    });
  }

  Future<void> setRejected(String bookingId) async {
    await _firestore.collection(_collectionName).doc(bookingId).update({
      'is_confirmed': false,
      'is_rejected': true,
    });
  }

  // Hitung pengajuan yg belum di konfirmasi
  Stream<int> getPendingBookingsCountWeekly() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _firestore
        .collection(_collectionName)
        .where("is_confirmed", isEqualTo: false)
        .where("is_rejected", isEqualTo: false)
        .where("createdAt", isGreaterThanOrEqualTo: sevenDaysAgo)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Hitung jumlah SEMUA Booking (dikonfirmasi, di rejected dan disetujui)
  Stream<int> getAllBookingsCountWeekly() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(_collectionName)
        .where("createdAt", isGreaterThanOrEqualTo: sevenDaysAgo)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  //  LAB paling banyak dipinjam
  Stream<Map<String, int>> getMostBorrowedLabWeekly() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    return _firestore
        .collection(_collectionName)
        .where('is_confirmed', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .where('createdAt', isGreaterThan: sevenDaysAgo)
        .snapshots()
        .asyncMap((snapshot) async {
          final Map<String, int> labCount = {};

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;

            try {
              final DocumentReference? slotRef =
                  data['slotId'] as DocumentReference?;
              if (slotRef != null) {
                final slotDoc = await slotRef.get();
                final slotData = slotDoc.data() as Map<String, dynamic>?;
                if (slotData != null) {
                  final DocumentReference? labRef =
                      slotData['lab_ref'] as DocumentReference?;
                  if (labRef != null) {
                    final labId = labRef.id;
                    labCount[labId] = (labCount[labId] ?? 0) + 1;
                  }
                }
              }
            } catch (e) {
              print("Error processing booking document ${doc.id}: $e");
              continue;
            }
          }
          return labCount;
        });
  }

  Stream<List<BookingModel>> getAllConfirmedBookings() {
    return _firestore
        .collection("Booking")
        .where("is_confirmed", isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BookingModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> setPresent(String bookingId) async {
    await _firestore.collection(_collectionName).doc(bookingId).update({
      'is_present': true,
    });
  }
  Future<void> setNotPresent(String bookingId) async {
    await _firestore.collection(_collectionName).doc(bookingId).update({
      'is_present': false,
    });
  }

  
  Stream<List<BookingModel>> getBookingsByUser(String userId) {
    final userRef = _firestore.doc("Users/$userId");
    return _firestore
        .collection(_collectionName)
        .where("user_id", isEqualTo: userRef)
        // .orderBy("createdAt", descending: true)  // Comment this out temporarily
        .snapshots()
        .map(
          (snapshot) {
            // Sort in-memory instead
            final bookings = snapshot.docs
                .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
                .toList();
            
            bookings.sort((a, b) {
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            
            return bookings;
          },
        );
  }
}
