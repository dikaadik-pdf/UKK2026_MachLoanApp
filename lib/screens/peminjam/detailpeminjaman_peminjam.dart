import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/kartu_peminjaman.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';

// DATA MODEL
class PeminjamanModel {
  final int idPeminjaman;
  final String namaAlat;
  final int idAlat;
  final int jumlah;
  final String status;
  final DateTime tanggalPinjaman;
  final DateTime estimasiPengembalian;
  final int denda;
  final String kodePeminjaman;
  final int dendaPerHari;
  final int terlambat;

  PeminjamanModel({
    required this.idPeminjaman,
    required this.namaAlat,
    required this.idAlat,
    required this.jumlah,
    required this.status,
    required this.tanggalPinjaman,
    required this.estimasiPengembalian,
    required this.denda,
    required this.kodePeminjaman,
    required this.dendaPerHari,
    required this.terlambat,
  });
}

// SCREEN
class PeminjamanPeminjamScreen extends StatefulWidget {
  final String username;

  const PeminjamanPeminjamScreen({super.key, required this.username});

  @override
  State<PeminjamanPeminjamScreen> createState() =>
      _PeminjamanPeminjamScreenState();
}

class _PeminjamanPeminjamScreenState extends State<PeminjamanPeminjamScreen> {
  String activeFilter = 'menunggu';
  bool isLoading = true;
  List<PeminjamanModel> data = [];
  RealtimeChannel? _channel;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> statusMap = {
    'menunggu': 'menunggu',
    'disetujui': 'disetujui',
    'ditolak': 'ditolak',
    'dikembalikan': 'dikembalikan',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeToRealtimeUpdates() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('peminjaman_peminjam_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) {
            _loadData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pengembalian',
          callback: (payload) {
            _loadData();
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final userId = await SupabaseServices.getUserIdByUsername(
        widget.username,
      );

      final supabase = Supabase.instance.client;

      final List<Map<String, dynamic>> response = await supabase
          .from('peminjaman')
          .select('''
            id_peminjaman,
            kode_peminjaman,
            status,
            tanggal_pinjam,
            estimasi_kembali,
            detail_peminjaman!inner(
              jumlah,
              alat!inner(nama_alat, id_alat, denda_per_hari)
            ),
            pengembalian(tanggal_pengembalian, total_denda, terlambat)
          ''')
          .eq('id_user', userId)
          .eq('status', statusMap[activeFilter]!)
          .order('tanggal_pinjam', ascending: false);

      data = response.map<PeminjamanModel>((e) {
        final detailList = e['detail_peminjaman'] as List;
        final detail = detailList.first;
        final alat = detail['alat'];

        final pengembalianList = e['pengembalian'] as List;
        final pengembalian = pengembalianList.isNotEmpty
            ? pengembalianList.first
            : null;

        return PeminjamanModel(
          idPeminjaman: e['id_peminjaman'],
          kodePeminjaman: e['kode_peminjaman'] ?? '-',
          namaAlat: alat['nama_alat'],
          idAlat: alat['id_alat'],
          jumlah: detail['jumlah'],
          status: e['status'],
          tanggalPinjaman: DateTime.parse(e['tanggal_pinjam']),
          estimasiPengembalian: DateTime.parse(e['estimasi_kembali']),
          denda: pengembalian?['total_denda'] ?? 0,
          dendaPerHari: alat['denda_per_hari'] ?? 0,
          terlambat: pengembalian?['terlambat'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('ERROR PEMINJAMAN: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleKembalikan(PeminjamanModel d) async {
    // Gunakan ConfirmationDialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Konfirmasi',
        subtitle: 'Apakah Anda yakin ingin mengembalikan "${d.namaAlat}"?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirm != true) return;

    try {
      final now = DateTime.now();

      // Hitung denda
      int daysLate = 0;
      int totalDenda = 0;
      if (now.isAfter(d.estimasiPengembalian)) {
        daysLate = now.difference(d.estimasiPengembalian).inDays;
        totalDenda = daysLate * (d.dendaPerHari > 0 ? d.dendaPerHari : 5000);
      }

      await SupabaseServices.kembalikanAlat(
        idPeminjaman: d.idPeminjaman,
        idAlat: d.idAlat,
        jumlah: d.jumlah,
        tanggalPengembalian: now,
        terlambat: daysLate,
        totalDenda: totalDenda,
      );

      // Reload data
      await _loadData();

      if (!mounted) return;

      // Gunakan SuccessDialog
      await showDialog(
        context: context,
        builder: (context) => SuccessDialog(
          title: 'Berhasil!',
          subtitle: 'Peminjaman berhasil dikembalikan!\nStok alat telah dikembalikan.',
          onOk: () => Navigator.pop(context),
        ),
      );
    } catch (e) {
      debugPrint('ERROR KEMBALIKAN: $e');

      if (!mounted) return;

      // Tetap gunakan SnackBar untuk error
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

  // HANDLE LIHAT KARTU PINJAM
  void _handleLihatKartu(PeminjamanModel d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanCardScreen(idPeminjaman: d.idPeminjaman),
      ),
    );
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

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
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
                : data.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 10,
                          ),
                          itemCount: data.length,
                          itemBuilder: (context, index) =>
                              _buildLoanCard(data[index]),
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
        _loadData();
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
            'Status: ${_getStatusLabel(activeFilter)}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'disetujui':
        return 'Pengembalian';
      case 'ditolak':
        return 'Ditolak';
      case 'dikembalikan':
        return 'Selesai';
      default:
        return status;
    }
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

  Widget _buildLoanCard(PeminjamanModel d) {
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
                Text(
                  d.namaAlat,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Kode: ${d.kodePeminjaman}',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                _buildTextRow('Jumlah', ': ${d.jumlah} unit'),
                _buildTextRow(
                  'Tanggal Peminjaman',
                  ': ${_formatDate(d.tanggalPinjaman.toIso8601String())}',
                ),
                _buildTextRow(
                  'Estimasi Pengembalian',
                  ': ${_formatDate(d.estimasiPengembalian.toIso8601String())}',
                ),
                if (d.terlambat > 0)
                  _buildTextRow('Keterlambatan', ': ${d.terlambat} hari'),
                if (d.dendaPerHari > 0 && d.status == 'disetujui')
                  _buildTextRow(
                    'Denda/Hari',
                    ': Rp ${_formatCurrency(d.dendaPerHari)}',
                  ),
              ],
            ),
          ),

          // Inner child section berdasarkan status
          _buildInnerChild(d),
        ],
      ),
    );
  }

  Widget _buildInnerChild(PeminjamanModel d) {
    if (d.status == 'menunggu') {
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
    } else if (d.status == 'disetujui') {
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
                  onPressed: () => _handleLihatKartu(d),
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
                  onPressed: () => _handleKembalikan(d),
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
    } else if (d.status == 'ditolak') {
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
    } else if (d.status == 'dikembalikan') {
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
}