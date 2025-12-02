import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/labs/lab_model.dart';
import '../../../models/slots/slot_model.dart';
import '../../models/booking/booking_model.dart';

class PeminjamanFormScreen extends StatefulWidget {
  final LabModel lab;
  final SlotModel slot;
  final DateTime selectedDate;

  const PeminjamanFormScreen({
    super.key,
    required this.lab,
    required this.slot,
    required this.selectedDate,
  });

  @override
  State<PeminjamanFormScreen> createState() => _PeminjamanFormScreenState();
}

class _PeminjamanFormScreenState extends State<PeminjamanFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaCtrl = TextEditingController();
  final TextEditingController nimCtrl = TextEditingController();
  final TextEditingController jumlahCtrl = TextEditingController();
  bool isAgree = false;

  String? tujuan;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (tujuan == null || tujuan!.isEmpty) {
      _showSnack("Pilih atau isi tujuan!");
      return;
    }
    if (!isAgree) {
      _showSnack("Anda harus menyetujui peraturan!");
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnack("User tidak login!");
      return;
    }

    try {
      final slotRef = _firestore.collection('Slots').doc(widget.slot.id);
      final bookCode = await generateBookCode(
        slotCode: widget.slot.slotCode,
        date: widget.selectedDate,
      );

      final booking = BookingModel(
        id: '',
        userRef: _firestore.collection('Users').doc(userId),
        slotRef: slotRef,
        bookCode: bookCode,
        bookBy: namaCtrl.text,
        bookNim: nimCtrl.text,
        bookPurpose: tujuan!,
        participantCount: int.tryParse(jumlahCtrl.text) ?? 1,
        isConfirmed: false,
        isRejected: false,
        isPresent: false,
      );

      await _firestore.collection('Booking').add(booking.toFirestore());

      _showSnack("Peminjaman berhasil diajukan!");
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Gagal menyimpan: $e");
    }
  }

  Future<String> generateBookCode({
    required String slotCode,
    required DateTime date,
  }) async {
    final tanggal =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final snap = await FirebaseFirestore.instance.collection("Booking").get();

    final nomorUrut = (snap.docs.length + 1).toString().padLeft(4, '0');

    return "$slotCode/$tanggal/$nomorUrut";
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _dialogTambahTujuan() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Tambah Tujuan Baru"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "Masukkan tujuan"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() => tujuan = ctrl.text);
              Navigator.pop(c);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Widget _fieldCard({required String label, required Widget child}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Peminjaman"),
        backgroundColor: const Color(0xFF3949AB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _fieldCard(
                label: "Nama",
                child: TextFormField(
                  controller: namaCtrl,
                  decoration: _inputDecoration("Masukkan Nama"),
                  validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                ),
              ),
              _fieldCard(
                label: "NIM",
                child: TextFormField(
                  controller: nimCtrl,
                  decoration: _inputDecoration("Masukkan NIM"),
                  validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                ),
              ),
              _fieldCard(
                label: "Jumlah Orang",
                child: TextFormField(
                  controller: jumlahCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("0"),
                  validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                ),
              ),

              _fieldCard(
                label: "Tujuan",
                child: DropdownButtonFormField<String>(
                  value: tujuan,
                  decoration: _inputDecoration("Pilih Tujuan"),
                  items: const [
                    DropdownMenuItem(
                      value: "Kelas Pengganti",
                      child: Text("Kelas Pengganti"),
                    ),
                    DropdownMenuItem(
                      value: "Kerja Kelompok",
                      child: Text("Kerja Kelompok"),
                    ),
                    DropdownMenuItem(
                      value: "Lainnya",
                      child: Text("Tambah tujuan baru..."),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == "Lainnya") {
                      _dialogTambahTujuan();
                    } else {
                      setState(() => tujuan = v);
                    }
                  },
                  validator: (v) => v == null ? "Wajib dipilih" : null,
                ),
              ),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Peraturan:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "• Menggunakan laboratorium sesuai jadwal.\n"
                        "• Menjaga kebersihan dan keamanan alat.\n"
                        "• Tidak membawa barang lab tanpa izin.\n"
                        "• Bertanggung jawab atas kerusakan.\n"
                        "• Mengembalikan tepat waktu.\n",
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: isAgree,
                            onChanged: (v) => setState(() => isAgree = v!),
                          ),
                          const Expanded(
                            child: Text(
                              "Saya setuju dengan aturan yang berlaku.",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Ajukan Peminjaman",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
