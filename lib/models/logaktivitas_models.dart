import 'package:intl/intl.dart';

class LogAktivitasModel {
  final String id;
  final String idUser;
  final String namaUser;
  final String role;
  final String aksi;
  final DateTime waktuAktivitas;

  LogAktivitasModel({
    required this.id,
    required this.idUser,
    required this.namaUser,
    required this.role,
    required this.aksi,
    required this.waktuAktivitas,
  });

  String get tanggal {
    return DateFormat('dd/MMM/yy').format(waktuAktivitas);
  }

  String get waktuLengkap {
    return DateFormat('dd MMM yyyy, HH:mm').format(waktuAktivitas);
  }

  String get roleFormatted {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'petugas':
        return 'Petugas';
      case 'peminjam':
        return 'Peminjam';
      default:
        return role;
    }
  }

  factory LogAktivitasModel.fromJson(Map<String, dynamic> json) {
    return LogAktivitasModel(
      id: json['id_log'].toString(),
      idUser: json['id_user'],
      namaUser: json['username'] ?? 'Unknown User',
      role: json['role'] ?? 'unknown',
      aksi: json['aktivitas'] ?? '',
      waktuAktivitas: DateTime.parse(json['waktu_aktivitas']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_log': id,
      'id_user': idUser,
      'username': namaUser,
      'role': role,
      'aktivitas': aksi,
      'waktu_aktivitas': waktuAktivitas.toIso8601String(),
    };
  }

  LogAktivitasModel copyWith({
    String? id,
    String? idUser,
    String? namaUser,
    String? role,
    String? aksi,
    DateTime? waktuAktivitas,
  }) {
    return LogAktivitasModel(
      id: id ?? this.id,
      idUser: idUser ?? this.idUser,
      namaUser: namaUser ?? this.namaUser,
      role: role ?? this.role,
      aksi: aksi ?? this.aksi,
      waktuAktivitas: waktuAktivitas ?? this.waktuAktivitas,
    );
  }
}