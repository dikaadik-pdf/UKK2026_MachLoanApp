import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ukk2026_machloanapp/models/logaktivitas_models.dart';
import 'package:ukk2026_machloanapp/services/logaktivitas_services.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/appbar_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LogAktivitasScreen extends StatefulWidget {
  const LogAktivitasScreen({Key? key}) : super(key: key);

  @override
  State<LogAktivitasScreen> createState() => _LogAktivitasScreenState();
}

class _LogAktivitasScreenState extends State<LogAktivitasScreen> {
  final LogAktivitasService _logService = LogAktivitasService();
  final TextEditingController _searchController = TextEditingController();

  List<LogAktivitasModel> _allLogs = [];
  List<LogAktivitasModel> _filteredLogs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String selectedFilter = 'Semua';
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('id_ID', null);
      _localeInitialized = true;
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

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

      final logs = await _logService.getLogsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _allLogs = logs;
        _filteredLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLogs = _allLogs;
      } else {
        _filteredLogs = _allLogs
            .where(
              (log) =>
                  log.namaUser.toLowerCase().contains(query.toLowerCase()) ||
                  log.aktivitas.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _printLogAktivitas() async {
    try {
      await _initializeLocale();

      final pdf = pw.Document();

      final now = DateTime.now();
      final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
      final filterText = _getFilterText();

      // Load logo dari assets
      final logoImage = await rootBundle.load('assets/images/mechloan.png');
      final logoBytes = logoImage.buffer.asUint8List();
      final logo = pw.MemoryImage(logoBytes);

      // Data yang akan di-print (gunakan _allLogs, bukan _filteredLogs agar tidak terpengaruh search)
      final dataToPrint = _allLogs;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header dengan Logo
            pw.Header(
              level: 0,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo
                  pw.Image(
                    logo,
                    width: 60,
                    height: 60,
                  ),
                  pw.SizedBox(width: 16),
                  // Informasi Header
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LAPORAN LOG AKTIVITAS',
                          style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'MACHLOAN : PART OF SMKS BRANTAS KARANGKATES',
                          style: const pw.TextStyle(fontSize: 12),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Divider(thickness: 2),

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
                    'Total Aktivitas:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${dataToPrint.length} Aktivitas',
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
              'Detail Log Aktivitas',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            // Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('No', isHeader: true),
                    _buildTableCell('Nama User', isHeader: true),
                    _buildTableCell('Role', isHeader: true),
                    _buildTableCell('Aktivitas', isHeader: true),
                    _buildTableCell('Tanggal', isHeader: true),
                    _buildTableCell('Waktu', isHeader: true),
                  ],
                ),
                // Data Rows
                ...dataToPrint.asMap().entries.map((entry) {
                  final index = entry.key;
                  final log = entry.value;

                  return pw.TableRow(
                    children: [
                      _buildTableCell('${index + 1}'),
                      _buildTableCell(log.namaUser),
                      _buildTableCell(log.roleFormatted),
                      _buildTableCell(log.aktivitas, textAlign: pw.TextAlign.left),
                      _buildTableCell(log.tanggal),
                      _buildTableCell(
                        '${log.waktuAktivitas.hour.toString().padLeft(2, '0')}:${log.waktuAktivitas.minute.toString().padLeft(2, '0')}',
                      ),
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
        name: 'Log_Aktivitas_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => SuccessDialog(
          title: 'Error!',
          subtitle: 'Gagal mencetak log aktivitas: $e',
          onOk: () => Navigator.pop(context),
        ),
      );
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign? textAlign}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: textAlign ?? pw.TextAlign.center,
      ),
    );
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
      appBar: CustomAppBarWithSearch(
        title: 'Log Aktivitas',
        searchController: _searchController,
        searchHintText: 'Cari Aktivitas Disini!',
        onSearchChanged: _filterSearch,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // --- SCROLLABLE FILTER BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        'Semua',
                        'Hari Ini',
                        'Minggu Ini',
                        'Sebulan Ini',
                      ].map((filter) {
                        final isSelected = filter == selectedFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selectedFilter = filter);
                              _loadLogs();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF769DCB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                filter,
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF333333),
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- MAIN CONTAINER (LANGSUNG TANPA WRAPPER) ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF769DCB),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  // Title - Centered
                  Center(
                    child: Text(
                      'Log Aktivitas',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDBEBFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- LIST VIEW ---
                  Expanded(child: _buildLogList()),
                ],
              ),
            ),
          ),

          // --- PRINT BUTTON DI BAWAH ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
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
                onPressed: _isLoading ? null : _printLogAktivitas,
                icon: const Icon(
                  Icons.print,
                  color: Colors.white,
                  size: 30,
                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDBEBFF)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDBEBFF), size: 48),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: GoogleFonts.poppins(
                color: const Color(0xFFDBEBFF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFFDBEBFF).withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLogs,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDBEBFF),
                foregroundColor: const Color(0xFF769DCB),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, color: Color(0xFFDBEBFF), size: 48),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? "Tidak ada aktivitas ditemukan"
                  : "Belum ada aktivitas",
              style: GoogleFonts.poppins(
                color: const Color(0xFFDBEBFF).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        return _buildActivityCard(_filteredLogs[index]);
      },
    );
  }

  Widget _buildActivityCard(LogAktivitasModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEBFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF769DCB),
            child: Icon(_getRoleIcon(log.role), color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.namaUser,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF769DCB),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(log.role),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    log.roleFormatted,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        log.aktivitas,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF769DCB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          log.tanggal,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF769DCB).withOpacity(0.7),
                          ),
                        ),
                        Text(
                          log.waktuAktivitas.hour.toString().padLeft(2, '0') +
                              ':' +
                              log.waktuAktivitas.minute.toString().padLeft(
                                2,
                                '0',
                              ),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: const Color(0xFF769DCB).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'petugas':
        return Icons.support_agent;
      case 'peminjam':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red.shade700;
      case 'petugas':
        return Colors.blue.shade700;
      case 'peminjam':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}