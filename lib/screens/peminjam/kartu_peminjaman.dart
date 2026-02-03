import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoanCardScreen extends StatefulWidget {
  final int idPeminjaman;

  const LoanCardScreen({super.key, required this.idPeminjaman});

  @override
  State<LoanCardScreen> createState() => _LoanCardScreenState();
}

class _LoanCardScreenState extends State<LoanCardScreen> {
  bool isLoading = true;

  String username = '-';
  String alat = '-';
  DateTime? tglPinjam;
  DateTime? estimasi;
  DateTime? tglKembali;
  int denda = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('peminjaman')
          .select('''
            tanggal_pinjam,
            estimasi_kembali,
            users!inner(username),
            detail_peminjaman!inner(
              alat!inner(nama_alat)
            ),
            pengembalian(tanggal_pengembalian, total_denda)
          ''')
          .eq('id_peminjaman', widget.idPeminjaman)
          .single();

      // Parse user
      final userData = data['users'];
      username = userData['username'] ?? '-';

      // Parse alat dari detail_peminjaman
      final detailList = data['detail_peminjaman'] as List;
      if (detailList.isNotEmpty) {
        final detail = detailList.first;
        final alatData = detail['alat'];
        alat = alatData['nama_alat'] ?? '-';
      }

      // Parse tanggal
      tglPinjam = DateTime.parse(data['tanggal_pinjam']);
      estimasi = DateTime.parse(data['estimasi_kembali']);

      // Parse pengembalian (jika ada)
      final pengembalianList = data['pengembalian'] as List;
      if (pengembalianList.isNotEmpty) {
        final pengembalian = pengembalianList.first;
        denda = pengembalian['total_denda'] ?? 0;
        
        // Parse tanggal pengembalian jika ada
        if (pengembalian['tanggal_pengembalian'] != null) {
          tglKembali = DateTime.parse(pengembalian['tanggal_pengembalian']);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR LOAD LOAN CARD: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? '-' : DateFormat('d MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _header(),
                const SizedBox(height: 30),
                _card(),
                const Spacer(),
                _buttonClose(),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 45, 20, 25),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF7DA0CA),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Text('Kartu Peminjaman',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _card() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF769DCB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF769DCB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
  
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset('assets/images/mechloan.png'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kartu Peminjaman',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _row('User Peminjam', username),
                  _row('Alat', alat),
                  _row('Tanggal Peminjaman', _fmt(tglPinjam)),
                  _row('Estimasi Pengembalian', _fmt(estimasi)),
                  if (tglKembali != null) 
                    _row('Dikembalikan', _fmt(tglKembali)),
                  _row('Denda Keterlambatan', 
                      denda == 0 ? 'Rp 0' : 'Rp ${NumberFormat('#,###', 'id_ID').format(denda)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Button Close
  Widget _buttonClose() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B7280),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
          ),
          child: Text(
            'Close',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}