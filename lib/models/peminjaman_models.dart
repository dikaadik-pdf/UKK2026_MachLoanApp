class PeminjamanModel {
  final String id;
  final String namaAlat;
  final String status; // 'Menunggu', 'Pengembalian', 'Ditolak', 'Selesai'
  final String tanggalPinjaman;
  final String estimasiPengembalian;
  final String? dikembalikanPada;
  final int denda;

  PeminjamanModel({
    required this.id,
    required this.namaAlat,
    required this.status,
    required this.tanggalPinjaman,
    required this.estimasiPengembalian,
    this.dikembalikanPada,
    this.denda = 0,
  });
}