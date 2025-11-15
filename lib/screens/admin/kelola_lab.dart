import 'package:flutter/material.dart';
import '../../../widgets/admin_bottom_navbar.dart';
import '../../../service/lab_service.dart';
import '../../../models/labs/lab_model.dart';

class KelolaLabScreen extends StatelessWidget {
  const KelolaLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labService = LabService();

    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Lab")),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),

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
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text(
                    "Daftar Lab Tersedia",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                ],
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

                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${lab.labKode} (${lab.labLocation})",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal form tambah lab
  void _showAddLabModal(BuildContext context, LabService labService) {
    final kodeC = TextEditingController();
    final namaC = TextEditingController();
    final lokasiC = TextEditingController();
    final kapasitasC = TextEditingController();
    final deskripsiC = TextEditingController();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tambah Lab Baru",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: kodeC,
                decoration: const InputDecoration(labelText: "Kode Lab"),
              ),
              TextField(
                controller: namaC,
                decoration: const InputDecoration(labelText: "Nama Lab"),
              ),
              TextField(
                controller: lokasiC,
                decoration: const InputDecoration(labelText: "Lokasi"),
              ),
              TextField(
                controller: kapasitasC,
                decoration: const InputDecoration(labelText: "Kapasitas"),
              ),
              TextField(
                controller: deskripsiC,
                decoration:
                    const InputDecoration(labelText: "Deskripsi Lab"),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (kodeC.text.isEmpty ||
                      namaC.text.isEmpty ||
                      lokasiC.text.isEmpty ||
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
                child: const Text("Tambah"),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
