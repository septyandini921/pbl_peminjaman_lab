// test/unit_test/auth_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart' as fcs;
import 'package:pbl_peminjaman_lab/auth/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AuthController Tests', () { //group test
    late MockFirebaseAuth mockAuth;
    late fcs.FakeFirebaseFirestore mockFirestore;
    late AuthController authController; //controller yang ingin diuji

    setUp(() { //setup ulang mock sebelum tiap test
      mockAuth = MockFirebaseAuth();
      mockFirestore = fcs.FakeFirebaseFirestore();
      
      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    test('Login berhasil dan mendapatkan user role', () async {
      final mockUser = MockUser( //membuat mock user
        email: 'test@example.com',
        uid: '12345',
        isEmailVerified: true,
      );

      // Setup mock auth untuk return user
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      // Setup mock firestore data
      await mockFirestore.collection('Users').doc('12345').set({
        'user_auth': 1, // role sebagai integer
        'email': 'test@example.com',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      final userRole = await authController.signIn( //eksekusi fungsi yang diuji
        'test@example.com', 
        'password123'
      );

      // Assert (pengecekan hasil)
      expect(userRole, 1);
      expect(authController.currentUserRole.value, 1);
      expect(authController.currentUserEmail.value, 'test@example.com');
    });

    test('Login gagal ketika user data tidak ditemukan di Firestore', () async {
      // Arrange
      final mockUser = MockUser(
        email: 'test@example.com',
        uid: '12345',
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      // Tidak setup data di firestore -> akan menyebabkan error

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Act & Assert
      expect(
        () async => await authController.signIn('test@example.com', 'password123'),
        throwsA('Data profil pengguna tidak ditemukan.'),
      );
    });

    test('Sign out berhasil mereset state', () async {
      // Arrange - setup user sudah login
      final mockUser = MockUser(
        email: 'test@example.com',
        uid: '12345',
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      await mockFirestore.collection('Users').doc('12345').set({
        'user_auth': 1,
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Login dulu
      await authController.signIn('test@example.com', 'password123');

      // Act
      await authController.signOut();

      // Assert
      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });
  });
}