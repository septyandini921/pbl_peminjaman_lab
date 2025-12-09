//C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\lib\screens\student\detail_peminjaman_student.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking/booking_model.dart';
import '../../service/booking_service.dart';

class DetailPeminjamanStudent extends StatelessWidget {
  final BookingModel booking;

  const DetailPeminjamanStudent({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Detail Peminjaman",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4D55CC),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.doc(booking.slotRef!.path).get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final slot = snap.data!;
          final slotStart = (slot["slot_start"] as Timestamp).toDate();
          final slotEnd = (slot["slot_end"] as Timestamp).toDate();

          String statusText = "Menunggu Konfirmasi";
          Color statusColor = Colors.orange;
          Color statusBg = Colors.orange.withOpacity(0.1);

          if (booking.isRejected) {
            statusText = "Ditolak";
            statusColor = Colors.red;
            statusBg = Colors.red.withOpacity(0.1);
          } else if (booking.isConfirmed) {
            statusText = "Disetujui";
            statusColor = Colors.green;
            statusBg = Colors.green.withOpacity(0.1);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Status Peminjaman",
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                _buildFigmaRow("Kode Booking", booking.bookCode),
                _buildFigmaRow("Tanggal",
                    "${slotStart.day}-${slotStart.month}-${slotStart.year}"),
                _buildFigmaRow("Jam",
                    "${slotStart.hour}:${slotStart.minute.toString().padLeft(2, "0")} - ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, "0")}"),

                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 10),

                const Text(
                  "Detail Data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                _buildFigmaRow("NIM", booking.bookNim),
                _buildFigmaRow("Nama", booking.bookBy),
                _buildFigmaRow(
                    "Jumlah Orang", "${booking.participantCount} Orang"),
                _buildFigmaRow("Tujuan", booking.bookPurpose),

                if (booking.isConfirmed) ...[
                  const SizedBox(height: 25),
                  const Text(
                    "Kehadiran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildFigmaRow(
                    "Status",
                    booking.isPresent ? "Hadir" : "Absen",
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFigmaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 120, 
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7986CB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}