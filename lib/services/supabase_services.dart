import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServices {
  static final SupabaseClient _client = Supabase.instance.client;


  // DASHBOARD SERVICES

  /// Mendapatkan statistik untuk dashboard admin
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final alatResponse = await _client
          .from('alat')
          .select('stok_total, stok_tersedia');

      int totalAlat = 0;
      int alatTersedia = 0;

      for (var alat in alatResponse) {
        totalAlat += (alat['stok_total'] as num).toInt();
        alatTersedia += (alat['stok_tersedia'] as num).toInt();
      }

      int alatDipinjam = totalAlat - alatTersedia;

      return {
        'total_alat': totalAlat,
        'alat_tersedia': alatTersedia,
        'alat_dipinjam': alatDipinjam,
      };
    } catch (e) {
      throw Exception('Gagal memuat statistik dashboard: $e');
    }
  }

  /// Mendapatkan data peminjaman mingguan (7 hari terakhir)
  static Future<List<Map<String, dynamic>>> getWeeklyPeminjamanStats() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));

      final response = await _client
          .from('peminjaman')
          .select('tanggal_pinjam, detail_peminjaman!inner(jumlah)')
          .gte('tanggal_pinjam', weekAgo.toUtc().toIso8601String())
          .lte('tanggal_pinjam', now.toUtc().toIso8601String());

      Map<String, int> dailyCount = {};

      for (int i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        final dateKey = date.toIso8601String().split('T')[0];
        dailyCount[dateKey] = 0;
      }

      for (var peminjaman in response) {
        final tanggal = (peminjaman['tanggal_pinjam'] as String).split('T')[0];
        final details = peminjaman['detail_peminjaman'] as List;

        int jumlahTotal = 0;
        for (var detail in details) {
          jumlahTotal += (detail['jumlah'] as num).toInt();
        }

        if (dailyCount.containsKey(tanggal)) {
          dailyCount[tanggal] = (dailyCount[tanggal] ?? 0) + jumlahTotal;
        }
      }

      final List<String> dayLabels = [
        'Sen',
        'Sel',
        'Rab',
        'Kam',
        'Jum',
        'Sab',
        'Min',
      ];
      List<Map<String, dynamic>> result = [];

      for (int i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        final dateKey = date.toIso8601String().split('T')[0];
        final dayIndex = date.weekday - 1; // 0 = Senin, 6 = Minggu

        result.add({
          'date': dateKey,
          'day_label': dayLabels[dayIndex],
          'total': dailyCount[dateKey] ?? 0,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Gagal memuat data grafik: $e');
    }
  }


  // DASHBOARD REALTIME SUBSCRIPTIONS

  /// Subscribe ke perubahan tabel 'alat' → update stat cards secara realtime
  static RealtimeChannel subscribeToDashboardAlat(
    Function(Map<String, dynamic>) onData,
  ) {
    final channel = _client.channel('dashboard_alat_realtime');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alat',
          callback: (payload) async {
            final data = await getDashboardStats();
            onData(data);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe ke perubahan tabel 'peminjaman' dan 'detail_peminjaman' → update chart realtime
  static RealtimeChannel subscribeToDashboardPeminjaman(
    Function(List<Map<String, dynamic>>) onData,
  ) {
    final channel = _client.channel('dashboard_peminjaman_realtime');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) async {
            final data = await getWeeklyPeminjamanStats();
            onData(data);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'detail_peminjaman',
          callback: (payload) async {
            final data = await getWeeklyPeminjamanStats();
            onData(data);
          },
        )
        .subscribe();

    return channel;
  }


  // KATEGORI SERVICES
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

  static Future<void> updateKategori({
    required int idKategori,
    String? namaKategori,
    String? prefixKode,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (namaKategori != null) updateData['nama_kategori'] = namaKategori;
      if (prefixKode != null) updateData['prefix_kode'] = prefixKode;

      if (updateData.isEmpty) {
        throw Exception('Tidak ada data yang diupdate');
      }

      await _client
          .from('kategori')
          .update(updateData)
          .eq('id_kategori', idKategori);
    } catch (e) {
      throw Exception('Gagal mengupdate kategori: $e');
    }
  }

  static Future<void> hapusKategori(int idKategori) async {
    try {
      await _client.from('kategori').delete().eq('id_kategori', idKategori);
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> searchKategori(
    String keyword,
  ) async {
    try {
      if (keyword.trim().isEmpty) {
        return getKategori();
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


  // ALAT SERVICES
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
      if (dendaPerHari != null) updateData['denda_per_hari'] = dendaPerHari;
      if (deskripsi != null) updateData['deskripsi'] = deskripsi;
      if (kondisi != null) updateData['kondisi'] = kondisi;

      if (stokTotal != null) {
        final currentAlat = await _client
            .from('alat')
            .select('stok_total, stok_tersedia')
            .eq('id_alat', idAlat)
            .single();

        final int currentTotal = currentAlat['stok_total'];
        final int currentTersedia = currentAlat['stok_tersedia'];

        final int selisih = stokTotal - currentTotal;
        final int newTersedia = currentTersedia + selisih;

        if (newTersedia < 0) {
          throw Exception(
            'Stok tidak bisa dikurangi karena ada ${currentTotal - currentTersedia} alat yang sedang dipinjam',
          );
        }

        updateData['stok_total'] = stokTotal;
        updateData['stok_tersedia'] = newTersedia;
      }

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


  // PEMINJAMAN SERVICES
  static Future<String> _generateKodePeminjaman() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final prefix = 'MCHL-$dateStr-';

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

  static Future<void> createPeminjaman({
    required String idUser,
    required int idAlat,
    required int jumlah,
    required DateTime tanggalPinjam,
    required DateTime estimasiKembali,
  }) async {
    try {
      final kodePeminjaman = await _generateKodePeminjaman();

      final peminjamanResponse = await _client
          .from('peminjaman')
          .insert({
            'kode_peminjaman': kodePeminjaman,
            'id_user': idUser,
            'tanggal_pinjam': tanggalPinjam.toUtc().toIso8601String(),
            'estimasi_kembali': estimasiKembali.toUtc().toIso8601String(),
            'status': 'menunggu',
          })
          .select()
          .single();

      final idPeminjaman = peminjamanResponse['id_peminjaman'];

      await _client.from('detail_peminjaman').insert({
        'id_peminjaman': idPeminjaman,
        'id_alat': idAlat,
        'jumlah': jumlah,
      });

      await _client.from('log_aktivitas').insert({
        'id_user': idUser,
        'aktivitas': 'Mengajukan peminjaman $kodePeminjaman',
      });
    } catch (e) {
      throw Exception('Gagal membuat peminjaman: $e');
    }
  }

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
              alat!inner(nama_alat, denda_per_hari, id_alat)
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

  static Future<void> updateStatusPeminjaman({
    required int idPeminjaman,
    required String newStatus,
    required String idPetugas,
    int? stokDikurangi,
    int? idAlat,
  }) async {
    try {
      await _client
          .from('peminjaman')
          .update({'status': newStatus})
          .eq('id_peminjaman', idPeminjaman);

      if (newStatus == 'disetujui' && stokDikurangi != null && idAlat != null) {
        await _client.rpc(
          'kurangi_stok_tersedia',
          params: {'p_id_alat': idAlat, 'p_jumlah': stokDikurangi},
        );
      }

      final actionText = newStatus == 'disetujui' ? 'menyetujui' : 'menolak';
      await _client.from('log_aktivitas').insert({
        'id_user': idPetugas,
        'aktivitas': 'Petugas $actionText peminjaman ID: $idPeminjaman',
      });
    } catch (e) {
      throw Exception('Gagal update status: $e');
    }
  }

  static Future<void> kembalikanAlat({
    required int idPeminjaman,
    required int idAlat,
    required int jumlah,
    required DateTime tanggalPengembalian,
    required int terlambat,
    required int totalDenda,
  }) async {
    try {
      await _client.from('pengembalian').insert({
        'id_peminjaman': idPeminjaman,
        'tanggal_pengembalian': tanggalPengembalian.toIso8601String().split(
          'T',
        )[0],
        'terlambat': terlambat,
        'total_denda': totalDenda,
      });

      await _client
          .from('peminjaman')
          .update({'status': 'dikembalikan'})
          .eq('id_peminjaman', idPeminjaman);

      await _client.rpc(
        'tambah_stok_tersedia',
        params: {'p_id_alat': idAlat, 'p_jumlah': jumlah},
      );
    } catch (e) {
      throw Exception('Gagal mengembalikan alat: $e');
    }
  }

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


  // LAPORAN SERVICES
  static Future<List<Map<String, dynamic>>> getLaporanPeminjaman({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('peminjaman').select('''
            id_peminjaman,
            kode_peminjaman,
            tanggal_pinjam,
            estimasi_kembali,
            status,
            users!inner(username),
            detail_peminjaman!inner(
              jumlah,
              alat!inner(nama_alat, kode_alat)
            ),
            pengembalian(tanggal_pengembalian, total_denda)
          ''');

      if (startDate != null) {
        query = query.gte(
          'tanggal_pinjam',
          startDate.toUtc().toIso8601String(),
        );
      }
      if (endDate != null) {
        query = query.lte('tanggal_pinjam', endDate.toUtc().toIso8601String());
      }

      final response = await query.order('tanggal_pinjam', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat laporan: $e');
    }
  }

  static Future<int> getTotalAlatDipinjam({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('peminjaman').select('''
            detail_peminjaman!inner(jumlah)
          ''');

      if (startDate != null) {
        query = query.gte(
          'tanggal_pinjam',
          startDate.toUtc().toIso8601String(),
        );
      }
      if (endDate != null) {
        query = query.lte('tanggal_pinjam', endDate.toUtc().toIso8601String());
      }

      final response = await query;

      int total = 0;
      for (var item in response) {
        final details = item['detail_peminjaman'] as List;
        for (var detail in details) {
          total += (detail['jumlah'] as num).toInt();
        }
      }

      return total;
    } catch (e) {
      throw Exception('Gagal menghitung total: $e');
    }
  }

  /// Subscribe ke perubahan peminjaman dan detail_peminjaman untuk laporan realtime
  static RealtimeChannel subscribeToLaporan(Function() onData) {
    final channel = _client.channel('laporan_realtime');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) async {
            onData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'detail_peminjaman',
          callback: (payload) async {
            onData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pengembalian',
          callback: (payload) async {
            onData();
          },
        )
        .subscribe();

    return channel;
  }
}
