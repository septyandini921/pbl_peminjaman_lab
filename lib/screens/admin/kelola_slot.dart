import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/labs/lab_model.dart';
import '../../models/slots/slot_model.dart';
import '../../service/slot_service.dart';
import 'tambah_slot.dart';

class KelolaSlotScreen extends StatefulWidget {
  final LabModel lab;
  final DateTime selectedDate;

  const KelolaSlotScreen({
    super.key,
    required this.lab,
    required this.selectedDate,
  });

  @override
  State<KelolaSlotScreen> createState() => _KelolaSlotScreenState();
}

class _KelolaSlotScreenState extends State<KelolaSlotScreen> {
  final SlotService _slotService = SlotService();
  late Stream<List<SlotModel>> _slotsStream;

  @override
  void initState() {
    super.initState();
    _slotsStream = _slotService.getSlotsStreamByDate(
      lab: widget.lab,
      selectedDate: widget.selectedDate,
    );
  }

  void _toggleSlotStatus(SlotModel slot, bool newValue) async {
    try {
      await _slotService.updateSlotStatus(slotId: slot.id, isOpen: newValue);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengubah status: $e")));
    }
  }

  void _deleteSlot(String slotId) async {
    try {
      await _slotService.deleteSlot(slotId: slotId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Slot berhasil dihapus")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghapus slot: $e")));
    }
  }

  Widget _buildSlotRow(SlotModel slot, int index) {
    final String startTime =
        DateFormat('HH.mm').format(slot.slotStart.toLocal());
    final String endTime =
        DateFormat('HH.mm').format(slot.slotEnd.toLocal());

    return GestureDetector(
      onTap: () => SlotFormDialog.show(
        context,
        lab: widget.lab,
        selectedDate: widget.selectedDate,
        slotToEdit: slot,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    slot.slotName.isNotEmpty ? slot.slotName : slot.slotCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: slot.isOpen,
                    onChanged: (v) => _toggleSlotStatus(slot, v),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        startTime,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text("-"),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        endTime,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteSlot(slot.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================== UI LABEL FIGMA ===============================
  Widget _infoTile(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label kiri (gradient + rounded + center)
          Container(
            constraints: const BoxConstraints(
              minWidth: 110, // bikin semua label sejajar rapi
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Value kanan (border + rounded)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat("d MMMM yyyy").format(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(title: Text("Kelola Slot: ${widget.lab.labName}")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => SlotFormDialog.show(
          context,
          lab: widget.lab,
          selectedDate: widget.selectedDate,
        ),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoTile("Kode Lab", widget.lab.labKode),
            _infoTile("Nama Lab", widget.lab.labName),
            _infoTile("Lokasi", widget.lab.labLocation),
            _infoTile("Deskripsi", widget.lab.labDescription),
            _infoTile("Tanggal", formattedDate),

            const SizedBox(height: 20),
            const Text(
              "Daftar Slot",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder<List<SlotModel>>(
              stream: _slotsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Text("Slot Belum Tersedia"),
                    ),
                  );
                }

                final slots = snapshot.data!;
                return ListView.builder(
                  itemCount: slots.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, i) {
                    return _buildSlotRow(slots[i], i);
                  },
                );
              },
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
