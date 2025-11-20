import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/user_service.dart';
import '../../models/user/user_model.dart';
import '../../widgets/admin_bottom_navbar.dart';
import 'admin_edit_profil.dart';

class ProfilAdminScreen extends StatefulWidget {
  const ProfilAdminScreen({super.key});

  @override
  State<ProfilAdminScreen> createState() => _ProfilAdminScreenState();
}

class _ProfilAdminScreenState extends State<ProfilAdminScreen> {
  final userService = UserService();
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
        builder: (context) => const AdminEditProfilScreen(),
        settings: RouteSettings(arguments: userData),
      ),
    );
    await loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFD9D5EC),
          centerTitle: true,
          title: const Text(
            "SIMPEL",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
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

                          GestureDetector(
                            onTap: goToEdit,
                            child: const Icon(Icons.edit,
                                size: 22, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
