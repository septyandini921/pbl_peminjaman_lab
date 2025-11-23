import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/labs/lab_model.dart';
import '../../../models/slots/slot_model.dart';
import '../../../service/booking_service.dart';
import 'booking_confirmation_screen.dart';

class PeminjamanScreen extends StatefulWidget {
  final LabModel lab;

  const PeminjamanScreen({super.key, required this.lab});

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
  DateTime _selectedDate = DateTime.now();
  SlotModel? _selectedSlot;

  final BookingService _bookingService = BookingService();

  // DATE PICKER
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _selectedSlot = null;
      });
    }
  }

  // LOAD SLOTS
  Future<List<SlotModel>> _loadAvailableSlots() async {
    final allSlots = await _bookingService.getSlotsForLab(
      lab: widget.lab,
      date: _selectedDate,
    );

    return allSlots;
  }

  void _goToForm() {
    if (_selectedSlot == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeminjamanFormScreen(
          lab: widget.lab,
          slot: _selectedSlot!,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Peminjaman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LAB DETAIL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lab ${widget.lab.labKode} - ${widget.lab.labName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Lokasi: ${widget.lab.labLocation}'),
                    Text('Kapasitas: ${widget.lab.labCapacity} orang'),
                    const SizedBox(height: 8),
                    Text(
                      widget.lab.labDescription,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // DATE PICKER
            const Text(
              'Tanggal Peminjaman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SLOT PICKER
            const Text(
              'Pilih Slot Waktu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            FutureBuilder<List<SlotModel>>(
              future: _loadAvailableSlots(),
              builder: (context, slotSnap) {
                if (slotSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allSlots = slotSnap.data ?? [];

                return FutureBuilder<List<DocumentReference>>(
                  future: _bookingService.checkBookedSlots(
                    lab: widget.lab,
                    date: _selectedDate,
                  ),
                  builder: (context, bookedSnap) {
                    if (bookedSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bookedSlotIds = bookedSnap.data ?? [];

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allSlots.map((slot) {
                        final isBooked = bookedSlotIds.contains(
                          FirebaseFirestore.instance.doc("Slots/${slot.id}"),
                        );

                        final isSelected = _selectedSlot?.id == slot.id;

                        final start = slot.slotStart;
                        final end = slot.slotEnd;
                        final slotTime =
                            "${_formatTime(start)} - ${_formatTime(end)}";

                        return ChoiceChip(
                          label: Text(
                            slotTime,
                            style: TextStyle(color: Colors.white),
                          ),
                          selected: isSelected,
                          selectedColor: isBooked
                              ? Colors.red
                              : const Color(0xFF3949AB),
                          backgroundColor: isBooked ? Colors.red : Colors.green,
                          onSelected: (selected) {
                            if (isBooked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Slot ini sudah terpinjam"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _selectedSlot = selected ? slot : null;
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSlot != null ? _goToForm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3949AB),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Konfirmasi Peminjaman',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
