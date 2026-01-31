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
        return {
          'success': false,
          'message': 'Email atau password salah',
        };
      }

      // ✅ Ambil data user dari tabel "users" (optional)
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

      return {
        'success': true,
        'user': UserModel.fromJson(userData),
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
