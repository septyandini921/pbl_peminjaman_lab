import 'package:flutter/material.dart';
import '../../widgets/admin_bottom_navbar.dart';
import '../../widgets/app_bar.dart';
import '../../service/user_service.dart';
import '../../models/user/user_model.dart';
import 'edit_user_screen.dart';
import 'tambah_user_screen.dart';

class KelolaUserScreen extends StatelessWidget {
  const KelolaUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return Scaffold(
      appBar: CustomAppBar(actions: []),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF4D55CC),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Container(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<UserModel>>(
          stream: userService.getUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4D55CC)),
              );
            }

            final users = snapshot.data!;
            if (users.isEmpty) {
              return const Center(
                child: Text(
                  "Belum ada user",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),

                    leading: CircleAvatar(
                      backgroundImage: AssetImage(user.avatar),
                      radius: 28,
                    ),

                    title: Text(
                      user.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "${user.userEmail}\nRole: ${_roleName(user.userAuth)}",
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // EDIT BUTTON
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF4D55CC).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF4D55CC),),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditUserScreen(user: user),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // DELETE BUTTON
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, user),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ROLE NAME
  String _roleName(int auth) {
    switch (auth) {
      case 1:
        return "Admin";
      case 2:
        return "Aslab";
      default:
        return "Mahasiswa";
    }
  }

  // POPUP KONFIRMASI HAPUS
  void _confirmDelete(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Hapus User?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Apakah kamu yakin ingin menghapus user '${user.userName}'?\n"
            "Tindakan ini tidak dapat dibatalkan.",
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await UserService().deleteUser(user.uid);
                Navigator.pop(context);
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }
}
