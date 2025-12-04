import 'package:flutter/material.dart';
import '../../widgets/student_bottom_navbar.dart'; // Mengimpor BottomNavBar
import '../../widgets/app_bar.dart'; // Mengimpor AppBar kustom yang sudah Anda buat

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan custom AppBar yang telah Anda buat
      appBar: CustomAppBar(actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white), // Tombol logout
          onPressed: () {
            // Fungsi logout yang sesuai
          },
        ),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Judul utama
            const Text(
              'Bagaimana cara mengajukan pinjam lab ruangan di SIMPEL ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),

            // Langkah 1: Daftar Lab Tersedia
            const Text(
              '1. Cek Ketersediaan Lab',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Daftar Lab dalam bentuk white card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.science,
                      color: Color(0xFF3949AB),
                    ),
                    title: const Text('Lab MMT Lt. 8B'),
                    subtitle: const Text('Ketuk untuk melihat detail peminjaman'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigasi jika diperlukan
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.science,
                      color: Color(0xFF3949AB),
                    ),
                    title: const Text('Lab DT Lt. 8B'),
                    subtitle: const Text('Ketuk untuk melihat detail peminjaman'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigasi jika diperlukan
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Langkah-langkah lainnya
            const Text(
              '2. Langkah Langkah Peminjaman Lab',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Langkah 1: Pilih Lab
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Pilih Lab',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    // Menggunakan Text.rich untuk membuat teks yang terformat
                    Text.rich(
                      TextSpan(
                        text: '• ', // Bullet point
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Cari dan klik Lab yang ingin anda pinjam dari daftar yang tersedia',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Langkah 2: Tentukan Jadwal & Slot Waktu
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Tentukan Jadwal & Slot Waktu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    // Menggunakan Text.rich untuk menambahkan teks yang berbeda format
                    Text.rich(
                      TextSpan(
                        text: '• ', // Bullet point
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Pilih tanggal Pinjam yang Anda inginkan.\n',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                          TextSpan(
                            text: '• ',
                            style: TextStyle(fontWeight: FontWeight.normal), // Bullet point
                          ),
                          TextSpan(
                            text: 'Pilih Slot Waktu yang masih tersedia (ditandai dengan warna selain Merah).',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Langkah 3: Lakukan Peminjaman
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. Lakukan Peminjaman:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    // Menggunakan Text.rich untuk gaya teks yang berbeda
                    Text.rich(
                      TextSpan(
                        text: '• ', // Bullet point
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Setelah tanggal dan slot waktu dipilih, klik tombol\n',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                          TextSpan(
                            text: '“Lakukan Peminjaman”',
                            style: TextStyle(fontWeight: FontWeight.bold), // Bold text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Langkah 4: Lengkapi Detail & Setujui Peraturan
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '4. Lengkapi Detail & Setujui Peraturan:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: '• ', // Bullet point
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Anda akan diarahkan ke halaman\n',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                          TextSpan(
                            text: 'Detail Peminjaman.\n',
                            style: TextStyle(fontWeight: FontWeight.bold), // Bold text
                          ),
                          TextSpan(
                            text: '• ',
                            style: TextStyle(fontWeight: FontWeight.normal), // Bullet
                          ),
                          TextSpan(
                            text: 'Isi data diri (NIM, Nama, Jumlah Orang, Tujuan pinjam).\n',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                          TextSpan(
                            text: '• ',
                            style: TextStyle(fontWeight: FontWeight.normal), // Bullet
                          ),
                          TextSpan(
                            text: 'Baca peraturan yang ditampilkan dengan seksama.',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Langkah 5: Ajukan Peminjaman
            const SizedBox(height: 10),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '5. Ajukan Peminjaman:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: '• ', // Bullet points (tanda titik)
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Centang kotak persetujuan jika Anda setuju\n',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                          TextSpan(
                            text: 'dengan semua peraturan yang berlaku.\n',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                          TextSpan(
                            text: '• ', 
                            style: TextStyle(fontWeight: FontWeight.normal), // Bullet
                          ),
                          TextSpan(
                            text: 'Klik tombol “Ajukan Peminjaman”.',
                            style: TextStyle(fontWeight: FontWeight.bold), // Bold text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Langkah 6: Tunggu Konfirmasi
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎓 Selanjutnya: Tunggu Konfirmasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: '• ', // Bullet point
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'Setelah mengajukan, Anda akan menerima konfirmasi status peminjaman melalui Notifikasi dalam waktu kurang lebih 48 jam.',
                            style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
