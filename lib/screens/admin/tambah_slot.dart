import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/labs/lab_model.dart';
import '../../models/slots/slot_model.dart';
import '../../service/slot_service.dart';

class SlotFormDialog {
  static Future<void> show(
    BuildContext context, {
    required LabModel lab,
    required DateTime selectedDate,
    SlotModel? slotToEdit,
  }) async {
    final SlotService slotService = SlotService();

    final TextEditingController kodeController = TextEditingController(
      text: slotToEdit?.slotCode ?? "",
    );
    final TextEditingController slotNameController = TextEditingController(
      text: slotToEdit?.slotName ?? "",
    );

    TimeOfDay startTime = slotToEdit != null
        ? TimeOfDay.fromDateTime(slotToEdit.slotStart.toLocal())
        : const TimeOfDay(hour: 7, minute: 0);

    TimeOfDay endTime = slotToEdit != null
        ? TimeOfDay.fromDateTime(slotToEdit.slotEnd.toLocal())
        : const TimeOfDay(hour: 9, minute: 0);

    final bool isEdit = slotToEdit != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.all(16),

              title: Text(
                isEdit ? "Edit Slot" : "Tambah Slot Baru",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              content: Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: kodeController,
                          decoration: const InputDecoration(
                            labelText: "Kode Slot",
                            hintText: "Misal: S01",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: slotNameController,
                          decoration: const InputDecoration(
                            labelText: "Nama Slot ",
                            hintText: "Misal: Slot 1",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tanggal",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              DateFormat('dd MMMM yyyy').format(selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Waktu Mulai"),
                            TextButton(
                              child: Text(startTime.format(context)),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                );
                                if (picked != null) {
                                  setStateDialog(() => startTime = picked);
                                }
                              },
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Waktu Selesai"),
                            TextButton(
                              child: Text(endTime.format(context)),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                );
                                if (picked != null) {
                                  setStateDialog(() => endTime = picked);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  child: const Text("Batal"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text(isEdit ? "Simpan" : "Tambah"),
                  onPressed: () async {
                    if (kodeController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Kode Slot wajib diisi")),
                      );
                      return;
                    }

                    try {
                      if (isEdit) {
                        await slotService.updateSlot(
                          slotId: slotToEdit!.id,
                          slotCode: kodeController.text.trim(),
                          slotName: slotNameController.text.trim(),
                          slotStart: DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            startTime.hour,
                            startTime.minute,
                          ),
                          slotEnd: DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            endTime.hour,
                            endTime.minute,
                          ),
                        );
                      } else {
                        await slotService.addSlot(
                          lab: lab,
                          slotDate: selectedDate,
                          startTime: startTime,
                          endTime: endTime,
                          slotCode: kodeController.text.trim(),
                          slotName: slotNameController.text.trim(),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
