import 'package:flutter/material.dart';
import '../../widgets/app_bar.dart';
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

  // ==================== ITEM NAVBAR ====================
  Widget _navItem(IconData icon, String label, int index) {
    bool active = currentIndex == index;

    return InkWell(
      onTap: () {
        if (currentIndex == index) return;
        setState(() => currentIndex = index);

        switch (index) {
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PermintaanPeminjamanScreen()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const KelolaLabScreen()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilAdminScreen()),
            );
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.white : Colors.white70, size: 28),
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

  // ========================== BUILD ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ========== PAKAI CUSTOM APP BAR ==========
      appBar: const CustomAppBar(actions: []),

      // =================== NAVBAR ===================
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

      body: _buildBody(),
    );
  }

  // ==================== HOME BODY ====================
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ========= CARD SELAMAT DATANG (SEKARANG DI BAWAH APP BAR) =========
          _welcomeCard(),
          const SizedBox(height: 25),

          _statistikSimpel(),
          const SizedBox(height: 25),
          _labPalingDipinjam(),
        ],
      ),
    );
  }

  // ==================== CARD WELCOME ====================
  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/icons/bot.png", width: 55),
          const SizedBox(width: 12),
          const Text(
            "Selamat datang Admin",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Statistik SIMPEL ====================
  Widget _statistikSimpel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4D55CC),
            Color(0xFF38339C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Statistik SIMPEL Minggu Ini",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
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
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.show_chart, size: 28),
                SizedBox(width: 10),
                Text(
                  "72%  Slot Terpakai",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==================== LAB PALING DIPINJAM ====================
  Widget _labPalingDipinjam() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4D55CC),
            Color(0xFF38339C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Lab Paling Sering Dipinjam",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Image.asset("assets/icons/lab_icon.png", width: 45),
                  const SizedBox(height: 6),
                  const Text(
                    "Lab MMT Lt 8B",
                    style: TextStyle(color: Colors.white),
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

  // ==================== Kotak kecil angka ====================
  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
