import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/aslab_bottom_navbar.dart';
import '../../models/booking/booking_model.dart';
import '../../service/booking_service.dart';
import 'detail_peminjaman_aslab.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  DateTime? selectedDate;

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

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      selectedDate == null
                          ? "Pilih tanggal"
                          : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: bookingService.getAllConfirmedBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allBookings = snapshot.data ?? [];
                final filtered = allBookings.where((b) {
                  if (selectedDate != null) {
                    final dateString =
                        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

                    if (!b.bookCode.contains(dateString)) return false;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "Tidak ada peminjaman.",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final b = filtered[index];

                    return FutureBuilder(
                      future: Future.wait([
                        FirebaseFirestore.instance.doc(b.slotRef!.path).get(),
                        FirebaseFirestore.instance.doc(b.userRef!.path).get(),
                      ]),
                      builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snap2) {
                        if (!snap2.hasData) return const SizedBox();

                        final slot = snap2.data![0];
                        final slotStart = (slot["slot_start"] as Timestamp)
                            .toDate();
                        final slotEnd = (slot["slot_end"] as Timestamp)
                            .toDate();

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailPeminjamanAslab(booking: b),
                              ),
                            );
                          },
                          child: Card(
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
                                  Text(
                                    "Peminjaman: ${b.bookCode}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Peminjam: ${b.bookBy} (${b.bookNim})",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Waktu: ${slotStart.hour}:${slotStart.minute.toString().padLeft(2, '0')} "
                                    "- ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),

                                  // STATUS KONFIRMASI (Tetap ada)
                                  Text(
                                    b.isRejected
                                        ? "Status: Ditolak"
                                        : b.isConfirmed
                                        ? "Status: Sudah dikonfirmasi"
                                        : "Status: Menunggu konfirmasi",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: b.isRejected
                                          ? Colors.red
                                          : b.isConfirmed
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  Text(
                                    b.isPresent == null
                                        ? "Kehadiran: Belum dikonfirmasi"
                                        : b.isPresent == true
                                        ? "Kehadiran: Hadir"
                                        : "Kehadiran: Tidak Hadir",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: b.isPresent == null
                                          ? Colors.orange
                                          : b.isPresent == true
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
