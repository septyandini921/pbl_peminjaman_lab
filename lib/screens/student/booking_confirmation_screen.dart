import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/labs/lab_model.dart';
import '../../models/slots/slot_model.dart';
import '../../models/booking/booking_model.dart';
import '../../service/slot_service.dart'; // TAMBAHKAN IMPORT INI
import '../../widgets/app_bar.dart';

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
  final SlotService _slotService = SlotService(); // TAMBAHKAN INI

  // Helper untuk menampilkan field read-only (child text)
  Widget _displayText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  // Format value yang bisa berupa String / DateTime / Timestamp / int (minutes from midnight)
  String _formatTimeValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is DateTime) {
      return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    }
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (value is int) {
      // assume it's minutes from midnight
      final h = (value ~/ 60).toString().padLeft(2, '0');
      final m = (value % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }
    // fallback
    return value.toString();
  }

  // Try multiple common field names to read start/end/duration in the slot model.
  dynamic _tryGetSlotField(dynamic slot, List<String> candidates) {
    for (final name in candidates) {
      try {
        final dyn = slot as dynamic;
        switch (name) {
          case 'startTime':
            return dyn.startTime;
          case 'start':
            return dyn.start;
          case 'timeStart':
            return dyn.timeStart;
          case 'slotStart':
            return dyn.slotStart;
          case 'start_at':
            return dyn.start_at;
          case 'from':
            return dyn.from;
          case 'startTimestamp':
            return dyn.startTimestamp;
          case 'startMinute':
            return dyn.startMinute;
          case 'startMinutes':
            return dyn.startMinutes;
          case 'endTime':
            return dyn.endTime;
          case 'end':
            return dyn.end;
          case 'timeEnd':
            return dyn.timeEnd;
          case 'slotEnd':
            return dyn.slotEnd;
          case 'end_at':
            return dyn.end_at;
          case 'to':
            return dyn.to;
          case 'endTimestamp':
            return dyn.endTimestamp;
          case 'endMinute':
            return dyn.endMinute;
          case 'endMinutes':
            return dyn.endMinutes;
          case 'duration':
            return dyn.duration;
          case 'length':
            return dyn.length;
          case 'durationMinutes':
            return dyn.durationMinutes;
          case 'minutes':
            return dyn.minutes;
          case 'durasi':
            return dyn.durasi;
          case 'timeLength':
            return dyn.timeLength;
          // Add more if your model uses different property names.
        }
      } catch (_) {
        // ignore and try next
      }
    }

    // If slot is a Map-like object we can try to access keys (useful if slot is a Map)
    try {
      if (slot is Map<String, dynamic>) {
        for (final name in candidates) {
          if (slot.containsKey(name)) return slot[name];
        }
      }
    } catch (_) {}

    return null;
  }

  // Compute end value from start+duration if end wasn't present
  dynamic _computeEndFromDuration(dynamic startVal, dynamic durationVal) {
    if (startVal == null || durationVal == null) return null;

    int? minutes;
    if (durationVal is int) {
      minutes = durationVal;
    } else if (durationVal is String) {
      final asInt = int.tryParse(durationVal);
      if (asInt != null) {
        minutes = asInt;
      } else {
        // If duration is string "HH:mm" treat this as a time not a length, ignore
        minutes = null;
      }
    }

    if (minutes == null) return null;

    if (startVal is Timestamp) {
      return startVal.toDate().add(Duration(minutes: minutes));
    }
    if (startVal is DateTime) {
      return startVal.add(Duration(minutes: minutes));
    }
    if (startVal is int) {
      // minutes from midnight
      return startVal + minutes;
    }
    if (startVal is String) {
      // try parse "HH:mm"
      final parts = startVal.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          final dt = DateTime.now().toUtc().add(
            Duration(hours: h, minutes: m),
          ); // arbitrary date
          final end = dt.add(Duration(minutes: minutes));
          // return as "HH:mm"
          return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
        }
      }
    }

    return null;
  }

  String _formatSlotTime(SlotModel slot) {
    final startCandidates = [
      'startTime',
      'start',
      'timeStart',
      'slotStart',
      'start_at',
      'from',
      'startTimestamp',
      'startMinute',
      'startMinutes',
      'start_min',
      'time_from',
    ];
    final endCandidates = [
      'endTime',
      'end',
      'timeEnd',
      'slotEnd',
      'end_at',
      'to',
      'endTimestamp',
      'endMinute',
      'endMinutes',
      'end_min',
      'finish',
    ];

    final durationCandidates = [
      'duration',
      'length',
      'durationMinutes',
      'minutes',
      'durasi',
      'timeLength',
      'slotLength',
      'durasiMenit',
    ];

    final startVal = _tryGetSlotField(slot, startCandidates);
    dynamic endVal = _tryGetSlotField(slot, endCandidates);

    // If end not present, try compute using duration
    if (endVal == null) {
      final durationVal = _tryGetSlotField(slot, durationCandidates);
      final computed = _computeEndFromDuration(startVal, durationVal);
      if (computed != null) {
        endVal = computed;
      }
    }

    final startStr = _formatTimeValue(startVal);
    final endStr = _formatTimeValue(endVal);

    if (startStr.isNotEmpty && endStr.isNotEmpty) {
      return '$startStr - $endStr';
    } else if (startStr.isNotEmpty) {
      return startStr;
    } else if (endStr.isNotEmpty) {
      return endStr;
    }

    // fallback to slotCode if no time fields found
    try {
      return (slot as dynamic).slotCode?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  // Widget input field dengan label gradien ungu sesuai gambar
  Widget _nimInputField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB5A8D5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7A73D1), Color(0xFFB5A8D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              'NIM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: nimCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                hintText: "2341760025",
                hintStyle: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black),
              validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputFieldWithGradientLabel({
    required String label,
    required Widget childInput,
    double labelWidth = 110,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB5A8D5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: labelWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7A73D1), Color(0xFFB5A8D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(child: childInput),
        ],
      ),
    );
  }

  // MODIFIED: Tambahkan update slot setelah booking berhasil
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

      // Simpan booking
      await _firestore.collection('Booking').add(booking.toFirestore());

      // UPDATE SLOT STATUS MENJADI BOOKED
      await _slotService.updateSlotBookedStatus(
        slotId: widget.slot.id,
        isBooked: true,
      );

      // Show modal upon success
      if (mounted) {
        _showPeminjamanBerhasilModal(context);
      }

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // MODIFIED: Tambahkan Navigator.pop dengan result "SUCCESS"
  void _showPeminjamanBerhasilModal(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Peminjaman Berhasil",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            "Silakan Tunggu Konfirmasi Melalui Notifikasi",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A73D1),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Tutup modal
                  Navigator.of(parentContext).pop("SUCCESS"); // RETURN SUCCESS KE SCREEN SEBELUMNYA
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black),
      validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
    );
  }

  Future<void> _dialogTambahTujuan() async {
    final TextEditingController ctrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tambah Tujuan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7A73D1),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: 'Masukkan tujuan',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB5A8D5),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB5A8D5),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF7A73D1),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7A73D1),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A73D1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        final text = ctrl.text.trim();
                        if (text.isNotEmpty) {
                          setState(() => tujuan = text);
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Peminjaman',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Tampilan Tanggal (read-only)
              _inputFieldWithGradientLabel(
                label: 'Tanggal Pinjam',
                childInput: _displayText(_formatDate(widget.selectedDate)),
              ),
              const SizedBox(height: 14),

              // Tampilan Slot (read-only)
              _inputFieldWithGradientLabel(
                label: 'Slot',
                childInput: _displayText(_formatSlotTime(widget.slot)),
              ),
              const SizedBox(height: 14),

              // NIM
              _nimInputField(),
              const SizedBox(height: 14),

              // Nama
              _inputFieldWithGradientLabel(
                label: 'Nama',
                childInput: _buildTextFormField(namaCtrl, "Masukkan Nama"),
              ),
              const SizedBox(height: 14),

              // Jumlah
              _inputFieldWithGradientLabel(
                label: 'Jumlah',
                childInput: _buildTextFormField(
                  jumlahCtrl,
                  "Masukkan jumlah orang",
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 14),

              // Tujuan
              _inputFieldWithGradientLabel(
                label: 'Tujuan',
                childInput: DropdownButtonFormField<String>(
                  value: tujuan,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    hintText: "Pilih Tujuan",
                    hintStyle: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "Kelas Pengganti",
                      child: Text("Kelas Pengganti"),
                    ),
                    DropdownMenuItem(
                      value: "Kerja Kelompok",
                      child: Text("Kerja Kelompok"),
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
              const SizedBox(height: 24),

              // Peraturan
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Peraturan:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "• Dilarang makan di dalam lab\n"
                        "• Dilarang menggunakan Lab melebihi kapasitas\n"
                        "• Menjaga kebersihan lab\n"
                        "• Mengembalikan barang yang telah dipinjam seperti semula\n"
                        "• Tidak menggunakan lab melebihi durasi slot yang tersedia\n"
                        "• Melakukan konfirmasi kehadiran pada asisten Lab",
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: isAgree,
                            onChanged: (v) => setState(() => isAgree = v!),
                          ),
                          const Expanded(
                            child: Text(
                              "*Saya bersedia mematuhi peraturan yang berlaku.",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4D55CC),
                        Color(0xFF7A73D1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submitBooking,
                    child: const Text(
                      "Lakukan Peminjaman",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    nimCtrl.dispose();
    jumlahCtrl.dispose();
    super.dispose();
  }
}