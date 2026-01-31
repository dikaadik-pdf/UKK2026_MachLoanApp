import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServices {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ========== KATEGORI ==========
  
  /// Mendapatkan semua kategori
  static Future<List<Map<String, dynamic>>> getKategori() async {
    try {
      final response = await _supabase
          .from('kategori')
          .select()
          .order('id_kategori');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mengambil kategori: $e');
    }
  }

  /// Menambah kategori baru
  static Future<Map<String, dynamic>> tambahKategori({
    required String namaKategori,
    required String prefixKode,
  }) async {
    try {
      final response = await _supabase
          .from('kategori')
          .insert({
            'nama_kategori': namaKategori.toLowerCase(),
            'prefix_kode': prefixKode.toUpperCase(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  /// Menghapus kategori
  static Future<void> hapusKategori(int idKategori) async {
    try {
      await _supabase
          .from('kategori')
          .delete()
          .eq('id_kategori', idKategori);
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  // ========== ALAT ==========
  
  /// Mendapatkan alat berdasarkan kategori
  static Future<List<Map<String, dynamic>>> getAlatByKategori(int idKategori) async {
    try {
      final response = await _supabase
          .from('alat')
          .select('*, kategori(*)')
          .eq('id_kategori', idKategori)
          .order('nama_alat');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mengambil alat: $e');
    }
  }

  /// Mendapatkan semua alat
  static Future<List<Map<String, dynamic>>> getAllAlat() async {
    try {
      final response = await _supabase
          .from('alat')
          .select('*, kategori(*)')
          .order('nama_alat');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mengambil semua alat: $e');
    }
  }

  /// Menambah alat baru
  static Future<Map<String, dynamic>> tambahAlat({
    required String namaAlat,
    required int idKategori,
    required int stokTotal,
    String kondisi = 'baik',
    int dendaPerHari = 0,
  }) async {
    try {
      final response = await _supabase
          .from('alat')
          .insert({
            'nama_alat': namaAlat,
            'id_kategori': idKategori,
            'stok_total': stokTotal,
            'stok_tersedia': stokTotal,
            'kondisi': kondisi,
            'denda_per_hari': dendaPerHari,
          })
          .select('*, kategori(*)')
          .single();
      return response;
    } catch (e) {
      throw Exception('Gagal menambah alat: $e');
    }
  }

  /// Mengupdate alat
  static Future<Map<String, dynamic>> updateAlat({
    required int idAlat,
    String? namaAlat,
    int? stokTotal,
    String? kondisi,
    int? dendaPerHari,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (namaAlat != null) updateData['nama_alat'] = namaAlat;
      if (stokTotal != null) {
        updateData['stok_total'] = stokTotal;
        // Update stok tersedia juga
        final currentAlat = await _supabase
            .from('alat')
            .select('stok_tersedia')
            .eq('id_alat', idAlat)
            .single();
        updateData['stok_tersedia'] = stokTotal;
      }
      if (kondisi != null) updateData['kondisi'] = kondisi;
      if (dendaPerHari != null) updateData['denda_per_hari'] = dendaPerHari;

      final response = await _supabase
          .from('alat')
          .update(updateData)
          .eq('id_alat', idAlat)
          .select('*, kategori(*)')
          .single();
      return response;
    } catch (e) {
      throw Exception('Gagal mengupdate alat: $e');
    }
  }

  /// Menghapus alat
  static Future<void> hapusAlat(int idAlat) async {
    try {
      await _supabase
          .from('alat')
          .delete()
          .eq('id_alat', idAlat);
    } catch (e) {
      throw Exception('Gagal menghapus alat: $e');
    }
  }

  /// Mencari alat berdasarkan nama
  static Future<List<Map<String, dynamic>>> searchAlat(String keyword, {int? idKategori}) async {
    try {
      var query = _supabase
          .from('alat')
          .select('*, kategori(*)')
          .ilike('nama_alat', '%$keyword%');
      
      if (idKategori != null) {
        query = query.eq('id_kategori', idKategori);
      }
      
      final response = await query.order('nama_alat');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mencari alat: $e');
    }
  }

  // ========== REALTIME SUBSCRIPTION ==========
  
  /// Subscribe ke perubahan alat berdasarkan kategori
  static RealtimeChannel subscribeToAlatByKategori(
    int idKategori,
    Function(List<Map<String, dynamic>>) onData,
  ) {
    final channel = _supabase
        .channel('alat_kategori_$idKategori')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alat',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_kategori',
            value: idKategori,
          ),
          callback: (payload) async {
            // Refresh data ketika ada perubahan
            final data = await getAlatByKategori(idKategori);
            onData(data);
          },
        )
        .subscribe();
    
    return channel;
  }

  /// Subscribe ke perubahan kategori
  static RealtimeChannel subscribeToKategori(
    Function(List<Map<String, dynamic>>) onData,
  ) {
    final channel = _supabase
        .channel('kategori_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kategori',
          callback: (payload) async {
            final data = await getKategori();
            onData(data);
          },
        )
        .subscribe();
    
    return channel;
  }

  /// Unsubscribe channel
  static Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}