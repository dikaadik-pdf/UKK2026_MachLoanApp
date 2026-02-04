import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeminjamanAdminScreen extends StatefulWidget {
  const PeminjamanAdminScreen({Key? key}) : super(key: key);

  @override
  State<PeminjamanAdminScreen> createState() => _PeminjamanAdminScreenState();
}

class _PeminjamanAdminScreenState extends State<PeminjamanAdminScreen> {
  String activeFilter = 'menunggu';
  List<Map<String, dynamic>> peminjamanList = [];
  bool isLoading = true;
  RealtimeChannel? _channel;
  String? currentUserId;
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Get current user ID and role
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        currentUserId = user.id;

        // Get user role from users table untuk cek permission
        final userData = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id_user', user.id)
            .single();

        currentUserRole = userData['role'];
      }

      await _loadPeminjamanData();
      _subscribeToRealtimeUpdates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _loadPeminjamanData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      // Load data berdasarkan filter status
      final data = await _getPeminjamanByStatus();

      if (mounted) {
        setState(() {
          peminjamanList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getPeminjamanByStatus() async {
    if (currentUserId == null) return [];

    try {
      // Admin melihat semua peminjaman
      final response = await Supabase.instance.client
          .from('peminjaman')
          .select('''
            *,
            users!inner(username),
            detail_peminjaman!inner(
              jumlah,
              alat!inner(nama_alat, denda_per_hari)
            ),
            pengembalian(tanggal_pengembalian, total_denda, terlambat)
          ''')
          .eq('status', activeFilter)
          .order('tanggal_pinjam', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat peminjaman: $e');
    }
  }

  void _subscribeToRealtimeUpdates() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('peminjaman_admin_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) {
            _loadPeminjamanData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pengembalian',
          callback: (payload) {
            _loadPeminjamanData();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day}/${months[date.month - 1]}/${date.year.toString().substring(2)}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'dikembalikan':
        return 'Dikembalikan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return const Color(0xFF769DCB);
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'dikembalikan':
        return const Color(0xFF769DCB);
      default:
        return const Color(0xFF769DCB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF769DCB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Peminjaman',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // --- FILTER BAR ---
          CustomFilterBar(
            filters: const ['menunggu', 'disetujui', 'ditolak', 'dikembalikan'],
            filterLabels: const ['Menunggu', 'Disetujui', 'Ditolak', 'Selesai'],
            initialFilter: activeFilter,
            onFilterSelected: (val) {
              setState(() => activeFilter = val);
              _loadPeminjamanData();
            },
          ),

          const SizedBox(height: 15),

          // Informasi untuk status menunggu
          if (activeFilter == 'menunggu') _buildInfoPending(),

          // --- LIST CONTENT ---
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : peminjamanList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadPeminjamanData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 10,
                      ),
                      itemCount: peminjamanList.length,
                      itemBuilder: (context, index) =>
                          _buildLoanCard(peminjamanList[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data peminjaman',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${_getStatusDisplay(activeFilter)}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPending() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE52510),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Perhatian!\nPeminjaman menunggu persetujuan Petugas dan Jangan Lupa Ingatkan Petugas Untuk Melakukan Pengecekan Peminjaman',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> data) {
    final detailPeminjaman = data['detail_peminjaman'] as List;
    final firstDetail = detailPeminjaman.isNotEmpty
        ? detailPeminjaman[0]
        : null;
    final alat = firstDetail?['alat'];
    final namaAlat = alat?['nama_alat'] ?? 'Unknown';
    final jumlah = firstDetail?['jumlah'] ?? 0;
    final dendaPerHari = alat?['denda_per_hari'] ?? 0;

    final pengembalianList = data['pengembalian'] as List?;
    final pengembalian =
        (pengembalianList != null && pengembalianList.isNotEmpty)
        ? pengembalianList.first
        : null;
    final totalDenda = pengembalian?['total_denda'] ?? 0;
    final terlambat = pengembalian?['terlambat'] ?? 0;

    final status = data['status'] as String;
    final kodePeminjaman = data['kode_peminjaman'] ?? '-';

    // Get username dari relasi users
    final users = data['users'];
    final username = users?['username'] ?? 'Unknown';

    // Cek apakah bisa dihapus: admin dan status dikembalikan
    final canDelete = currentUserRole == 'admin' && status == 'dikembalikan';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      namaAlat,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white70,
                        size: 24,
                      ),
                      onPressed: () =>
                          _showDeleteConfirmation(data['id_peminjaman']),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Kode: $kodePeminjaman',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
              ),
              const SizedBox(height: 5),
              // Tampilkan username peminjam
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      username,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadges(status, totalDenda, terlambat),
              const SizedBox(height: 10),
              _buildTextRow('Jumlah', ': $jumlah unit'),
              _buildTextRow(
                'Tanggal Peminjaman',
                ': ${_formatDate(data['tanggal_pinjam'])}',
              ),
              _buildTextRow(
                'Estimasi Pengembalian',
                ': ${_formatDate(data['estimasi_kembali'])}',
              ),
              if (terlambat > 0)
                _buildTextRow('Keterlambatan', ': $terlambat hari'),
              if (dendaPerHari > 0 && status == 'disetujui')
                _buildTextRow(
                  'Denda/Hari',
                  ': Rp ${_formatCurrency(dendaPerHari)}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadges(String status, int totalDenda, int terlambat) {
    if (status == 'disetujui') {
      return Wrap(
        spacing: 10,
        runSpacing: 5,
        children: [_badge('Disetujui', Colors.green)],
      );
    } else if (status == 'dikembalikan') {
      return Wrap(
        spacing: 10,
        runSpacing: 5,
        children: [
          _badge('Dikembalikan', const Color(0xFF769DCB)),
          if (totalDenda > 0)
            _badge('Denda: Rp ${_formatCurrency(totalDenda)}', Colors.red),
          if (terlambat > 0)
            _badge('Terlambat: $terlambat hari', Colors.orange),
        ],
      );
    }

    return _badge(_getStatusDisplay(status), _getStatusColor(status));
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _showDeleteConfirmation(int idPeminjaman) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Riwayat', style: GoogleFonts.poppins()),
        content: Text(
          'Apakah Anda yakin ingin menghapus riwayat peminjaman ini? Data yang sudah dihapus tidak dapat dikembalikan.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && currentUserId != null) {
      try {
        // Get kode peminjaman untuk log
        final peminjamanData = await Supabase.instance.client
            .from('peminjaman')
            .select('kode_peminjaman')
            .eq('id_peminjaman', idPeminjaman)
            .single();

        final kodePeminjaman = peminjamanData['kode_peminjaman'];

        // Hapus peminjaman (cascade akan menghapus detail_peminjaman dan pengembalian)
        await Supabase.instance.client
            .from('peminjaman')
            .delete()
            .eq('id_peminjaman', idPeminjaman);

        // Log aktivitas admin
        await Supabase.instance.client.from('log_aktivitas').insert({
          'id_user': currentUserId,
          'aktivitas': 'Admin menghapus riwayat peminjaman $kodePeminjaman',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Riwayat peminjaman berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPeminjamanData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class CustomFilterBar extends StatelessWidget {
  final List<String> filters;
  final List<String> filterLabels;
  final Function(String) onFilterSelected;
  final String initialFilter;

  const CustomFilterBar({
    Key? key,
    required this.filters,
    required this.filterLabels,
    required this.onFilterSelected,
    required this.initialFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final label = filterLabels[index];
          final isSelected = filter == initialFilter;

          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterSelected(filter),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF769DCB)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
