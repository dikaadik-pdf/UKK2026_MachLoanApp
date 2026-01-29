import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/users_models.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ================= LOGIN (FINAL FIXED) =================
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final cleanUsername = username.trim();

      // 🔥 EXACT MATCH (NO ILIKE, NO MAYBESINGLE)
      final response = await _supabase
          .from('users')
          .select('id_user, username, role, password')
          .eq('username', cleanUsername)
          .single();

      final dbPassword = response['password'];

      if (dbPassword != password) {
        return _fail('Password salah!');
      }

      final user = UserModel.fromJson(response);

      await _logActivity(
        idUser: user.idUser!,
        aktivitas: 'Login sukses: ${user.username} (${user.role})',
      );

      return _success('Login berhasil!', user);
    } on PostgrestException catch (e) {
      // 🔥 USER NOT FOUND
      if (e.code == 'PGRST116') {
        return _fail('Username tidak ditemukan!');
      }
      return _fail('Database error: ${e.message}');
    } catch (e) {
      return _fail('Server error: $e');
    }
  }

  // ================= REGISTER =================
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final cleanUsername = username.trim();

      // Cek username unik
      final existing = await _supabase
          .from('users')
          .select('id_user')
          .eq('username', cleanUsername)
          .maybeSingle();

      if (existing != null) {
        return _fail('Username sudah terdaftar!');
      }

      final insert = await _supabase
          .from('users')
          .insert({
            'username': cleanUsername,
            'password': password, // ⚠️ plaintext OK for UKK
            'role': role,
          })
          .select('id_user, username, role')
          .single();

      final user = UserModel.fromJson(insert);

      await _logActivity(
        idUser: user.idUser!,
        aktivitas: 'Register sukses: ${user.username} (${user.role})',
      );

      return _success('Akun berhasil dibuat!', user);
    } catch (e) {
      return _fail('Register error: $e');
    }
  }

  // ================= LOG ACTIVITY =================
  Future<void> _logActivity({
    required int idUser,
    required String aktivitas,
  }) async {
    await _supabase.from('log_aktivitas').insert({
      'id_user': idUser,
      'aktivitas': aktivitas,
    });
  }

  // ================= HELPERS =================
  Map<String, dynamic> _success(String message, UserModel user) {
    return {
      'success': true,
      'message': message,
      'user': user,
    };
  }

  Map<String, dynamic> _fail(String message) {
    return {
      'success': false,
      'message': message,
    };
  }

  // ================= ROLE CHECK =================
  bool isAdmin(UserModel user) => user.role == 'admin';
  bool isPetugas(UserModel user) => user.role == 'petugas';
  bool isPeminjam(UserModel user) => user.role == 'peminjam';
}