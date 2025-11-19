import 'package:flutter/material.dart';
import '../../widgets/admin_bottom_navbar.dart';

class PermintaanPeminjamanScreen extends StatelessWidget {
  const PermintaanPeminjamanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0), 
        child: SizedBox.shrink(),
      ),
      body: Center(
        child: Text(
          'ini halaman permintaan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}