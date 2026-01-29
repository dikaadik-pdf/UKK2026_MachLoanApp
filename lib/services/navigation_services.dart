import 'package:flutter/material.dart';
import '../models/users_models.dart';

// Import screens berdasarkan role
// Sesuaikan dengan path screen lu
// import '../screens/admin/dashboardpage.dart';
// import '../screens/petugas/dashboardpage.dart';
// import '../screens/peminjam/dashboardpage.dart';
// import '../screens/loginpage.dart';

class NavigationService {
  // ================= ROUTE KE DASHBOARD BERDASARKAN ROLE =================
  static Widget getHomeScreenByRole(UserModel user) {
    switch (user.role) {
      case 'admin':
        // return AdminDashboardScreen(user: user);
        return _buildPlaceholder('Admin Dashboard', user);
      
      case 'petugas':
        // return PetugasDashboardScreen(user: user);
        return _buildPlaceholder('Petugas Dashboard', user);
      
      case 'peminjam':
        // return PeminjamDashboardScreen(user: user);
        return _buildPlaceholder('Peminjam Dashboard', user);
      
      default:
        // return LoginScreen();
        return _buildPlaceholder('Unknown Role', user);
    }
  }

  // ================= NAVIGATE TO HOME BY ROLE =================
  static void navigateToHomeByRole(
    BuildContext context,
    UserModel user, {
    bool clearStack = true,
  }) {
    final homeScreen = getHomeScreenByRole(user);
    
    if (clearStack) {
      // Clear navigation stack (gabisa back)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeScreen),
        (route) => false,
      );
    } else {
      // Normal navigation (bisa back)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => homeScreen),
      );
    }
  }

  // ================= NAVIGATE TO LOGIN =================
  static void navigateToLogin(BuildContext context) {
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => LoginScreen()),
    //   (route) => false,
    // );
  }

  // ================= CHECK PERMISSION BY ROLE =================
  static bool hasPermission(UserModel user, String permission) {
    // Define permissions per role
    final permissions = {
      'admin': [
        'manage_users',
        'manage_alat',
        'manage_kategori',
        'approve_peminjaman',
        'view_reports',
        'manage_pengembalian',
      ],
      'petugas': [
        'manage_alat',
        'manage_kategori',
        'approve_peminjaman',
        'manage_pengembalian',
      ],
      'peminjam': [
        'create_peminjaman',
        'view_my_peminjaman',
      ],
    };

    final userPermissions = permissions[user.role] ?? [];
    return userPermissions.contains(permission);
  }

  // ================= GET ROUTE NAME BY ROLE =================
  static String getRouteNameByRole(String role) {
    switch (role) {
      case 'admin':
        return '/admin/dashboard';
      case 'petugas':
        return '/petugas/dashboard';
      case 'peminjam':
        return '/peminjam/dashboard';
      default:
        return '/login';
    }
  }

  // ================= PLACEHOLDER WIDGET (Temporary) =================
  static Widget _buildPlaceholder(String title, UserModel user) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Welcome, ${user.username}!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Role: ${user.role?.toUpperCase()}',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Text(
              'TODO: Implement $title Screen',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}