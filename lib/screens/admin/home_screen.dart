import 'package:flutter/material.dart';
import '../../../auth/auth_controller.dart';
import '../auth/login_screen.dart';

// Import halaman sesuai folder kamu
import 'permintaan_peminjaman.dart';
import 'kelola_lab.dart';
import 'profil_admin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await AuthController.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ======================== HEADER CUSTOM ==========================
Widget _customHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 25, bottom: 15), // <--- diperkecil
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF4D55CC),
          Color(0xFF38339C),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: const Center(
      child: Text(
        "SIMPEL",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18, // <--- font lebih kecil
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

  // ======================== NAVBAR ITEM ==========================
  Widget _navItem(IconData icon, String label, int index) {
    bool active = currentIndex == index;

    return InkWell(
      onTap: () {
        if (currentIndex == index) return; // tidak reload halaman sama

        setState(() {
          currentIndex = index;
        });

        // ================= NAVIGASI SESUAI INDEX =================
        switch (index) {
          case 0:
            // halaman home, sudah di sini
            break;

          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PermintaanPeminjamanScreen(),
              ),
            );
            break;

          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const KelolaLabScreen(),
              ),
            );
            break;

          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilAdminScreen(),
              ),
            );
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? Colors.white : Colors.white70,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: _customHeader(),
      ),

      // ======================== NAVBAR TANPA MELENGKUNG ==========================
      bottomNavigationBar: Container(
        color: const Color(0xFF4D55CC),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, "Home", 0),
            _navItem(Icons.list, "List", 1),
            _navItem(Icons.science, "Kelola Lab", 2),
            _navItem(Icons.person, "Profile", 3),
          ],
        ),
      ),

      // ======================== BODY ==============================
      body: _buildBody(),
    );
  }

  // ======================== BODY CONTENT ==========================
Widget _buildBody() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ===== Card Welcome Admin =====
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar/logo
              Image.asset(
                "assets/icons/bot.png",
                width: 55,
                height: 55,
              ),
              const SizedBox(width: 15),

              // Teks
              const Text(
                "Selamat datang Admin",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Statistik
        _statistikSimpel(),
        const SizedBox(height: 25),

        // Lab paling sering dipinjam
        _labPalingDipinjam(),
        const SizedBox(height: 25),

        const Text(
          "Peminjaman Menunggu Konfirmasi",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        _peminjamanCard(),
        const SizedBox(height: 10),
        _peminjamanCard(),
      ],
    ),
  );
}
  // ======================== KOMPONEN TAMBAHAN ==========================
  Widget _statistikSimpel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x804D55CC),
            Color(0xFF38339C),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Statistik SIMPEL  Minggu Ini",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statBox("20", "Pengajuan"),
              _statBox("17", "Peminjaman"),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.show_chart, color: Colors.black, size: 30),
                SizedBox(width: 10),
                Text(
                  "72%  Slot Terpakai",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _labPalingDipinjam() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x804D55CC),
            Color(0xFF38339C),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Lab Paling Sering Dipinjam",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Image.asset(
                    'assets/icons/lab_icon.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Lab MMT Lt 8B",
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              _statBox("8", "Peminjaman"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _peminjamanCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Peminjaman LMMT0101050320",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 4),
          Text("Slot 1 Lab MMT Lt 8B pada 5 Maret 2020"),
          Text("Oleh Syifa Revalina 2341760099"),
        ],
      ),
    );
  }
}
