// C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\test\unit_test\logout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart' as fcs;
import 'package:pbl_peminjaman_lab/auth/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AuthController Logout Tests', () {
    late MockFirebaseAuth mockAuth;
    late fcs.FakeFirebaseFirestore mockFirestore;
    late AuthController authController;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = fcs.FakeFirebaseFirestore();
    });

    // POSITIVE SCENARIOS 
     test('Logout berhasil - User Mahasiswa', () async {
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

      await authController.signIn(
        'mahasiswa@example.com', 
        'mahasiswapass123'
      );

      // Verifikasi sebelum logout
      expect(authController.currentUserRole.value, 0);
      expect(authController.currentUserEmail.value, 'mahasiswa@example.com');
      expect(mockAuth.currentUser, isNotNull); // User masih login

      await authController.signOut();

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
      expect(mockAuth.currentUser, isNull); 
    });

    test('Logout berhasil - User Admin', () async {
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

      await authController.signIn('admin@example.com', 'adminpass123');

      await authController.signOut();

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
      expect(mockAuth.currentUser, isNull);
    });

    test('Logout berhasil - User Aslab', () async {
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

      await authController.signIn('aslab@example.com', 'aslabpass123');

      await authController.signOut();

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
      expect(mockAuth.currentUser, isNull);
    });

    test('Logout berhasil - Multiple logout calls', () async {
      final mockUser = MockUser(
        email: 'test@example.com',
        uid: 'test123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('test123').set({
        'user_auth': 0,
        'user_email': 'test@example.com',
        'user_name': 'Test User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      await authController.signIn('test@example.com', 'password123');

      await authController.signOut();
      await authController.signOut();
      await authController.signOut(); 

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Logout berhasil - Kembali login setelah logout', () async {
      final mockUser = MockUser(
        email: 'user@example.com',
        uid: 'user123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('user123').set({
        'user_auth': 0,
        'user_email': 'user@example.com',
        'user_name': 'Regular User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Login pertama
      await authController.signIn('user@example.com', 'password123');
      expect(authController.currentUserRole.value, 0);
      expect(authController.currentUserEmail.value, 'user@example.com');

      // Logout pertama
      await authController.signOut();
      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);

      // Login kembali
      await authController.signIn('user@example.com', 'password123');
      expect(authController.currentUserRole.value, 0);
      expect(authController.currentUserEmail.value, 'user@example.com');

      // Logout kembali
      await authController.signOut();
      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    // NEGATIVE/EDGE CASE SCENARIOS 
    test('Logout saat sudah logout (state sudah null)', () async {
      // Setup tanpa login (state null dari awal)
      mockAuth = MockFirebaseAuth(signedIn: false);
      
      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      authController.currentUserRole.value = null;
      authController.currentUserEmail.value = null;

      await authController.signOut();

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Logout tanpa pernah login (auth null)', () async {
      // Setup dengan mockAuth yang tidak memiliki currentUser
      mockAuth = MockFirebaseAuth(signedIn: false);
      
      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      authController.currentUserRole.value = null;
      authController.currentUserEmail.value = null;

      await authController.signOut();

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
      expect(mockAuth.currentUser, isNull);
    });

    test('Logout dengan auth error simulation', () async {
      final mockUser = MockUser(
        email: 'error@example.com',
        uid: 'error123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('error123').set({
        'user_auth': 0,
        'user_email': 'error@example.com',
        'user_name': 'Error User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Login
      await authController.signIn('error@example.com', 'password123');
      
      // Simulasi error saat signOut (tidak tersedia di MockFirebaseAuth secara langsung)
      // test bahwa state tetap di-reset
      await authController.signOut();

      // Verifikasi bahwa state tetap di-reset meskipun ada error
      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Logout dengan data firestore yang tidak sinkron', () async {
      final mockUser = MockUser(
        email: 'nosync@example.com',
        uid: 'nosync123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Login akan error tapi di bypass dengan set manual
      authController.currentUserRole.value = 0;
      authController.currentUserEmail.value = 'nosync@example.com';

      await authController.signOut();

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Logout kemudian akses user data', () async {
      final mockUser = MockUser(
        email: 'data@example.com',
        uid: 'data123',
        isEmailVerified: true,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('data123').set({
        'user_auth': 0,
        'user_email': 'data@example.com',
        'user_name': 'Data User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      // Login
      await authController.signIn('data@example.com', 'password123');

      // Simpan data sebelum logout
      final roleBefore = authController.currentUserRole.value;
      final emailBefore = authController.currentUserEmail.value;

      // Logout
      await authController.signOut();

      // Verifikasi setelah logout
      expect(roleBefore, 0); 
      expect(emailBefore, 'data@example.com'); 
      expect(authController.currentUserRole.value, isNull); 
      expect(authController.currentUserEmail.value, isNull); 

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
    });

    test('Logout dengan user yang belum diverifikasi email', () async {
      final mockUser = MockUser(
        email: 'unverified@example.com',
        uid: 'unverified123',
        isEmailVerified: false,
      );

      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      await mockFirestore.collection('Users').doc('unverified123').set({
        'user_auth': 0,
        'user_email': 'unverified@example.com',
        'user_name': 'Unverified User',
        'avatar': 'assets/avatar/Avatar_Woman.jpg',
      });

      authController = AuthController.testConstructor(
        auth: mockAuth,
        firestore: mockFirestore,
      );

      await authController.signIn('unverified@example.com', 'password123');

      await authController.signOut();

      expect(authController.currentUserRole.value, isNull);
      expect(authController.currentUserEmail.value, isNull);
      expect(mockAuth.currentUser, isNull);
    });
  });
}