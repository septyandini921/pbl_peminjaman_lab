import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/labs/lab_model.dart';
import '../../models/slots/slot_model.dart';
import '../../service/booking_service.dart';
import '../../service/slot_service.dart';
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
  final SlotService _slotService = SlotService();

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

  // GUNAKAN STREAM UNTUK REAL-TIME UPDATE
  Stream<List<SlotModel>> _getAvailableSlotsStream() {
    return _slotService.getSlotsStreamByDate(
      lab: widget.lab,
      selectedDate: _selectedDate,
    );
  }

  void _goToForm() async {
    if (_selectedSlot == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeminjamanFormScreen(
          lab: widget.lab,
          slot: _selectedSlot!,
          selectedDate: _selectedDate,
        ),
      ),
    );

    // Refresh slot list setelah booking
    if (result == "SUCCESS") {
      setState(() {
        _selectedSlot = null; // Reset selected slot
      });
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Peminjaman'),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LAB DETAIL
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Lokasi: ${widget.lab.labLocation}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Kapasitas: ${widget.lab.labCapacity} orang'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.lab.labDescription,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF3949AB)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SLOT PICKER - MENGGUNAKAN STREAMBUILDER UNTUK REAL-TIME UPDATE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Slot Waktu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Legend
                Row(
                  children: [
                    _buildLegend(Colors.green, 'Tersedia'),
                    const SizedBox(width: 8),
                    _buildLegend(Colors.red, 'Penuh'),
                    const SizedBox(width: 8),
                    _buildLegend(Colors.grey, 'Tutup'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<SlotModel>>(
              stream: _getAvailableSlotsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allSlots = snapshot.data ?? [];

                if (allSlots.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada slot tersedia untuk tanggal ini',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allSlots.map((slot) {
                    // CEK LANGSUNG DARI SLOT MODEL
                    final isBooked = slot.isBooked;
                    final isOpen = slot.isOpen;
                    final isSelected = _selectedSlot?.id == slot.id;

                    final start = slot.slotStart;
                    final end = slot.slotEnd;
                    final slotTime = "${_formatTime(start)} - ${_formatTime(end)}";

                    // Tentukan warna berdasarkan status
                    Color backgroundColor;
                    Color selectedColor;
                    
                    if (isBooked) {
                      // Slot sudah dibooking -> MERAH
                      backgroundColor = Colors.red;
                      selectedColor = Colors.red.shade700;
                    } else if (!isOpen) {
                      // Slot ditutup -> ABU-ABU
                      backgroundColor = Colors.grey;
                      selectedColor = Colors.grey.shade700;
                    } else {
                      // Slot tersedia -> HIJAU
                      backgroundColor = Colors.green;
                      selectedColor = const Color(0xFF3949AB);
                    }

                    return ChoiceChip(
                      label: Text(
                        slotTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: selectedColor,
                      backgroundColor: backgroundColor,
                      onSelected: (selected) {
                        // Cek apakah slot bisa dipilih
                        if (isBooked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Slot ini sudah terpinjam"),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        if (!isOpen) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Slot ini sedang ditutup"),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _selectedSlot = selected ? slot : null;
                        });
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40),

            // CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSlot != null ? _goToForm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3949AB),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _selectedSlot != null 
                    ? 'Konfirmasi Peminjaman'
                    : 'Pilih Slot Terlebih Dahulu',
                  style: TextStyle(
                    fontSize: 18,
                    color: _selectedSlot != null ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk legend
  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}