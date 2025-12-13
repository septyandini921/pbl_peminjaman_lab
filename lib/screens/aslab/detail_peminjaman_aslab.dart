import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking/booking_model.dart';
import '../../service/booking_service.dart';

class DetailPeminjamanAslab extends StatelessWidget {
  final BookingModel booking;

  const DetailPeminjamanAslab({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          "SIMPEL",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4D55CC),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance.doc(booking.slotRef!.path).get(),
        ]),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final slot = snap.data![0];

          final slotStart = (slot["slot_start"] as Timestamp).toDate();
          final slotEnd = (slot["slot_end"] as Timestamp).toDate();

          String statusText = "*Peminjaman Menunggu Konfirmasi";
          Color statusColor = Colors.orange;

          if (booking.isRejected) {
            statusText = "*Peminjaman Ditolak";
            statusColor = Colors.red;
          } else if (booking.isConfirmed) {
            statusText = "*Peminjaman Disetujui";
            statusColor = Colors.green;
          }

          bool showButtons = !booking.isConfirmed && !booking.isRejected;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  key: const Key('btn_back'),
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF4D55CC), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Kembali",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4D55CC),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                    children: [
                      const TextSpan(
                        text: "Peminjaman ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: booking.bookCode),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: statusColor,
                  ),
                ),

                const SizedBox(height: 25),

                _buildFigmaRow("Tanggal Pinjam",
                    "${slotStart.day}-${slotStart.month}-${slotStart.year}"),

                _buildFigmaRow("Slot Pinjam",
                    "Slot : ${slotStart.hour}:${slotStart.minute.toString().padLeft(2, "0")} - ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, "0")}"),

                _buildFigmaRow("Kode Pinjam", booking.bookCode),

                const SizedBox(height: 25),

                const Text(
                  "Detail Peminjaman",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                _buildFigmaRow("NIM", booking.bookNim),
                _buildFigmaRow("Nama", booking.bookBy),
                _buildFigmaRow("Jumlah Orang", booking.participantCount.toString()),
                _buildFigmaRow("Tujuan", booking.bookPurpose),

                if (booking.isConfirmed) ...[
                  const SizedBox(height: 25),
                  const Text(
                    "Status Kehadiran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildFigmaRow("Kehadiran:", booking.isPresent ? "Hadir" : "Tidak Hadir")
                ],

                const SizedBox(height: 30),
                if (booking.isConfirmed) ...[
                  const Text(
                    "Konfirmasi Kehadiran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // Tombol Hadir
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                    key: Key('btn_hadir'),
                      onPressed: booking.isPresent
                          ? null
                          : () async {
                              bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi'),
                                  content: const Text(
                                      'Apakah anda yakin akan mengonfirmasi status kehadiran sebagai Hadir?'),
                                  actions: [
                                    TextButton(
                                    key: const Key('dialog_cancel'),
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      key: const Key('dialog_yes'),
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Ya'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await bookingService.setPresent(booking.id);

                                // tutup HALAMAN detail, kembali ke list
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Hadir",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
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
            width: 130,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7986CB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
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