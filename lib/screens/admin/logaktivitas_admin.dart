import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ukk2026_machloanapp/models/logaktivitas_models.dart';
import 'package:ukk2026_machloanapp/services/logaktivitas_services.dart';
import 'package:ukk2026_machloanapp/widgets/filter_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
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

      // Data yang akan di-print (gunakan _allLogs, bukan _filteredLogs agar tidak terpengaruh search)
      final dataToPrint = _allLogs;

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
                    'LAPORAN LOG AKTIVITAS',
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
      body: Column(
        children: [
          // --- HEADER YANG LEBIH TINGGI (180) ---
          Container(
            width: double.infinity,
            height: 190,
            decoration: const BoxDecoration(
              color: Color(0xFF769DCB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar: Back button + Title + Refresh
                  Row(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log Aktivitas',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: _loadLogs,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),

                  // Search Bar di dalam AppBar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F4F6F),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterSearch,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari Aktivitas Disini!',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- FILTER BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomFilterBar(
              filters: const [
                'Semua',
                'Hari Ini',
                'Minggu Ini',
                'Sebulan Ini',
              ],
              initialFilter: selectedFilter,
              onFilterSelected: (filter) {
                setState(() => selectedFilter = filter);
                _loadLogs();
              },
            ),
          ),

          const SizedBox(height: 20),

          // --- MAIN CONTAINER ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1F4F6F),
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
                        color: Colors.white,
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
                  size: 24,
                ),
                label: Text(
                  "Print",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
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
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLogs,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF769DCB),
                foregroundColor: Colors.white,
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
            const Icon(Icons.inbox_outlined, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? "Tidak ada aktivitas ditemukan"
                  : "Belum ada aktivitas",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Tampilkan semua data yang sudah difilter
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
        color: const Color(0xFF769DCB),
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
            backgroundColor: const Color(0xFF1F4F6F),
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
                    color: Colors.white,
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
                          color: Colors.white,
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
                            color: Colors.white70,
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
                            color: Colors.white60,
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