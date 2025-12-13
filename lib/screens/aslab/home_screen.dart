import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_bar.dart';
import '../../service/booking_service.dart';
import '../../widgets/aslab_bottom_navbar.dart';
import '../../service/slot_service.dart';
import '../../service/lab_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final BookingService _bookingService = BookingService();
  final SlotService _slotService = SlotService();
  final LabService _labService = LabService();
  String userName = "Pengguna";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .get();

      /// ⛔ FIX UTAMA: Cek apakah widget masih mounted sebelum setState
      if (!mounted) return;

      setState(() {
        userName = snapshot.data()?["user_name"] ?? "Pengguna";
      });
    } catch (e) {
      // Error diamkan saja
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home_screen'),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(actions: []),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _welcomeCard(),
          const SizedBox(height: 25),
          _statistikSimpel(),
          const SizedBox(height: 25),
          _labPalingDipinjam(),
        ],
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      key: const Key('home_welcome_card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/icons/bot.png", width: 55),
          const SizedBox(width: 12),
          Text(
            "Selamat Datang $userName",
            key: const Key('home_welcome_text'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _statistikSimpel() {
    return Container(
      key: const Key('home_statistik'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4D55CC), Color(0xFF38339C)],
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
              StreamBuilder<int>(
                stream: _bookingService.getAllBookingsCountWeekly(),
                builder: (context, snapshot) {
                  final value = snapshot.data?.toString() ?? "0";
                  return _statBox(
                    value,
                    "Pengajuan",
                    key: const Key('stat_pengajuan'),
                  );
                },
              ),
              StreamBuilder<int>(
                stream: _bookingService.getConfirmedBookingsCountWeekly(),
                builder: (context, snapshot) {
                  final value = snapshot.data?.toString() ?? "0";
                  return _statBox(
                    value,
                    "Peminjaman",
                    key: const Key('stat_peminjaman'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<int>(
            stream: _slotService.getTotalUsedSlotsWeekly(),
            initialData: 0,
            builder: (context, usedSnapshot) {
              final usedCount = usedSnapshot.data ?? 0;
              return Container(
                key: const Key('stat_slot_terpakai'),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "$usedCount Slot Terpakai",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _labPalingDipinjam() {
    return StreamBuilder<Map<String, int>>(
      stream: _bookingService.getMostBorrowedLabWeekly(),
      initialData: const {},
      builder: (context, snapshot) {
        String labName = "N/A";
        int totalPeminjaman = 0;

        if (snapshot.connectionState == ConnectionState.waiting) {
          labName = "Memuat...";
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final sortedLabs = snapshot.data!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final mostUsedLabId = sortedLabs.first.key;
          totalPeminjaman = sortedLabs.first.value;

          return FutureBuilder<String>(
            future: _labService.getLabNameById(mostUsedLabId),
            builder: (context, nameSnapshot) {
              labName = nameSnapshot.data ?? 'Memuat Nama...';
              return _buildStyledLabDisplay(labName, totalPeminjaman);
            },
          );
        }

        return _buildStyledLabDisplay(labName, totalPeminjaman);
      },
    );
  }

  Widget _buildStyledLabDisplay(String labName, int totalPeminjaman) {
    return Container(
      key: const Key('home_lab_paling_dipinjam'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4D55CC), Color(0xFF38339C)],
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
            key: const Key('lab_total_peminjaman'),
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Image.asset("assets/icons/lab_icon.png", width: 45),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 100,
                    child: Text(
                      labName,
                      key: const Key('lab_name_text'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              _statBox(totalPeminjaman.toString(), "Peminjaman"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
