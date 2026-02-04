import 'package:ukk2026_machloanapp/models/logaktivitas_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogAktivitasService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Mendapatkan semua log aktivitas (untuk kompatibilitas)
  Future<List<LogAktivitasModel>> getAllLogs() async {
    try {
      final response = await _client
          .from('log_aktivitas')
          .select('''
            id_log,
            id_user,
            aktivitas,
            waktu_aktivitas,
            users!inner(
              username,
              role
            )
          ''')
          .order('waktu_aktivitas', ascending: false);

      return (response as List).map<LogAktivitasModel>((log) {
        final logData = log as Map<String, dynamic>;
        
        // Debug print untuk melihat struktur data
        print('Raw log data: $logData');
        
        return LogAktivitasModel.fromJson(logData);
      }).toList();
    } catch (e) {
      print('Error detail: $e');
      throw Exception('Gagal memuat log aktivitas: $e');
    }
  }

  /// Mendapatkan log aktivitas dengan filter tanggal
  Future<List<LogAktivitasModel>> getLogsByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('log_aktivitas').select('''
            id_log,
            id_user,
            aktivitas,
            waktu_aktivitas,
            users!inner(
              username,
              role
            )
          ''');

      if (startDate != null) {
        // Set waktu ke awal hari (00:00:00)
        final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
        query = query.gte(
          'waktu_aktivitas',
          startOfDay.toUtc().toIso8601String(),
        );
      }
      
      if (endDate != null) {
        // Set waktu ke akhir hari (23:59:59)
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte(
          'waktu_aktivitas',
          endOfDay.toUtc().toIso8601String(),
        );
      }

      final response = await query.order('waktu_aktivitas', ascending: false);

      return (response as List).map<LogAktivitasModel>((log) {
        final logData = log as Map<String, dynamic>;
        
        // Debug print untuk melihat struktur data
        print('Raw log data with date filter: $logData');
        
        return LogAktivitasModel.fromJson(logData);
      }).toList();
    } catch (e) {
      print('Error detail in getLogsByDateRange: $e');
      throw Exception('Gagal memuat log aktivitas: $e');
    }
  }

  /// Subscribe ke perubahan log aktivitas realtime
  RealtimeChannel subscribeToLogAktivitas(
    Function(List<LogAktivitasModel>) onData,
  ) {
    final channel = _client.channel('log_aktivitas_realtime');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'log_aktivitas',
          callback: (payload) async {
            try {
              final data = await getAllLogs();
              onData(data);
            } catch (e) {
              print('Error in realtime subscription: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe dari channel
  void unsubscribeChannel(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}