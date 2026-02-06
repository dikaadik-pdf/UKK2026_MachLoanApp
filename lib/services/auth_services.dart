import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/users_models.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return {'success': false, 'message': 'Email atau password salah'};
      }

      final userData = await supabase
          .from('users')
          .select('*')
          .eq('id_user', user.id)
          .maybeSingle();

      if (userData == null) {
        return {
          'success': false,
          'message': 'User tidak ditemukan di tabel users',
        };
      }

      return {'success': true, 'user': UserModel.fromJson(userData)};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> logout() async {
    try {
      await supabase.auth.signOut();
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  // ================= USER AVATAR SERVICES =================
  
  /// Update user avatar URL in database
  Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      await supabase
          .from('users')
          .update({'avatar_url': avatarUrl})
          .eq('id_user', userId);
    } catch (e) {
      throw Exception('Gagal update avatar: $e');
    }
  }

  /// Get user avatar URL
  Future<String?> getUserAvatar(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select('avatar_url')
          .eq('id_user', userId)
          .single();
      return response['avatar_url'];
    } catch (e) {
      return null;
    }
  }

  /// Get user data including avatar
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select('*')
          .eq('id_user', userId)
          .single();
      return response;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}