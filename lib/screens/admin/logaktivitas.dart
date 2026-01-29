import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/logaktivitas_models.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';

class LogAktivitasScreen extends StatefulWidget {
  const LogAktivitasScreen({Key? key}) : super(key: key);

  @override
  State<LogAktivitasScreen> createState() => _LogAktivitasScreenState();
}

class _LogAktivitasScreenState extends State<LogAktivitasScreen> {
  // Data Dummy Master
  final List<LogAktivitasModel> _allLogs = [
    LogAktivitasModel(
      id: '1',
      namaUser: 'Wibian Junanta',
      role: 'Petugas',
      aksi: 'Menyetujui Peminjaman',
      tanggal: '20/Jan/26',
    ),
    LogAktivitasModel(
      id: '2',
      namaUser: 'Ignatius Kurniawan',
      role: 'Peminjam',
      aksi: 'Peminjaman Alat "Alat Tangan"',
      tanggal: '20/Jan/26',
    ),
    LogAktivitasModel(
      id: '3',
      namaUser: 'Ignatius Kurniawan',
      role: 'Peminjam',
      aksi: 'Pengembalian Alat "Alat Ukur"',
      tanggal: '20/Jan/26',
    ),
  ];

  // List untuk menampung hasil filter pencarian
  List<LogAktivitasModel> _filteredLogs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredLogs = _allLogs; // Awalnya tampilkan semua data
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredLogs = _allLogs
          .where((log) =>
              log.namaUser.toLowerCase().contains(query.toLowerCase()) ||
              log.aksi.toLowerCase().contains(query.toLowerCase()))
          .toList();
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
                  Text(
                    'Log Aktivitas',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1,
                    ),
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

          const SizedBox(height: 25),

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
                  Text(
                    'Log Aktivitas',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- LIST VIEW ---
                  Expanded(
                    child: _filteredLogs.isEmpty
                        ? Center(
                            child: Text(
                              "Tidak ada aktivitas ditemukan",
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filteredLogs.length,
                            itemBuilder: (context, index) {
                              return _buildActivityCard(_filteredLogs[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          const CircleAvatar(
            backgroundColor: Color(0xFF1F4F6F),
            child: Icon(Icons.person, color: Colors.white),
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
                Text(
                  log.role,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      log.tanggal,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
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
}