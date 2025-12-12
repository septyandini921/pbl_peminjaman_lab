// C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\test\unit_test\login_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart' as fcs;
import 'package:pbl_peminjaman_lab/auth/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AuthController Login Tests', () {
    late MockFirebaseAuth mockAuth;
    late fcs.FakeFirebaseFirestore mockFirestore;
    late AuthController authController;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = fcs.FakeFirebaseFirestore();
      
      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    test('Login berhasil sebagai Mahasiswa (user_auth = 0)', () async {
      final mockUser = MockUser(
        email: 'mahasiswa@example.com',
        uid: 'mahasiswa123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('mahasiswa123').set({
        'user_auth': 0,
        'user_email': 'mahasiswa@example.com',
        'user_name': 'Budi Mahasiswa',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      final userRole = await authController.signIn(
        'mahasiswa@example.com', 
        'mahasiswapass123'
      );

      expect(userRole, 0);
      expect(authController.currentUserRole.value, 0);
      expect(authController.currentUserEmail.value, 'mahasiswa@example.com');
    });

    test('Login berhasil sebagai Admin (user_auth = 1)', () async {
      final mockUser = MockUser(
        email: 'admin@example.com',
        uid: 'admin123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('admin123').set({
        'user_auth': 1,
        'user_email': 'admin@example.com',
        'user_name': 'Admin User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      final userRole = await authController.signIn(
        'admin@example.com', 
        'adminpass123'
      );

      expect(userRole, 1);
      expect(authController.currentUserRole.value, 1);
      expect(authController.currentUserEmail.value, 'admin@example.com');
    });

    test('Login berhasil sebagai Aslab (user_auth = 2)', () async {
      final mockUser = MockUser(
        email: 'aslab@example.com',
        uid: 'aslab123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('aslab123').set({
        'user_auth': 2,
        'user_email': 'aslab@example.com',
        'user_name': 'Aslab User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      final userRole = await authController.signIn(
        'aslab@example.com', 
        'aslabpass123'
      );

      expect(userRole, 2);
      expect(authController.currentUserRole.value, 2);
      expect(authController.currentUserEmail.value, 'aslab@example.com');
    });

    test('Login gagal - Email tidak terdaftar', () async {
      // User berhasil login tapi tidak ada data di Firestore
      final mockUser = MockUser(
        email: 'tidakterdaftar@example.com',
        uid: 'notfound123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Tidak membuat data di Firestore, sehingga akan error
      expect(
        () => authController.signIn('tidakterdaftar@example.com', 'password123'),
        throwsA(predicate((e) => 
          e.toString().contains('Data profil pengguna tidak ditemukan'))),
      );

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Login gagal - Email salah, password benar', () async {
      final mockUser = MockUser(
        email: 'emailsalah@example.com',
        uid: 'wrongemail123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Data tidak ada di Firestore
      expect(
        () => authController.signIn('emailsalah@example.com', 'passwordbenar123'),
        throwsA(predicate((e) => 
          e.toString().contains('Data profil pengguna tidak ditemukan'))),
      );

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Login gagal - Email benar, password salah', () async {
      // Simulasi auth gagal dengan signedIn: false
      final mockUser = MockUser(
        email: 'emailbenar@example.com',
        uid: 'correct123',
        isEmailVerified: false,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // signedIn: false akan membuat user = null
      expect(
        () => authController.signIn('emailbenar@example.com', 'passwordsalah'),
        throwsA(predicate((e) => 
          e.toString().contains('Login gagal, user tidak valid'))),
      );

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Login gagal - Email salah dan password salah', () async {
      final mockUser = MockUser(
        email: 'emailsalah@example.com',
        uid: 'wrong123',
        isEmailVerified: false,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      expect(
        () => authController.signIn('emailsalah@example.com', 'passwordsalah'),
        throwsA(predicate((e) => 
          e.toString().contains('Login gagal, user tidak valid'))),
      );

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

  });
}