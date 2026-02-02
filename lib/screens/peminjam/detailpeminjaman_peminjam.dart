import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';

// =====================
// DATA MODEL
// =====================
class PeminjamanModel {
  final int idPeminjaman;
  final String namaAlat;
  final String status;
  final DateTime tanggalPinjaman;
  final DateTime estimasiPengembalian;
  final DateTime? dikembalikanPada;
  final int denda;

  PeminjamanModel({
    required this.idPeminjaman,
    required this.namaAlat,
    required this.status,
    required this.tanggalPinjaman,
    required this.estimasiPengembalian,
    this.dikembalikanPada,
    required this.denda,
  });
}

// =====================
// SCREEN
// =====================
class PeminjamanPeminjamScreen extends StatefulWidget {
  final String username;

  const PeminjamanPeminjamScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<PeminjamanPeminjamScreen> createState() =>
      _PeminjamanPeminjamScreenState();
}

class _PeminjamanPeminjamScreenState extends State<PeminjamanPeminjamScreen> {
  String activeFilter = 'Menunggu';
  bool isLoading = true;

  List<PeminjamanModel> data = [];

  /// MAP FILTER -> STATUS DATABASE
  /// ACC PETUGAS = status 'dipinjam' -> MASUK PENGEMBALIAN
  final Map<String, String> statusMap = {
    'Menunggu': 'menunggu',
    'Pengembalian': 'dipinjam',
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
      final userId =
          await SupabaseServices.getUserIdByUsername(widget.username);

      final supabase = Supabase.instance.client;

      final List<Map<String, dynamic>> response =
          await supabase.from('peminjaman').select('''
            id_peminjaman,
            status,
            tanggal_pinjam,
            estimasi_kembali,
            detail_peminjaman!inner(
              alat!inner(nama_alat)
            ),
            pengembalian(tanggal_pengembalian, total_denda)
          ''')
          .eq('id_user', userId)
          // INI KUNCI FILTER
          .eq('status', statusMap[activeFilter]!)
          .order('tanggal_pinjam', ascending: false);

      data = response.map<PeminjamanModel>((e) {
        final detailList = e['detail_peminjaman'] as List;
        final detail = detailList.first;
        final alat = detail['alat'];

        final pengembalianList = e['pengembalian'] as List;
        final pengembalian =
            pengembalianList.isNotEmpty ? pengembalianList.first : null;

        return PeminjamanModel(
          idPeminjaman: e['id_peminjaman'],
          namaAlat: alat['nama_alat'],
          status: e['status'],
          tanggalPinjaman: DateTime.parse(e['tanggal_pinjam']),
          estimasiPengembalian: DateTime.parse(e['estimasi_kembali']),
          dikembalikanPada: pengembalian != null
              ? DateTime.parse(pengembalian['tanggal_pengembalian'])
              : null,
          denda: pengembalian?['total_denda'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('ERROR PEMINJAMAN: $e');
    }

    setState(() => isLoading = false);
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
                        horizontal: 25, vertical: 10),
                    itemCount: data.length,
                    itemBuilder: (context, index) =>
                        _buildLoanCard(data[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // =====================
  // HEADER
  // =====================
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
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('Peminjaman',
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // =====================
  // FILTER
  // =====================
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isActive ? const Color(0xFF769DCB) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =====================
  // CARD
  // =====================
  Widget _buildLoanCard(PeminjamanModel d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.namaAlat,
                style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            _buildStatusBadge(d),
            const SizedBox(height: 12),
            _buildRow('Tanggal Peminjaman', _fmt(d.tanggalPinjaman)),
            _buildRow(
                'Estimasi Pengembalian', _fmt(d.estimasiPengembalian)),
            if (d.dikembalikanPada != null)
              _buildRow(
                  'Dikembalikan Pada', _fmt(d.dikembalikanPada!)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PeminjamanModel d) {
    if (activeFilter == 'Pengembalian') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFE52510),
            borderRadius: BorderRadius.circular(8)),
        child: Text('Denda: ${d.denda}',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFF769DCB),
          borderRadius: BorderRadius.circular(8)),
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
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 10)),
        ),
        Text(': $value',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 10)),
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
      child: Text(
        'Setiap keterlambatan dikenakan denda 5000 / hari',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
