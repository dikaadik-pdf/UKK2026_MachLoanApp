import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPage extends StatefulWidget {
  final String username;

  const LaporanPage({
    super.key,
    required this.username,
  });

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String selectedFilter = 'Semua';
  bool isLoading = true;
  List<Map<String, dynamic>> laporanData = [];
  int totalAlat = 0;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadLaporan();
  }

  Future<void> _initializeLocale() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('id_ID', null);
      _localeInitialized = true;
    }
  }

  /// Parse tanggal dari string — handles both DATE (yyyy-MM-dd) dan TIMESTAMP (yyyy-MM-ddTHH:mm:ss)
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLaporan() async {
    setState(() => isLoading = true);

    try {
      DateTime? startDate;
      DateTime? endDate = DateTime.now();

      switch (selectedFilter) {
        case 'Hari Ini':
          startDate = DateTime.now();
          break;
        case 'Minggu Ini':
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'Sebulan Ini':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'Semua':
        default:
          startDate = null;
          endDate = null;
      }

      final data = await SupabaseServices.getLaporanPeminjaman(
        startDate: startDate,
        endDate: endDate,
      );

      final total = await SupabaseServices.getTotalAlatDipinjam(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      // ✅ Sort di sini — tanggal_pinjam terbaru di atas (descending)
      data.sort((a, b) {
        final dateA = _parseDate(a['tanggal_pinjam']);
        final dateB = _parseDate(b['tanggal_pinjam']);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;   // null taruh di bawah
        if (dateB == null) return -1;
        return dateB.compareTo(dateA); // descending = terbaru di atas
      });

      setState(() {
        laporanData = data;
        totalAlat = total;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      showDialog(
        context: context,
        builder: (_) => SuccessDialog(
          title: 'Hmm..!',
          subtitle: 'Sebentar, Sepertinya Ada Kesalahan Sistem',
          onOk: () => Navigator.pop(context),
        ),
      );
    }
  }

  Future<void> _printLaporan() async {
    try {
      await _initializeLocale();

      final pdf = pw.Document();

      final now = DateTime.now();
      final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
      final filterText = _getFilterText();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LAPORAN PEMINJAMAN ALAT',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'SMKS BRANTAS KARANGKATES',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Tanggal Cetak: ${dateFormat.format(now)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Filter: $filterText',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Total
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Alat Dipinjam:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$totalAlat Item',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Detail Peminjaman',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Table — laporanData sudah di-sort descending
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('No', isHeader: true),
                    _buildTableCell('Nama Alat', isHeader: true),
                    _buildTableCell('Kode Alat', isHeader: true),
                    _buildTableCell('Tgl Pinjam', isHeader: true),
                    _buildTableCell('Est. Kembali', isHeader: true),
                    _buildTableCell('Jumlah', isHeader: true),
                  ],
                ),
                // Data Rows
                ...laporanData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final detailList = item['detail_peminjaman'] as List;
                  final detail = detailList.isNotEmpty ? detailList.first : null;
                  final alat = detail?['alat'];

                  return pw.TableRow(
                    children: [
                      _buildTableCell('${index + 1}'),
                      _buildTableCell(alat?['nama_alat'] ?? '-'),
                      _buildTableCell(alat?['kode_alat'] ?? '-'),
                      _buildTableCell(_formatDate(item['tanggal_pinjam'])),
                      _buildTableCell(_formatDate(item['estimasi_kembali'])),
                      _buildTableCell('${detail?['jumlah'] ?? 0}'),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Laporan_Peminjaman_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => SuccessDialog(
          title: 'Error!',
          subtitle: 'Gagal mencetak laporan: $e',
          onOk: () => Navigator.pop(context),
        ),
      );
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d/MM/yy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getFilterText() {
    switch (selectedFilter) {
      case 'Hari Ini':
        return 'Data Hari Ini';
      case 'Minggu Ini':
        return 'Data 7 Hari Terakhir';
      case 'Sebulan Ini':
        return 'Data 30 Hari Terakhir';
      case 'Semua':
      default:
        return 'Semua Data';
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
            height: 125,
            decoration: const BoxDecoration(
              color: Color(0xFF769DCB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 45, 20, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Laporan',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F4F6F),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterButton('Semua'),
                          _buildFilterButton('Hari Ini'),
                          _buildFilterButton('Minggu Ini'),
                          _buildFilterButton('Sebulan Ini'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _printLaporan,
                      icon: const Icon(Icons.print,
                          color: Colors.white, size: 30),
                      label: Text(
                        "Print",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF333333),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- TOTAL CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F4F6F),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Alat Dipinjam:",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                "$totalAlat Item",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Detail Peminjaman",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F4F6F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Data list — sudah di-sort descending dari _loadLaporan
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1F4F6F),
                      ),
                    )
                  else if (laporanData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Tidak ada data peminjaman',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1F4F6F),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ...laporanData.map((item) {
                      final detailList = item['detail_peminjaman'] as List;
                      final detail =
                          detailList.isNotEmpty ? detailList.first : null;
                      final alat = detail?['alat'];

                      return _buildToolItem(
                        alat?['nama_alat'] ?? 'Unknown',
                        _formatDate(item['tanggal_pinjam']),
                        _formatDate(item['estimasi_kembali']),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title) {
    bool isSelected = selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = title);
        _loadLaporan();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF769DCB) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildToolItem(String name, String dateOut, String dateIn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tanggal Dipinjam : $dateOut",
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 10)),
              Text("Estimasi Kembali: $dateIn",
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}