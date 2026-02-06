import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/kartu_peminjaman.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        currentUserId = user.id;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadPeminjamanData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
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
      final response = await Supabase.instance.client
          .from('peminjaman')
          .select('''
            *,
            users!inner(username),
            detail_peminjaman!inner(
              jumlah,
              alat!inner(nama_alat, denda_per_hari, id_alat)
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
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
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

  Future<void> _handleKembalikan(Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi', style: GoogleFonts.poppins()),
        content: Text(
          'Apakah Anda yakin ingin mengembalikan alat ini?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Kembalikan',
              style: GoogleFonts.poppins(color: Colors.green),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final now = DateTime.now();
      final estimasiKembali = DateTime.parse(data['estimasi_kembali']);
      final detailPeminjaman = data['detail_peminjaman'] as List;
      final firstDetail = detailPeminjaman.first;
      final idAlat = firstDetail['alat']['id_alat'];
      final jumlah = firstDetail['jumlah'];

      int daysLate = 0;
      int totalDenda = 0;
      if (now.isAfter(estimasiKembali)) {
        daysLate = now.difference(estimasiKembali).inDays;
        final dendaPerHari = firstDetail['alat']['denda_per_hari'] ?? 0;
        totalDenda = (daysLate * dendaPerHari).toInt();
      }

      // Insert pengembalian
      await Supabase.instance.client.from('pengembalian').insert({
        'id_peminjaman': data['id_peminjaman'],
        'tanggal_pengembalian': now.toIso8601String().split('T')[0],
        'terlambat': daysLate,
        'total_denda': totalDenda,
      });

      // Update status peminjaman
      await Supabase.instance.client
          .from('peminjaman')
          .update({'status': 'dikembalikan'})
          .eq('id_peminjaman', data['id_peminjaman']);

      // Tambah stok tersedia
      await Supabase.instance.client.rpc(
        'tambah_stok_tersedia',
        params: {'p_id_alat': idAlat, 'p_jumlah': jumlah},
      );

      // Log aktivitas
      if (currentUserId != null) {
        await Supabase.instance.client.from('log_aktivitas').insert({
          'id_user': currentUserId,
          'aktivitas': 'Admin mengembalikan peminjaman ${data['kode_peminjaman']}',
        });
      }

      await _loadPeminjamanData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Peminjaman berhasil dikembalikan!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengembalikan: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleLihatKartu(int idPeminjaman) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanCardScreen(idPeminjaman: idPeminjaman),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(185),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF769DCB),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Peminjaman',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEBFF),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1F4F6F),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Cari Alat Disini!',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF1F4F6F).withOpacity(0.5),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 22,
                          color: const Color(0xFF1F4F6F).withOpacity(0.7),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          
          // Filter Bar dengan ScrollView
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Text(
                  "Filter : ",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('menunggu', 'Menunggu'),
                        const SizedBox(width: 12),
                        _buildFilterChip('disetujui', 'Pengembalian'),
                        const SizedBox(width: 12),
                        _buildFilterChip('ditolak', 'Ditolak'),
                        const SizedBox(width: 12),
                        _buildFilterChip('dikembalikan', 'Selesai'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Informasi untuk status menunggu
          if (activeFilter == 'menunggu') _buildInfoPending(),

          // List Content
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

  Widget _buildFilterChip(String filterValue, String label) {
    final isSelected = activeFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() => activeFilter = filterValue);
        _loadPeminjamanData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF769DCB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : const Color(0xFF333333),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
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
    final firstDetail = detailPeminjaman.isNotEmpty ? detailPeminjaman[0] : null;
    final alat = firstDetail?['alat'];
    final namaAlat = alat?['nama_alat'] ?? 'Unknown';
    final jumlah = firstDetail?['jumlah'] ?? 0;
    final dendaPerHari = alat?['denda_per_hari'] ?? 0;

    final pengembalianList = data['pengembalian'] as List?;
    final pengembalian = (pengembalianList != null && pengembalianList.isNotEmpty)
        ? pengembalianList.first
        : null;
    final totalDenda = pengembalian?['total_denda'] ?? 0;
    final terlambat = pengembalian?['terlambat'] ?? 0;

    final status = data['status'] as String;
    final kodePeminjaman = data['kode_peminjaman'] ?? '-';

    final users = data['users'];
    final username = users?['username'] ?? 'Unknown';

    final canDelete = currentUserRole == 'admin' && status == 'dikembalikan';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF769DCB),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content utama
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                        onPressed: () => _showDeleteConfirmation(data['id_peminjaman']),
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
          ),

          // Inner child section berdasarkan status
          _buildInnerChild(data, status, totalDenda, terlambat),
        ],
      ),
    );
  }

  Widget _buildInnerChild(
    Map<String, dynamic> data,
    String status,
    int totalDenda,
    int terlambat,
  ) {
    if (status == 'menunggu') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF769DCB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Menunggu',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else if (status == 'disetujui') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () => _handleLihatKartu(data['id_peminjaman']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF788291),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Lihat Kartu Pinjam',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () => _handleKembalikan(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9ACD32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Kembalikan',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'ditolak') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFCE0000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ditolak',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else if (status == 'dikembalikan') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8BB501),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Dikembalikan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
        final peminjamanData = await Supabase.instance.client
            .from('peminjaman')
            .select('kode_peminjaman')
            .eq('id_peminjaman', idPeminjaman)
            .single();

        final kodePeminjaman = peminjamanData['kode_peminjaman'];

        await Supabase.instance.client
            .from('peminjaman')
            .delete()
            .eq('id_peminjaman', idPeminjaman);

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