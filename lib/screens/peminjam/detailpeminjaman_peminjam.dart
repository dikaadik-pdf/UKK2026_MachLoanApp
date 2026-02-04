import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  PeminjamanModel({
    required this.idPeminjaman,
    required this.namaAlat,
    required this.idAlat,
    required this.jumlah,
    required this.status,
    required this.tanggalPinjaman,
    required this.estimasiPengembalian,
    required this.denda,
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
  String activeFilter = 'Menunggu';
  bool isLoading = true;

  List<PeminjamanModel> data = [];

  final Map<String, String> statusMap = {
    'Menunggu': 'menunggu',
    'Pengembalian': 'disetujui',
    'Ditolak': 'ditolak',
    'Selesai': 'dikembalikan',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
            status,
            tanggal_pinjam,
            estimasi_kembali,
            detail_peminjaman!inner(
              jumlah,
              alat!inner(nama_alat, id_alat)
            ),
            pengembalian(tanggal_pengembalian, total_denda)
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
          namaAlat: alat['nama_alat'],
          idAlat: alat['id_alat'],
          jumlah: detail['jumlah'],
          status: e['status'],
          tanggalPinjaman: DateTime.parse(e['tanggal_pinjam']),
          estimasiPengembalian: DateTime.parse(e['estimasi_kembali']),
          denda: pengembalian?['total_denda'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('ERROR PEMINJAMAN: $e');
    }

    setState(() => isLoading = false);
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
        totalDenda = daysLate * 5000;
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

  String _fmt(DateTime d) => DateFormat('d/MMM/yy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 15),
          _buildFilter(),
          if (activeFilter == 'Pengembalian') _buildInfoDenda(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) =>
                        _buildLoanCard(data[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 45, 20, 25),
      decoration: const BoxDecoration(
        color: Color(0xFF769DCB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'Peminjaman',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // FILTER
  Widget _buildFilter() {
    final filters = ['Menunggu', 'Pengembalian', 'Ditolak', 'Selesai'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((f) {
          final isActive = activeFilter == f;
          return GestureDetector(
            onTap: () {
              setState(() => activeFilter = f);
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF769DCB) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // CARD
  Widget _buildLoanCard(PeminjamanModel d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content utama card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.namaAlat,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusBadge(d),
                const SizedBox(height: 12),
                _buildRow('Tanggal Peminjaman', _fmt(d.tanggalPinjaman)),
                _buildRow(
                  'Estimasi Pengembalian',
                  _fmt(d.estimasiPengembalian),
                ),
              ],
            ),
          ),

          if (activeFilter == 'Pengembalian')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF769DCB), // Inner container lebih terang
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Button Lihat Kartu Pinjam
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
                  // Button Kembalikan
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
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PeminjamanModel d) {
    if (activeFilter == 'Pengembalian') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE52510),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Denda: ${d.denda}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF769DCB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        activeFilter == 'Selesai' ? 'Dikembalikan' : activeFilter,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
          ),
        ),
        Text(
          ': $value',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildInfoDenda() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE52510),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Perhatian Baca Baik Baik!\nSetiap keterlambatan pengembalian maka dikenakan denda sebesar 5000/hari',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}