import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  String kodePeminjaman = '-';
  DateTime? tglPinjam;
  DateTime? estimasi;
  DateTime? tglKembali;
  int denda = 0;
  int jumlah = 0;
  String kodeAlat = '-';

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
            kode_peminjaman,
            tanggal_pinjam,
            estimasi_kembali,
            users!inner(username),
            detail_peminjaman!inner(
              jumlah,
              alat!inner(nama_alat, kode_alat)
            ),
            pengembalian(tanggal_pengembalian, total_denda)
          ''')
          .eq('id_peminjaman', widget.idPeminjaman)
          .single();

      // Parse kode peminjaman
      kodePeminjaman = data['kode_peminjaman'] ?? '-';

      // Parse user
      final userData = data['users'];
      username = userData['username'] ?? '-';

      // Parse alat dari detail_peminjaman
      final detailList = data['detail_peminjaman'] as List;
      if (detailList.isNotEmpty) {
        final detail = detailList.first;
        final alatData = detail['alat'];
        alat = alatData['nama_alat'] ?? '-';
        kodeAlat = alatData['kode_alat'] ?? '-';
        jumlah = detail['jumlah'] ?? 0;
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

  Future<void> _printCard() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue300,
                    borderRadius: pw.BorderRadius.circular(15),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'KARTU PEMINJAMAN',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'ALAT TEKNIK MESIN (MACHLOAN)',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'SMKS BRANTAS KARANGKATES',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Info Card
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(25),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2, color: PdfColors.blue700),
                    borderRadius: pw.BorderRadius.circular(15),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Kode Peminjaman
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue700,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          kodePeminjaman,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 20),

                      // Data Rows
                      _buildPdfRow('User Peminjam', username),
                      _buildPdfDivider(),
                      _buildPdfRow('Alat', alat),
                      _buildPdfDivider(),
                      _buildPdfRow('Kode Alat', kodeAlat),
                      _buildPdfDivider(),
                      _buildPdfRow('Jumlah', '$jumlah Unit'),
                      _buildPdfDivider(),
                      _buildPdfRow('Tanggal Peminjaman', _fmt(tglPinjam)),
                      _buildPdfDivider(),
                      _buildPdfRow('Estimasi Pengembalian', _fmt(estimasi)),
                      
                      if (tglKembali != null) ...[
                        _buildPdfDivider(),
                        _buildPdfRow('Dikembalikan', _fmt(tglKembali)),
                      ],
                      
                      _buildPdfDivider(),
                      _buildPdfRow(
                        'Denda Keterlambatan',
                        denda == 0
                            ? 'Rp 0'
                            : 'Rp ${NumberFormat('#,###', 'id_ID').format(denda)}',
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Catatan:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '• Harap mengembalikan alat sesuai dengan estimasi waktu pengembalian',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '• Keterlambatan pengembalian akan dikenakan denda',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '• Simpan kartu ini sebagai bukti peminjaman',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Print Date
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Dicetak: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Kartu_Peminjaman_$kodePeminjaman.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Divider(color: PdfColors.grey400, thickness: 0.5),
    );
  }

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
                _buttons(),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Text(
        'Kartu Peminjaman',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C5F7F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header Card dengan Logo
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF5A8AB5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Logo tanpa container wrapper
                  Image.asset(
                    'assets/images/machloanputih.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kartu Peminjaman',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
                  // Kondisional: tampilkan Kode Alat dan Jumlah hanya jika belum dikembalikan
                  if (tglKembali == null) ...[
                    _row('Kode Alat', kodeAlat),
                    _row('Jumlah', '$jumlah Unit'),
                  ],
                  _row('Tanggal Peminjaman', _fmt(tglPinjam)),
                  _row('Estimasi Pengembalian', _fmt(estimasi)),
                  if (tglKembali != null)
                    _row('Dikembalikan', _fmt(tglKembali)),
                  _row(
                    'Denda Keterlambatan',
                    denda == 0
                        ? 'Rp 0'
                        : NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(denda),
                  ),
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

  Widget _buttons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Print Button
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _printCard,
              icon: const Icon(Icons.print, size: 20),
              label: Text(
                'Print Kartu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7280),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Close Button
          SizedBox(
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
        ],
      ),
    );
  }
}