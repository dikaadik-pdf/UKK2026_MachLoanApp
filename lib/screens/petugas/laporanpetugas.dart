import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPetugasPage extends StatefulWidget {
  final String username;

  const LaporanPetugasPage({super.key, required this.username});

  @override
  State<LaporanPetugasPage> createState() => _LaporanPetugasPageState();
}

class _LaporanPetugasPageState extends State<LaporanPetugasPage> {
  String selectedFilter = 'Semua';
  bool isLoading = true;
  List<Map<String, dynamic>> laporanData = [];
  int totalAlat = 0;
  int totalPeminjam = 0;
  bool _localeInitialized = false;
  RealtimeChannel? _realtimeChannel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadLaporan();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      SupabaseServices.unsubscribeChannel(_realtimeChannel!);
    }
    _searchController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = SupabaseServices.subscribeToLaporan(() {
      if (mounted) {
        _loadLaporan();
      }
    });
  }

  Future<void> _initializeLocale() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('id_ID', null);
      _localeInitialized = true;
    }
  }

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
        case 'Bulan Ini':
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

      // Hitung jumlah peminjam unik
      final uniquePeminjam = <String>{};
      for (var item in data) {
        final username = item['users']?['username'];
        if (username != null) {
          uniquePeminjam.add(username);
        }
      }

      if (!mounted) return;

      // Sort descending
      data.sort((a, b) {
        final dateA = _parseDate(a['tanggal_pinjam']);
        final dateB = _parseDate(b['tanggal_pinjam']);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      setState(() {
        laporanData = data;
        totalAlat = total;
        totalPeminjam = uniquePeminjam.length;
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

      // Load logo dari asset
      final logoImage = await rootBundle.load('assets/images/mechloan.png');
      final logoBytes = logoImage.buffer.asUint8List();

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
                  // Logo dan Judul
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(
                        pw.MemoryImage(logoBytes),
                        width: 60,
                        height: 60,
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'LAPORAN : PEMINJAMAN ALAT',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'MACHLOAN : PART OF SMKS BRANTAS KARANGKATES',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
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

            // Statistik
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Alat Dipinjam:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$totalAlat',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Alat',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Peminjam:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$totalPeminjam',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Peminjam',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Detail Peminjaman',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            // Table
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
      case 'Bulan Ini':
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
                        'Laporan Petugas',
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
                        color: const Color(0xFF769DCB),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Cari Alat Disini!',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF769DCB),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 22,
                          color: const Color(0xFF769DCB),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
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
                        _buildFilterChip('Semua', 'Semua'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Hari Ini', 'Hari Ini'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Minggu Ini', 'Minggu Ini'),
                        const SizedBox(width: 12),
                        _buildFilterChip('Bulan Ini', 'Bulan Ini'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Statistik Cards - 2 Cards dengan H150 dan text center
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                // Card Total Alat Dipinjam
                Expanded(
                  child: Container(
                    height: 225,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEBFF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Alat Dipinjam:',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF769DCB),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 45),
                        isLoading
                            ? const SizedBox(
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalAlat',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF769DCB),
                                      fontSize: 70,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 23),
                                  Text(
                                    'Alat',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF769DCB),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // Card Total Peminjam
                Expanded(
                  child: Container(
                    height: 225,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEBFF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Peminjam:',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF769DCB),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 45),
                        isLoading
                            ? const SizedBox(
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFF769DCB),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalPeminjam',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF769DCB),
                                      fontSize: 70,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 23),
                                  Text(
                                    'Peminjam',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF769DCB),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Detail Peminjaman Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Peminjaman',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F4F6F),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Data list
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: Color(0xFFDBEBFF),
                        ),
                      ),
                    )
                  else if (laporanData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data peminjaman',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
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

          const SizedBox(height: 20),

          // Print Button - Tidak Menempel
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
            child: Container(
              width: double.infinity,
              height: 60,
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
                icon: Icon(
                  Icons.print,
                  color: isLoading ? Colors.grey[400] : Colors.white,
                  size: 30,
                ),
                label: Text(
                  "Print",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isLoading ? Colors.grey[400] : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3A40),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterValue, String label) {
    final isSelected = selectedFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = filterValue);
        _loadLaporan();
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

  Widget _buildToolItem(String name, String dateOut, String dateIn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEBFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              color: const Color(0xFF769DCB),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tanggal Dipinjam: $dateOut',
                style: GoogleFonts.poppins(color: const Color(0xFF769DCB), fontSize: 10),
              ),
              Text(
                'Estimasi Kembali: $dateIn',
                style: GoogleFonts.poppins(color: const Color(0xFF769DCB), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}