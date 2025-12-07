//C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\lib\screens\student\notification_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Untuk mendapatkan userId
import '../../widgets/student_bottom_navbar.dart';
import '../../widgets/app_bar.dart';
import '../../service/booking_service.dart';
import '../../models/booking/booking_model.dart';
import 'detail_peminjaman_student.dart';  // Import halaman detail

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final BookingService _bookingService = BookingService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    // Asumsikan user sudah login, ambil userId dari Firebase Auth
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  // Fungsi untuk mendapatkan pesan notifikasi berdasarkan status booking
  String _getNotificationMessage(BookingModel booking) {
    if (booking.isRejected) {
      return "Peminjaman ${booking.bookCode} ditolak";
    } else if (booking.isConfirmed) {
      return "Peminjaman ${booking.bookCode} telah dikonfirmasi";
    } else {
      return "Peminjaman ${booking.bookCode} berhasil diajukan";
    }
  }

  // Fungsi untuk mendapatkan warna card berdasarkan status
  Color _getCardColor(BookingModel booking) {
    if (booking.isRejected) {
      return Colors.red.shade100;
    } else if (booking.isConfirmed) {
      return Colors.green.shade100;
    } else {
      return Colors.blue.shade100;
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: null,
          )
        ],
      ),
      // 1. Ganti body langsung StreamBuilder menjadi Column
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Agar teks rata kiri
        children: [
          // 2. Bagian Header "Notifikasi"
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // Padding atas/kiri/kanan
            child: Text(
              "Notifikasi",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // 3. Bungkus StreamBuilder dengan Expanded agar mengisi sisa layar
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _bookingService.getBookingsByUser(_currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada notifikasi',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final message = _getNotificationMessage(booking);
                    final cardColor = _getCardColor(booking);

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        title: Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tap untuk melihat detail peminjaman',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailPeminjamanStudent(booking: booking),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      );
    }
  }