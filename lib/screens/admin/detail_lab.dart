import 'package:flutter/material.dart';
import '../../models/labs/lab_model.dart';
import 'kelola_slot.dart';

class DetailLabScreen extends StatefulWidget {
  final LabModel lab;
  const DetailLabScreen({super.key, required this.lab});
  @override
  State<DetailLabScreen> createState() => _DetailLabScreenState();
}

class _DetailLabScreenState extends State<DetailLabScreen> {
  DateTime? selectedDate;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lab ${widget.lab.labName}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoTile("Kode Lab", widget.lab.labKode),
            _infoTile("Nama Lab", widget.lab.labName),
            _infoTile("Lokasi", widget.lab.labLocation),
            _infoTile("Kapasitas", widget.lab.labCapacity.toString()),
            _infoTile("Deskripsi", widget.lab.labDescription),
            const SizedBox(height: 24),
            const Text(
              "Kelola Jadwal & Slot Peminjaman",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDatePicker(context),

            const SizedBox(height: 24),
            _buildManageSlotButton(context),
          ],
        ),
      ),
    );
  }

Widget _infoTile(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== LABEL FIXED WIDTH =====
        SizedBox(
          width: 110, // atur sesuai kebutuhan biar sejajar
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6E7FF3),
                  Color(0xFF8D6BE8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
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
        ),

        const SizedBox(width: 12),

        // ===== VALUE (KANAN) =====
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: selectedDate == null
                ? ""
                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
          ),
          decoration: InputDecoration(
            hintText: "Pilih tanggal",
            labelText: "Tanggal",
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onTap: () => _openDatePicker(context),
        ),
      ],
    );
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Widget _buildManageSlotButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.access_time),
        label: const Text("Kelola Slot"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          // Tombol selalu aktif
          backgroundColor: const Color.fromRGBO(211, 158, 211, 1),
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          DateTime? dateToUse = selectedDate;
          // 1. Jika tanggal belum dipilih, tampilkan Date Picker secara sinkron
          if (dateToUse == null) {
            dateToUse = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            // Perbarui state jika tanggal dipilih dari date picker yang baru dibuka
            if (dateToUse != null) {
              setState(() => selectedDate = dateToUse);
            }
          }
          // 2. Jika tanggal berhasil didapatkan (baik dari state lama atau date picker baru), lakukan navigasi
          if (dateToUse != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    KelolaSlotScreen(lab: widget.lab, selectedDate: dateToUse!),
              ),
            );
          }
        },
      ),
    );
  }
}
