import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_models.dart';

class MemberService {
  final SupabaseClient supabase = Supabase.instance.client;

  // GET ALL MEMBERS
  Future<List<MemberModel>> getAllMembers() async {
    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('users')
          .select('id_user, username, role, created_at')
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        print('⚠️ No data found in users table');
        return [];
      }

      final List<MemberModel> members = response
          .map((json) => MemberModel.fromJson(json))
          .toList();

      print('✅ Loaded ${members.length} members');
      return members;
    } catch (e) {
      print('❌ Error loading members: $e');
      rethrow;
    }
  }


  // CREATE MEMBER
  Future<Map<String, dynamic>> createMember({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    try {
      // Cek username duplikat
      final bool usernameExists = await _checkUsernameExists(username);
      if (usernameExists) {
        return {
          'success': false,
          'message': 'Username sudah digunakan! Gunakan username lain.',
        };
      }

      // Buat akun auth
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = authResponse.user;
      if (user == null) {
        return {'success': false, 'message': 'Gagal membuat akun autentikasi'};
      }

      // Insert ke tabel users
      await supabase.from('users').insert({
        'id_user': user.id,
        'username': username,
        'role': role.toLowerCase(),
      });

      print('Member created: $username (${role.toLowerCase()})');

      return {'success': true, 'message': 'Member berhasil ditambahkan'};
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

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ Create member error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }


  // UPDATE MEMBER
  Future<Map<String, dynamic>> updateMember({
    required String userId,
    required String username,
    required String role,
  }) async {
    try {
      await supabase
          .from('users')
          .update({'username': username, 'role': role.toLowerCase()})
          .eq('id_user', userId);

      print('✅ Member updated: $username → ${role.toLowerCase()}');

      return {'success': true, 'message': 'Member berhasil diupdate'};
    } catch (e) {
      print('❌ Update error: $e');
      return {'success': false, 'message': 'Gagal update member: $e'};
    }
  }


  // DELETE MEMBER
  Future<Map<String, dynamic>> deleteMember(String userId) async {
    try {
      await supabase.from('users').delete().eq('id_user', userId);

      print('✅ Member deleted: $userId');

      return {'success': true, 'message': 'Member berhasil dihapus'};
    } catch (e) {
      print('❌ Delete error: $e');
      return {'success': false, 'message': 'Gagal menghapus member: $e'};
    }
  }

  // CHECK USERNAME EXISTS
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final Map<String, dynamic>? response = await supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }


  // ROLE CONVERTER (DISPLAY → DATABASE)
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
