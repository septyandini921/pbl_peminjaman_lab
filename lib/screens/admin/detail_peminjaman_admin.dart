import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking/booking_model.dart';
import '../../service/booking_service.dart';
import '../../service/slot_service.dart';

class DetailPeminjamanAdmin extends StatelessWidget {
  final BookingModel booking;

  const DetailPeminjamanAdmin({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingService();
    final slotService = SlotService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                // Tombol Kembali
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF4D55CC),
                        size: 20,
                      ),
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

                // Judul Peminjaman
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

                // Info Tanggal dan Slot
                _buildFigmaRow(
                  "Tanggal Pinjam",
                  "${slotStart.day}-${slotStart.month}-${slotStart.year}",
                ),

                _buildFigmaRow(
                  "Slot Pinjam",
                  "Slot : ${slotStart.hour}:${slotStart.minute.toString().padLeft(2, "0")} - ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, "0")}",
                ),

                _buildFigmaRow("Kode Pinjam", booking.bookCode),

                const SizedBox(height: 25),

                // Detail Peminjaman
                const Text(
                  "Detail Peminjaman",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                _buildFigmaRow("NIM", booking.bookNim),
                _buildFigmaRow("Nama", booking.bookBy),
                _buildFigmaRow(
                  "Jumlah Orang",
                  booking.participantCount.toString(),
                ),
                _buildFigmaRow("Tujuan", booking.bookPurpose),

                // Status Kehadiran (hanya muncul jika sudah dikonfirmasi)
                if (booking.isConfirmed) ...[
                  const SizedBox(height: 25),
                  const Text(
                    "Status Kehadiran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildFigmaRow(
                    "Kehadiran",
                    booking.isPresent ? "Hadir" : "Tidak Hadir",
                  ),
                ],

                const SizedBox(height: 40),

                // Tombol Konfirmasi dan Tolak (hanya muncul jika belum dikonfirmasi/ditolak)
                if (showButtons)
                  Column(
                    children: [
                      // Tombol Konfirmasi
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            showConfirmDialog(
                              context: context,
                              title: "Apakah anda yakin mengkonfirmasi peminjaman?",
                              confirmText: "Konfirmasi",
                              confirmColor: Colors.green,
                              onYes: () async {
                                try {
                                  await bookingService.setApproved(booking.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Peminjaman berhasil dikonfirmasi'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text('Gagal mengkonfirmasi: $e'),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Konfirmasi",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Tombol Tolak
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            showConfirmDialog(
                              context: context,
                              title: "Apakah anda yakin menolak peminjaman?",
                              confirmText: "Tolak",
                              confirmColor: Colors.redAccent,
                              onYes: () async {
                                try {
                                  // Ambil slotId dan kembalikan slot menggunakan method atomic
                                  final slotId = await bookingService.setRejected(booking.id);
                                  
                                  if (slotId != null) {
                                    // Gunakan releaseSlot yang lebih aman dengan transaksi
                                    final success = await slotService.releaseSlot(slotId: slotId);
                                    
                                    if (!success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.warning_amber, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('Peminjaman ditolak, tapi gagal melepaskan slot'),
                                            ],
                                          ),
                                          backgroundColor: Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('Peminjaman berhasil ditolak'),
                                            ],
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('Slot tidak ditemukan'),
                                            ],
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                  
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text('Gagal menolak peminjaman: $e'),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Tolak",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget untuk baris informasi dengan desain Figma
  Widget _buildFigmaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // Label container
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

          // Value container
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
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog konfirmasi yang lebih baik
  Future<void> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onYes,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: confirmColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    confirmText == "Konfirmasi" ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 48,
                    color: confirmColor,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7986CB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7986CB),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // Tombol Konfirmasi/Tolak
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onYes();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}