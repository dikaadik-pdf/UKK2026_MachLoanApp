import 'package:flutter/material.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/dashboardpagepeminjam.dart';
import '../models/users_models.dart';
import 'package:ukk2026_machloanapp/screens/admin/dashboardpage.dart'; // ✅ PERBAIKI INI
import 'package:ukk2026_machloanapp/screens/petugas/dashboardpagepetugas.dart';

class NavigationService {
  // ================= ROUTE KE DASHBOARD BERDASARKAN ROLE =================
  static Widget getHomeScreenByRole(UserModel user) {
    switch (user.role) {
      case 'admin':
        return DashboardScreenAdmin(username: user.username); // ✅ BENAR
      
      case 'petugas':
        return DashboardScreenPetugas(username: user.username); // Sementara pakai admin
      
      case 'peminjam':
        return DashboardScreenPeminjam(username: user.username);
      
      default:
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeScreen),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => homeScreen),
      );
    }
  }

  // ================= NAVIGATE TO LOGIN =================
  static void navigateToLogin(BuildContext context) {
    // Implementasi nanti
  }

  // ================= CHECK PERMISSION BY ROLE =================
  static bool hasPermission(UserModel user, String permission) {
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
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${user.username}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Role: ${user.role?.toUpperCase()}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Text(
              'TODO: Implement $title Screen',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}