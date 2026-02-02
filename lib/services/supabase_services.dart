import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServices {
  static final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // KATEGORI SERVICES
  // ==========================================

  static Future<List<Map<String, dynamic>>> getKategori() async {
    try {
      final response = await _client
          .from('kategori')
          .select()
          .order('nama_kategori');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  static RealtimeChannel subscribeToKategori(
    Function(List<Map<String, dynamic>>) onData,
  ) {
    final channel = _client.channel('kategori_realtime');

    channel
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

  static Future<void> tambahKategori({
    required String namaKategori,
    String? prefixKode,
  }) async {
    try {
      await _client.from('kategori').insert({
        'nama_kategori': namaKategori,
        if (prefixKode != null) 'prefix_kode': prefixKode,
      });
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  static Future<void> hapusKategori(int idKategori) async {
    try {
      await _client.from('kategori').delete().eq('id_kategori', idKategori);
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  // ==========================================
  // SEARCH KATEGORI (TAMBAHAN)
  // ==========================================
  static Future<List<Map<String, dynamic>>> searchKategori(
    String keyword,
  ) async {
    try {
      if (keyword.trim().isEmpty) {
        return getKategori(); // balikin semua kalau kosong
      }

      final response = await _client
          .from('kategori')
          .select()
          .ilike('nama_kategori', '%$keyword%')
          .order('nama_kategori');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal search kategori: $e');
    }
  }

  // ==========================================
  // ALAT SERVICES
  // ==========================================

  static Future<List<Map<String, dynamic>>> getAlatByKategori(
    int idKategori,
  ) async {
    try {
      final response = await _client
          .from('alat')
          .select()
          .eq('id_kategori', idKategori)
          .order('nama_alat');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat alat: $e');
    }
  }

  static RealtimeChannel subscribeToAlatByKategori(
    int idKategori,
    Function(List<Map<String, dynamic>>) onData,
  ) {
    final channel = _client.channel('alat_$idKategori');

    channel
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
            final data = await getAlatByKategori(idKategori);
            onData(data);
          },
        )
        .subscribe();

    return channel;
  }

  static Future<void> tambahAlat({
    required String namaAlat,
    required int idKategori,
    required int stokTotal,
    required double dendaPerHari,
    String? deskripsi,
    String? kondisi,
  }) async {
    try {
      await _client.from('alat').insert({
        'nama_alat': namaAlat,
        'id_kategori': idKategori,
        'stok_total': stokTotal,
        'stok_tersedia': stokTotal,
        'denda_per_hari': dendaPerHari,
        if (deskripsi != null) 'deskripsi': deskripsi,
        if (kondisi != null) 'kondisi': kondisi,
      });
    } catch (e) {
      throw Exception('Gagal menambah alat: $e');
    }
  }

  static Future<void> updateAlat({
    required int idAlat,
    String? namaAlat,
    int? idKategori,
    int? stokTotal,
    double? dendaPerHari,
    String? deskripsi,
    String? kondisi,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (namaAlat != null) updateData['nama_alat'] = namaAlat;
      if (idKategori != null) updateData['id_kategori'] = idKategori;
      if (stokTotal != null) updateData['stok_total'] = stokTotal;
      if (dendaPerHari != null) updateData['denda_per_hari'] = dendaPerHari;
      if (deskripsi != null) updateData['deskripsi'] = deskripsi;
      if (kondisi != null) updateData['kondisi'] = kondisi;

      if (updateData.isEmpty) {
        throw Exception('Tidak ada data yang diupdate');
      }

      await _client.from('alat').update(updateData).eq('id_alat', idAlat);
    } catch (e) {
      throw Exception('Gagal mengupdate alat: $e');
    }
  }

  static Future<void> hapusAlat(int idAlat) async {
    try {
      await _client.from('alat').delete().eq('id_alat', idAlat);
    } catch (e) {
      throw Exception('Gagal menghapus alat: $e');
    }
  }

  static void unsubscribeChannel(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }

  // ==========================================
  // PEMINJAMAN SERVICES
  // ==========================================

  /// Generate kode peminjaman otomatis (format: PJM-YYYYMMDD-XXX)
  static Future<String> _generateKodePeminjaman() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final prefix = 'PJM-$dateStr-';

    try {
      final response = await _client
          .from('peminjaman')
          .select('kode_peminjaman')
          .like('kode_peminjaman', '$prefix%')
          .order('kode_peminjaman', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return '${prefix}001';
      }

      final lastCode = response[0]['kode_peminjaman'] as String;
      final lastNumber = int.parse(lastCode.split('-').last);
      final newNumber = (lastNumber + 1).toString().padLeft(3, '0');
      return '$prefix$newNumber';
    } catch (e) {
      return '${prefix}001';
    }
  }

  /// Create peminjaman baru (dipanggil dari PinjamAlat)
  static Future<void> createPeminjaman({
    required String idUser,
    required int idAlat,
    required int jumlah,
    required DateTime tanggalPinjam,
    required DateTime estimasiKembali,
  }) async {
    try {
      // Generate kode peminjaman
      final kodePeminjaman = await _generateKodePeminjaman();

      // Insert ke tabel peminjaman
      final peminjamanResponse = await _client
          .from('peminjaman')
          .insert({
            'kode_peminjaman': kodePeminjaman,
            'id_user': idUser,
            'tanggal_pinjam': tanggalPinjam.toIso8601String().split('T')[0],
            'estimasi_kembali': estimasiKembali.toIso8601String().split('T')[0],
            'status': 'menunggu',
          })
          .select()
          .single();

      final idPeminjaman = peminjamanResponse['id_peminjaman'];

      // Insert ke tabel detail_peminjaman
      await _client.from('detail_peminjaman').insert({
        'id_peminjaman': idPeminjaman,
        'id_alat': idAlat,
        'jumlah': jumlah,
      });

      // Log aktivitas
      await _client.from('log_aktivitas').insert({
        'id_user': idUser,
        'aktivitas': 'Mengajukan peminjaman $kodePeminjaman',
      });
    } catch (e) {
      throw Exception('Gagal membuat peminjaman: $e');
    }
  }

  /// Get daftar peminjaman berdasarkan status (untuk petugas)
  static Future<List<Map<String, dynamic>>> getPeminjamanByStatus(
    String status,
  ) async {
    try {
      final response = await _client
          .from('peminjaman')
          .select('''
            *,
            users!inner(username),
            detail_peminjaman!inner(
              jumlah,
              alat!inner(nama_alat, denda_per_hari)
            ),
            pengembalian(tanggal_pengembalian, total_denda)
          ''')
          .eq('status', status)
          .order('tanggal_pinjam', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat peminjaman: $e');
    }
  }

  /// Subscribe realtime untuk peminjaman berdasarkan status
  static RealtimeChannel subscribeToPeminjamanByStatus(
    String status,
    Function(List<Map<String, dynamic>>) onData,
  ) {
    final channel = _client.channel('peminjaman_$status');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) async {
            final data = await getPeminjamanByStatus(status);
            onData(data);
          },
        )
        .subscribe();

    return channel;
  }

  /// Update status peminjaman (Setujui/Tolak)
  static Future<void> updateStatusPeminjaman({
    required int idPeminjaman,
    required String newStatus,
    required String idPetugas,
    int? stokDikurangi,
    int? idAlat,
  }) async {
    try {
      // Update status peminjaman
      await _client
          .from('peminjaman')
          .update({'status': newStatus})
          .eq('id_peminjaman', idPeminjaman);

      // Jika disetujui, kurangi stok tersedia
      if (newStatus == 'disetujui' && stokDikurangi != null && idAlat != null) {
        await _client.rpc(
          'kurangi_stok_tersedia',
          params: {'p_id_alat': idAlat, 'p_jumlah': stokDikurangi},
        );
      }

      // Log aktivitas
      final actionText = newStatus == 'disetujui' ? 'menyetujui' : 'menolak';
      await _client.from('log_aktivitas').insert({
        'id_user': idPetugas,
        'aktivitas': 'Petugas $actionText peminjaman ID: $idPeminjaman',
      });
    } catch (e) {
      throw Exception('Gagal update status: $e');
    }
  }

  /// Get user ID dari username
  static Future<String> getUserIdByUsername(String username) async {
    try {
      final response = await _client
          .from('users')
          .select('id_user')
          .eq('username', username)
          .single();
      return response['id_user'];
    } catch (e) {
      throw Exception('User tidak ditemukan');
    }
  }

  /// Get alat by ID
  static Future<Map<String, dynamic>> getAlatById(int idAlat) async {
    try {
      final response = await _client
          .from('alat')
          .select()
          .eq('id_alat', idAlat)
          .single();
      return response;
    } catch (e) {
      throw Exception('Alat tidak ditemukan');
    }
  }
}
