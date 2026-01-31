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
          _buildHeader(),

          const SizedBox(height: 15),

          // --- FILTER BAR ---
          _buildScrollableFilter(),

          const SizedBox(height: 10),

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

  Widget _buildHeader() {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Peminjaman',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Icon(Icons.person, color: Colors.white, size: 35),
        ],
      ),
    );
  }

  Widget _buildScrollableFilter() {
    List<String> filters = ['Menunggu', 'Pengembalian', 'Ditolak', 'Selesai'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((filter) {
          bool isSelected = activeFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => activeFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF769DCB) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoanCard(PeminjamanModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.namaAlat,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
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

          // --- MODIFIKASI: INNER CONTAINER & BUTTON KEMBALIKAN ---
          if (activeFilter == 'Pengembalian')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF769DCB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8DC33E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Kembalikan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PeminjamanModel data) {
    if (data.status == 'Pengembalian') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE52510),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Denda: ${data.denda}',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    }
    
    String text = data.status == 'Selesai' ? 'Dikembalikan' : data.status;
    Color color = data.status == 'Ditolak' ? const Color(0xFFE52510) : const Color(0xFF769DCB);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
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
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Pengembalian',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Setiap keterlambatan pengembalian maka dikenakan denda sebesar 5000/Hari',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}