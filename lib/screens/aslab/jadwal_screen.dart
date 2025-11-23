import 'package:flutter/material.dart';
import '../../widgets/aslab_bottom_navbar.dart';
import '../../widgets/app_bar.dart';

class JadwalScreen extends StatelessWidget {
  const JadwalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),

      body: const Center(
        child: Text(
          'ini halaman Jadwal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
