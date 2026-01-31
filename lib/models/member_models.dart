class MemberModel {
  final String id;      
  final String nama;   
  final String status;  

  MemberModel({
    required this.id,
    required this.nama,
    required this.status,
  });


  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id_user'] ?? '',
      nama: json['username'] ?? 'Unknown',
      status: _formatRoleFromDatabase(json['role'] ?? 'peminjam'),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id_user': id,
      'username': nama,
      'role': _roleToDatabase(status),
    };
  }


  static String _formatRoleFromDatabase(String role) {
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

  static String _roleToDatabase(String displayRole) {
    switch (displayRole) {
      case 'Admin':
        return 'admin';
      case 'Petugas':
        return 'petugas';
      case 'Peminjam':
        return 'peminjam';
      default:
        return displayRole.toLowerCase();
    }
  }

  @override
  String toString() {
    return 'MemberModel(id: $id, nama: $nama, status: $status)';
  }
}