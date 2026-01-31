import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_models.dart';

class MemberService {
  final supabase = Supabase.instance.client;

  /// Fetch semua members dari database
  Future<List<MemberModel>> getAllMembers() async {
    try {
      final response = await supabase
          .from('users')
          .select('id_user, username, role, created_at')
          .order('created_at', ascending: false);

      if (response == null || (response as List).isEmpty) {
        print('⚠️ No data found in users table');
        return [];
      }

      final members = (response as List)
          .map((json) => MemberModel.fromJson(json))
          .toList();

      print('✅ Loaded ${members.length} members');
      return members;
    } catch (e) {
      print('❌ Error loading members: $e');
      rethrow;
    }
  }

  /// Tambah member baru (create auth + insert ke tabel users)
  Future<Map<String, dynamic>> createMember({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    try {
      // Cek username duplikat
      final existingUsername = await _checkUsernameExists(username);
      if (existingUsername) {
        return {
          'success': false,
          'message': 'Username sudah digunakan! Gunakan username lain.',
        };
      }

      // Create auth user
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'Gagal membuat akun autentikasi',
        };
      }

      // Insert ke tabel users
      await supabase.from('users').insert({
        'id_user': user.id,
        'username': username,
        'role': role.toLowerCase(),
      });

      print('✅ Member created: $username ($role)');

      return {
        'success': true,
        'message': 'Member berhasil ditambahkan',
      };
    } on AuthException catch (e) {
      String errorMessage = 'Gagal membuat akun';
      
      if (e.message.contains('already registered')) {
        errorMessage = 'Email sudah terdaftar! Gunakan email lain.';
      } else if (e.message.contains('Invalid email')) {
        errorMessage = 'Format email tidak valid';
      } else if (e.message.contains('Password')) {
        errorMessage = 'Password terlalu lemah (minimal 6 karakter)';
      } else {
        errorMessage = e.message;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Create member error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Update member (username dan role)
  Future<Map<String, dynamic>> updateMember({
    required String userId,
    required String username,
    required String role,
  }) async {
    try {
      await supabase.from('users').update({
        'username': username,
        'role': role.toLowerCase(),
      }).eq('id_user', userId);

      print('✅ Member updated: $username → $role');

      return {
        'success': true,
        'message': 'Member berhasil diupdate',
      };
    } catch (e) {
      print('❌ Update error: $e');
      return {
        'success': false,
        'message': 'Gagal update member: $e',
      };
    }
  }

  /// Delete member dari tabel users
  Future<Map<String, dynamic>> deleteMember(String userId) async {
    try {
      await supabase.from('users').delete().eq('id_user', userId);
      
      print('✅ Member deleted: $userId');

      return {
        'success': true,
        'message': 'Member berhasil dihapus',
      };
    } catch (e) {
      print('❌ Delete error: $e');
      return {
        'success': false,
        'message': 'Gagal menghapus: $e',
      };
    }
  }

  /// Cek apakah username sudah digunakan
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final response = await supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Helper: Convert role display ke database format
  String roleToDatabase(String displayRole) {
    switch (displayRole) {
      case 'Admin':
        return 'admin';
      case 'Petugas':
        return 'petugas';
      case 'Peminjam':
        return 'peminjam';
      default:
        return displayRole.toLowerCase();
    }
  }
}