import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  static final AuthController instance = AuthController._internal();
  AuthController._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<int?> currentUserRole = ValueNotifier<int?>(null);
  final ValueNotifier<String?> currentUserEmail = ValueNotifier<String?>(null);

  void initAuthListener() {
    // Implementasi listener jika perlu untuk auto-login
  }

  Future<int> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        String uid = user.uid;

        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(uid).get();

        if (userDoc.exists) {
          int userRole = (userDoc.data() as Map<String, dynamic>)['user_auth'] as int;

          currentUserRole.value = userRole;
          currentUserEmail.value = user.email;

          return userRole;
          
        } else {
          await _auth.signOut(); 
          throw 'Data profil pengguna tidak ditemukan.';
        }
      } else {
        throw 'Login gagal, user tidak valid.';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Email atau password salah';
      }
      throw 'Terjadi kesalahan: ${e.message}';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUserRole.value = null;
    currentUserEmail.value = null;
  }
}