import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_bottom_navbar.dart';
import '../../models/booking/booking_model.dart';
import '../../service/booking_service.dart';

class PermintaanPeminjamanScreen extends StatelessWidget {
  const PermintaanPeminjamanScreen({super.key});

  // ======================== HEADER CUSTOM ==========================
  Widget _customHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 45, bottom: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4D55CC), Color(0xFF38339C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Center(
        child: Text(
          "SIMPEL",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: _customHeader(),
      ),

      // ======================== BODY ==========================
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getPendingBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final booking = snapshot.data ?? [];

          if (booking.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada data peminjaman.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: booking.length,
            itemBuilder: (context, index) {
              final b = booking[index];

              return FutureBuilder(
                future: Future.wait([
                  FirebaseFirestore.instance.doc(b.slotRef!.path).get(),
                  FirebaseFirestore.instance.doc(b.userRef!.path).get(),
                ]),
                builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snap2) {
                  if (!snap2.hasData) {
                    return const SizedBox();
                  }

                  final slot = snap2.data![0];
                  final user = snap2.data![1];

                  final slotStart = (slot["slot_start"] as Timestamp).toDate();
                  final slotEnd = (slot["slot_end"] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= BOOKING CODE =================
                          Text(
                            "Kode: ${b.bookCode}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ================= USER INFO =================
                          Text(
                            "Peminjam: ${b.bookBy} (${b.bookNim})",
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 8),

                          // ================= SLOT INFO =================
                          Text(
                            "Waktu: ${slotStart.hour}:${slotStart.minute.toString().padLeft(2, '0')} "
                            "- ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 8),

                          // ================= STATUS =================
                          Text(
                            b.isConfirmed
                                ? "Status: Sudah dikonfirmasi"
                                : "Status: Menunggu konfirmasi",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: b.isConfirmed
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
