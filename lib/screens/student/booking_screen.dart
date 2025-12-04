import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/labs/lab_model.dart';
import '../../../models/slots/slot_model.dart';
import '../../../service/booking_service.dart';
import 'booking_confirmation_screen.dart';
import '../../widgets/app_bar.dart';

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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
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

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id').format(date);
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(actions: []),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lab Details Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science,
                            color: Color(0xFF3949AB), size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'Lab ${widget.lab.labKode} - ${widget.lab.labName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lokasi: ${widget.lab.labLocation}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Kapasitas: ${widget.lab.labCapacity} orang',
                      style: const TextStyle(fontSize: 16),
                    ),
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

            // Tanggal peminjaman dengan label ungu dan kotak putih
            const Text(
              'Tanggal Peminjaman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _selectDate(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFA395E6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Tanggal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Slot Picker
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
                    if (bookedSnap.connectionState ==
                        ConnectionState.waiting) {
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
                            style: const TextStyle(color: Colors.white),
                          ),
                          selected: isSelected,
                          selectedColor:
                              isBooked ? Colors.red : const Color(0xFF3949AB),
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

            // Tombol Lakukan Peminjaman dengan gradasi
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: _selectedSlot != null ? _goToForm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lakukan Peminjaman',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}