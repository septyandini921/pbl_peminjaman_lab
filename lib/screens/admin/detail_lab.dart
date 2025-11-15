import 'package:flutter/material.dart';
import '../../models/labs/lab_model.dart';

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
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.visible, 
              softWrap: true, 
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
        const Text(
          "Tanggal", 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),

        const SizedBox(height: 8),

        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: selectedDate == null 
                ? "" 
                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, 
              ),
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
}