import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/logaktivitas_models.dart';
import 'package:ukk2026_machloanapp/services/logaktivitas_services.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final logs = await _logService.getAllLogs();
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
            .where((log) =>
                log.namaUser.toLowerCase().contains(query.toLowerCase()) ||
                log.aksi.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          // --- HEADER ---
          Container(
            width: double.infinity,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF769DCB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Log Aktivitas',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                    onPressed: _loadLogs,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Cari Aktivitas Disini!',
              onChanged: _filterSearch,
            ),
          ),

          const SizedBox(height: 20),

          // --- MAIN CONTAINER ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(25, 0, 25, 30),
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
                  Expanded(
                    child: _buildLogList(),
                  ),
                ],
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
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
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
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
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
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Batasi maksimal 5 aktivitas terbaru
    final logsToDisplay = _filteredLogs.take(5).toList();

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: logsToDisplay.length,
      itemBuilder: (context, index) {
        return _buildActivityCard(logsToDisplay[index]);
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
            child: Icon(
              _getRoleIcon(log.role),
              color: Colors.white,
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        log.aksi,
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
                          log.waktuAktivitas.minute.toString().padLeft(2, '0'),
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