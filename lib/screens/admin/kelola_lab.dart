import 'package:flutter/material.dart';
import '../../../widgets/admin_bottom_navbar.dart';
import '../../../widgets/app_bar.dart';
import '../../../service/lab_service.dart';
import '../../../models/labs/lab_model.dart';
import 'detail_lab.dart';

class KelolaLabScreen extends StatelessWidget {
  const KelolaLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labService = LabService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(actions: []),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddLabModal(context, labService);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Daftar Lab Tersedia",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<List<LabModel>>(
                stream: labService.getLabs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Belum ada data lab"));
                  }

                  final labs = snapshot.data!;

                  return ListView.builder(
                    itemCount: labs.length,
                    itemBuilder: (context, index) {
                      final lab = labs[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailLabScreen(lab: lab),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${lab.labKode} (${lab.labLocation})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(lab.labName),
                                ],
                              ),

                              Switch(
                                value: lab.isShow,
                                onChanged: (value) {
                                  labService.updateIsShow(lab.id, value);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
  void _showAddLabModal(BuildContext context, LabService labService) {
    final kodeC = TextEditingController();
    final namaC = TextEditingController();
    final lokasiC = TextEditingController();
    final kapasitasC = TextEditingController();
    final deskripsiC = TextEditingController();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              Widget figmaField(
                String label,
                TextEditingController controller, {
                bool number = false,
              }) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C4CD7), Color(0xFF8A7BE3)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey),
                          ),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: controller,
                            keyboardType: number
                                ? TextInputType.number
                                : TextInputType.text,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 30),
                        const Text(
                          "Tambah Lab Baru",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 26),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    figmaField("Kode Lab", kodeC),
                    figmaField("Nama Lab", namaC),
                    figmaField("Lokasi", lokasiC),
                    figmaField("Kapasitas", kapasitasC, number: true),
                    figmaField("Deskripsi", deskripsiC),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (kodeC.text.isEmpty ||
                              namaC.text.isEmpty ||
                              lokasiC.text.isEmpty ||
                              kapasitasC.text.isEmpty ||
                              deskripsiC.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Semua field harus diisi!"),
                              ),
                            );
                            return;
                          }

                          await labService.addLab(
                            labKode: kodeC.text,
                            labName: namaC.text,
                            labLocation: lokasiC.text,
                            labCapacity: int.parse(kapasitasC.text),
                            labDescription: deskripsiC.text,
                          );

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Tambah",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
