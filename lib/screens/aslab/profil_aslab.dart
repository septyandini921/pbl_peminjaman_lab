import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/user_service.dart';
import '../../models/user/user_model.dart';
import '../../widgets/aslab_bottom_navbar.dart';
import '../../widgets/app_bar.dart';
import 'aslab_edit_profil.dart';

class ProfilAslabScreen extends StatefulWidget {
  const ProfilAslabScreen({super.key});

  @override
  State<ProfilAslabScreen> createState() => _ProfilAslabScreenState();
}

class _ProfilAslabScreenState extends State<ProfilAslabScreen> {
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
        builder: (context) => const AslabEditProfilScreen(),
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
                                    fontWeight: FontWeight.bold,
                                  ),
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

      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
