import 'package:intl/intl.dart';

class LogAktivitasModel {
  final int idLog;
  final String idUser;
  final String aktivitas;
  final DateTime waktuAktivitas;
  final String namaUser;
  final String role;

  LogAktivitasModel({
    required this.idLog,
    required this.idUser,
    required this.aktivitas,
    required this.waktuAktivitas,
    required this.namaUser,
    required this.role,
  });

  /// Parse dari JSON response Supabase
  factory LogAktivitasModel.fromJson(Map<String, dynamic> json) {
    // Handle users data - bisa berupa Map atau List
    String username = 'Unknown User';
    String userRole = 'unknown';

    if (json['users'] != null) {
      final usersData = json['users'];
      
      // Jika users adalah Map langsung
      if (usersData is Map<String, dynamic>) {
        username = usersData['username'] ?? 'Unknown User';
        userRole = usersData['role'] ?? 'unknown';
      } 
      // Jika users adalah List (edge case, tapi handle juga)
      else if (usersData is List && usersData.isNotEmpty) {
        final firstUser = usersData[0] as Map<String, dynamic>;
        username = firstUser['username'] ?? 'Unknown User';
        userRole = firstUser['role'] ?? 'unknown';
      }
    }

    return LogAktivitasModel(
      idLog: json['id_log'] as int,
      idUser: json['id_user'] as String,
      aktivitas: json['aktivitas'] as String? ?? '',
      waktuAktivitas: DateTime.parse(json['waktu_aktivitas'] as String),
      namaUser: username,
      role: userRole,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_log': idLog,
      'id_user': idUser,
      'aktivitas': aktivitas,
      'waktu_aktivitas': waktuAktivitas.toIso8601String(),
      'users': {
        'username': namaUser,
        'role': role,
      }
    };
  }

  /// Format tanggal untuk display
  String get tanggal {
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return formatter.format(waktuAktivitas);
  }

  /// Format role untuk display
  String get roleFormatted {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'petugas':
        return 'Petugas';
      case 'peminjam':
        return 'Peminjam';
      default:
        return 'Unknown';
    }
  }

  /// Copy with method untuk update data
  LogAktivitasModel copyWith({
    int? idLog,
    String? idUser,
    String? aktivitas,
    DateTime? waktuAktivitas,
    String? namaUser,
    String? role,
  }) {
    return LogAktivitasModel(
      idLog: idLog ?? this.idLog,
      idUser: idUser ?? this.idUser,
      aktivitas: aktivitas ?? this.aktivitas,
      waktuAktivitas: waktuAktivitas ?? this.waktuAktivitas,
      namaUser: namaUser ?? this.namaUser,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'LogAktivitasModel(idLog: $idLog, namaUser: $namaUser, role: $role, aktivitas: $aktivitas, waktu: $waktuAktivitas)';
  }
}