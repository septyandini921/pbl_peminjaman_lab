import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/student_bottom_navbar.dart';
import '../../widgets/app_bar.dart';
import '../../service/booking_service.dart';
import '../../models/booking/booking_model.dart';
import 'detail_peminjaman_student.dart';

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
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  String _getNotificationMessage(BookingModel booking) {
    if (booking.isRejected) {
      return "Peminjaman ${booking.bookCode} ditolak";
    } else if (booking.isConfirmed) {
      return "Peminjaman ${booking.bookCode} telah dikonfirmasi";
    } else {
      return "Peminjaman ${booking.bookCode} berhasil diajukan";
    }
  }

  Color _getCardColor(BookingModel booking) {
    if (booking.isRejected) {
      return Colors.red.shade100;
    } else if (booking.isConfirmed) {
      return Colors.green.shade100;
    } else {
      return Colors.blue.shade100;
    }
  }

  IconData _getStatusIcon(BookingModel booking) {
    if (booking.isRejected) {
      return Icons.cancel;
    } else if (booking.isConfirmed) {
      return Icons.check_circle;
    } else {
      return Icons.hourglass_empty;
    }
  }

  Color _getIconColor(BookingModel booking) {
    if (booking.isRejected) {
      return Colors.red;
    } else if (booking.isConfirmed) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Baru saja';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Text(
              "Notifikasi",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
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
                    final icon = _getStatusIcon(booking);
                    final iconColor = _getIconColor(booking);
                    final timeAgo = _formatDateTime(booking.createdAt);

                    // ✅ KUNCI: Tambahkan unique key untuk setiap card
                    return Card(
                      key: ValueKey(booking.id), // ← PENTING: Unique key berdasarkan booking ID
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailPeminjamanStudent(booking: booking),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Icon status
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: iconColor,
                                  size: 28,
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap untuk melihat detail peminjaman',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeAgo,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Chevron right
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
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
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}