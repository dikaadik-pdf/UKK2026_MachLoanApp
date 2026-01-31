import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/peminjaman_models.dart';

class PeminjamanScreen extends StatefulWidget {
  const PeminjamanScreen({Key? key}) : super(key: key);

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Peminjaman',
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

          const SizedBox(height: 15),

          // --- FILTER BAR ---
          CustomFilterBar(
            filters: const ['Menunggu', 'Pengembalian', 'Ditolak', 'Selesai'],
            initialFilter: activeFilter,
            onFilterSelected: (val) {
              setState(() => activeFilter = val);
            },
          ),

          const SizedBox(height: 15),

          // Informasi Denda
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

  Widget _buildInfoDenda() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
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

  Widget _buildLoanCard(PeminjamanModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
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
      child: Stack(
        children: [
          Column(
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
              const SizedBox(height: 10),
              _buildTextRow('Tanggal Peminjaman', ': ${data.tanggalPinjaman}'),
              _buildTextRow('Estimasi Pengembalian', ': ${data.estimasiPengembalian}'),
              if (data.dikembalikanPada != null)
                _buildTextRow('Dikembalikan Pada', ': ${data.dikembalikanPada}'),
            ],
          ),
          if (data.status == 'Selesai')
            const Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.delete, color: Colors.white70, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PeminjamanModel data) {
    if (data.status == 'Pengembalian') {
      return Row(
        children: [
          _badge('Disetujui', Colors.green),
          const SizedBox(width: 10),
          _badge('Denda: ${data.denda}', Colors.red),
        ],
      );
    }
    String text = data.status == 'Selesai' ? 'Dikembalikan' : data.status;
    Color color = data.status == 'Ditolak' ? Colors.red : const Color(0xFF769DCB);
    return _badge(text, color);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 130,
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
    );
  }
}

class CustomFilterBar extends StatelessWidget {
  final List<String> filters;
  final Function(String) onFilterSelected;
  final String initialFilter;

  const CustomFilterBar({
    Key? key,
    required this.filters,
    required this.onFilterSelected,
    required this.initialFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: filters.map((filter) {
          bool isSelected = filter == initialFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterSelected(filter),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF769DCB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}