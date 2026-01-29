class LogAktivitasModel {
  final String id;
  final String namaUser;
  final String role;
  final String aksi;
  final String tanggal;

  LogAktivitasModel({
    required this.id,
    required this.namaUser,
    required this.role,
    required this.aksi,
    required this.tanggal,
  });

  // Memudahkan jika nanti data datang dari database/backend
  factory LogAktivitasModel.fromMap(Map<String, dynamic> map) {
    return LogAktivitasModel(
      id: map['id'] ?? '',
      namaUser: map['namaUser'] ?? '',
      role: map['role'] ?? '',
      aksi: map['aksi'] ?? '',
      tanggal: map['tanggal'] ?? '',
    );
  }
}