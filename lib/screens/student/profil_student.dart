import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../service/user_service.dart';
import '../../service/booking_service.dart'; 
import '../../models/user/user_model.dart';
import '../../models/booking/booking_model.dart'; 
import '../../widgets/student_bottom_navbar.dart';
import '../../widgets/app_bar.dart';
import 'student_edit_profil.dart';
import 'detail_peminjaman_student.dart'; 

class ProfilStudent extends StatefulWidget {
  const ProfilStudent({super.key});

  @override
  State<ProfilStudent> createState() => _ProfilStudentState();
}

class _ProfilStudentState extends State<ProfilStudent> {
  final userService = UserService();
  final bookingService = BookingService(); 
  UserModel? userData;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    UserModel? data = await userService.getUser(uid);
    setState(() => userData = data);
  }

  Future<void> goToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentEditProfilScreen(),
        settings: RouteSettings(arguments: userData),
      ),
    );
    await loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: CustomAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Profil Anda",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: goToEdit,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage(userData!.avatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData!.userName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userData!.userEmail,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit, size: 22, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Riwayat Booking",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: StreamBuilder<List<BookingModel>>(
                      stream: bookingService.getAllBookings(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _emptyState();
                        }

                        final myBookings = snapshot.data!.where((b) {
                          return b.userRef != null && b.userRef!.id == userData!.uid;
                        }).toList();

                        if (myBookings.isEmpty) {
                          return _emptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: myBookings.length,
                          itemBuilder: (context, index) {
                            final booking = myBookings[index];
                            return _buildBookingCard(booking);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            "Belum ada riwayat booking",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.doc(booking.slotRef!.path).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(); 

        final slot = snapshot.data!;
        final slotStart = (slot["slot_start"] as Timestamp).toDate();
        final slotEnd = (slot["slot_end"] as Timestamp).toDate();

        String statusLabel = "Menunggu";
        Color statusColor = Colors.orange;
        Color cardColor = Colors.white;

        if (booking.isRejected) {
          statusLabel = "Ditolak";
          statusColor = Colors.red;
          cardColor = const Color(0xFFFFF5F5); 
        } else if (booking.isConfirmed) {
          statusLabel = "Disetujui";
          statusColor = Colors.green;
          cardColor = const Color(0xFFF6FFFA);
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPeminjamanStudent(booking: booking),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today,
                      color: Color(0xFF4D55CC)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.bookCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${slotStart.day}-${slotStart.month}-${slotStart.year}  •  ${slotStart.hour}:${slotStart.minute.toString().padLeft(2, '0')} - ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}