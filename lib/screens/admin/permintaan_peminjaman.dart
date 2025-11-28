import 'package:flutter/material.dart';
import '../../widgets/admin_bottom_navbar.dart';

class PermintaanPeminjamanScreen extends StatelessWidget {
  const PermintaanPeminjamanScreen({super.key});

   // ======================== HEADER CUSTOM ==========================
Widget _customHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 45, bottom: 25),
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
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ======================== HEADER ==========================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: _customHeader(),
      ),

      // ======================== BODY ==========================
      body: const Center(
        child: Text(
          'Tidak Ada Permintaan Peminjaman',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),

      // ======================== NAVBAR ==========================
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
