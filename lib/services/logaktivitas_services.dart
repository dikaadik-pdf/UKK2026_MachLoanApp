import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk2026_machloanapp/models/logaktivitas_models.dart';

class LogAktivitasService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil semua log aktivitas dari database
  Future<List<LogAktivitasModel>> getAllLogs() async {
    try {
      final response = await _supabase
          .from('vw_log_aktivitas')
          .select()
          .order('waktu_aktivitas', ascending: false);

      return (response as List)
          .map((log) => LogAktivitasModel.fromJson(log))
          .toList();
    } catch (e) {
      print('Error fetching logs: $e');
      throw Exception('Gagal mengambil data log aktivitas');
    }
  }

  /// Mencari log aktivitas berdasarkan query
  Future<List<LogAktivitasModel>> searchLogs(String query) async {
    try {
      final response = await _supabase
          .from('vw_log_aktivitas')
          .select()
          .or('username.ilike.%$query%,aktivitas.ilike.%$query%')
          .order('waktu_aktivitas', ascending: false);

      return (response as List)
          .map((log) => LogAktivitasModel.fromJson(log))
          .toList();
    } catch (e) {
      print('Error searching logs: $e');
      throw Exception('Gagal mencari log aktivitas');
    }
  }

  /// Filter log berdasarkan role
  Future<List<LogAktivitasModel>> getLogsByRole(String role) async {
    try {
      final response = await _supabase
          .from('vw_log_aktivitas')
          .select()
          .eq('role', role)
          .order('waktu_aktivitas', ascending: false);

      return (response as List)
          .map((log) => LogAktivitasModel.fromJson(log))
          .toList();
    } catch (e) {
      print('Error fetching logs by role: $e');
      throw Exception('Gagal mengambil log berdasarkan role');
    }
  }

  /// Filter log berdasarkan tanggal
  Future<List<LogAktivitasModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('vw_log_aktivitas')
          .select()
          .gte('waktu_aktivitas', startDate.toIso8601String())
          .lte('waktu_aktivitas', endDate.toIso8601String())
          .order('waktu_aktivitas', ascending: false);

      return (response as List)
          .map((log) => LogAktivitasModel.fromJson(log))
          .toList();
    } catch (e) {
      print('Error fetching logs by date: $e');
      throw Exception('Gagal mengambil log berdasarkan tanggal');
    }
  }

  /// Mencatat aktivitas login
  Future<void> logLogin(String userId) async {
    try {
      await _supabase.rpc('log_user_activity', params: {
        'p_id_user': userId,
        'p_aktivitas': 'Login ke aplikasi',
      });
    } catch (e) {
      print('Error logging login: $e');
    }
  }

  /// Mencatat aktivitas logout
  Future<void> logLogout(String userId) async {
    try {
      await _supabase.rpc('log_user_activity', params: {
        'p_id_user': userId,
        'p_aktivitas': 'Logout dari aplikasi',
      });
    } catch (e) {
      print('Error logging logout: $e');
    }
  }

  /// Mencatat aktivitas custom
  Future<void> logCustomActivity(String userId, String activity) async {
    try {
      await _supabase.rpc('log_user_activity', params: {
        'p_id_user': userId,
        'p_aktivitas': activity,
      });
    } catch (e) {
      print('Error logging custom activity: $e');
    }
  }

  /// Subscribe ke perubahan log aktivitas (real-time)
  Stream<List<LogAktivitasModel>> subscribeToLogs() {
    return _supabase
        .from('vw_log_aktivitas')
        .stream(primaryKey: ['id_log'])
        .order('waktu_aktivitas', ascending: false)
        .map((data) => data.map((log) => LogAktivitasModel.fromJson(log)).toList());
  }
}