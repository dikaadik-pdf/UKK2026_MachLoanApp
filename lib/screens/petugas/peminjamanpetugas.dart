import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- DATA MODEL ---
class PeminjamanModel {
  final String id, namaAlat, status, tanggalPinjaman, estimasiPengembalian;
  final String? dikembalikanPada;
  final int? denda;

  PeminjamanModel({
    required this.id,
    required this.namaAlat,
    required this.status,
    required this.tanggalPinjaman,
    required this.estimasiPengembalian,
    this.dikembalikanPada,
    this.denda,
  });
}

class PeminjamanPetugasScreen extends StatefulWidget {
  final String username;

  const PeminjamanPetugasScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<PeminjamanPetugasScreen> createState() =>
      _PeminjamanPetugasScreenState();
}

class _PeminjamanPetugasScreenState extends State<PeminjamanPetugasScreen> {
  String activeFilter = 'Menunggu';

  // Data Dummy sesuai gambar referensi petugas
  final List<PeminjamanModel> allData = [
    PeminjamanModel(
      id: '1',
      namaAlat: 'Palu Baja',
      status: 'Menunggu',
      tanggalPinjaman: '1/Jan/26',
      estimasiPengembalian: '6/Jan/26',
    ),
    PeminjamanModel(
      id: '2',
      namaAlat: 'Jangka Sorong',
      status: 'Pengembalian',
      tanggalPinjaman: '1/Jan/26',
      estimasiPengembalian: '6/Jan/26',
      dikembalikanPada: '2/Jan/26',
      denda: 0,
    ),
    PeminjamanModel(
      id: '3',
      namaAlat: 'Palu Baja',
      status: 'Ditolak',
      tanggalPinjaman: '1/Jan/26',
      estimasiPengembalian: '6/Jan/26',
    ),
    PeminjamanModel(
      id: '4',
      namaAlat: 'Jangka Sorong',
      status: 'Selesai',
      tanggalPinjaman: '1/Jan/26',
      estimasiPengembalian: '6/Jan/26',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<PeminjamanModel> filteredList = allData
        .where((item) => item.status == activeFilter)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          // --- HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF769DCB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 5),
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
          ),

          const SizedBox(height: 15),

          // --- FILTER BAR (SCROLLABLE) ---
          _buildScrollableFilter(),

          const SizedBox(height: 10),

          // --- INFO DENDA (Hanya di tab Pengembalian) ---
          if (activeFilter == 'Pengembalian') _buildInfoDenda(),

          // --- LIST CONTENT ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              itemCount: filteredList.length,
              itemBuilder: (context, index) => _buildLoanCard(filteredList[index]),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Filter yang bisa digeser
  Widget _buildScrollableFilter() {
    List<String> filters = ['Menunggu', 'Pengembalian', 'Ditolak', 'Selesai'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: filters.map((filter) {
            bool isSelected = activeFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => activeFilter = filter),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF769DCB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Widget Kartu Peminjaman
  Widget _buildLoanCard(PeminjamanModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F), // Background biru tua utama
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Detail Informasi (Bagian Biru Tua)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.namaAlat,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                _buildStatusBadge(data),
                const SizedBox(height: 12),
                _buildTextRow('Tanggal Peminjaman', ': ${data.tanggalPinjaman}'),
                _buildTextRow('Estimasi Pengembalian', ': ${data.estimasiPengembalian}'),
                if (data.dikembalikanPada != null)
                  _buildTextRow('Dikembalikan Pada', ': ${data.dikembalikanPada}'),
              ],
            ),
          ),

          // Tombol Aksi (Hanya muncul di Tab Menunggu)
          if (activeFilter == 'Menunggu')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF769DCB), // Area biru muda bawah
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _actionButton('Setujui', const Color(0xFF8DC33E))),
                  const SizedBox(width: 15),
                  Expanded(child: _actionButton('Tolak', const Color(0xFFE52510))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Tombol Setujui/Tolak yang sudah dirapikan ukurannya
  Widget _actionButton(String label, Color color) {
    return Container(
      height: 35, // Tinggi tombol lebih ramping
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Badge Status
  Widget _buildStatusBadge(PeminjamanModel data) {
    if (data.status == 'Pengembalian') {
      return Row(
        children: [
          _badge('Disetujui', const Color(0xFF8DC33E)),
          const SizedBox(width: 8),
          _badge('Denda: ${data.denda}', const Color(0xFFE52510)),
        ],
      );
    }
    String text = data.status == 'Selesai' ? 'Dikembalikan' : data.status;
    Color color = data.status == 'Ditolak' ? const Color(0xFFE52510) : const Color(0xFF769DCB);
    return _badge(text, color);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDenda() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE52510),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Informasi Pengembalian\nSetiap keterlambatan pengembalian maka dikenakan denda sebesar 5000/Hari',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}