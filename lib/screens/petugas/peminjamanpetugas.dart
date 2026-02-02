import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  String activeFilter = 'menunggu';
  List<Map<String, dynamic>> _peminjamanList = [];
  bool _loading = true;
  RealtimeChannel? _peminjamanChannel;
  String? _idPetugas;

  final DateFormat dateFormatter = DateFormat('d/MMM/yy');

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    if (_peminjamanChannel != null) {
      SupabaseServices.unsubscribeChannel(_peminjamanChannel!);
    }
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Get ID petugas
      _idPetugas = await SupabaseServices.getUserIdByUsername(widget.username);
      
      // Load data
      await _loadPeminjaman();
      
      // Setup realtime
      _setupRealtimeSubscription();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _setupRealtimeSubscription() {
    _peminjamanChannel = SupabaseServices.subscribeToPeminjamanByStatus(
      activeFilter,
      (data) {
        if (!mounted) return;
        setState(() {
          _peminjamanList = data;
          _loading = false;
        });
      },
    );
  }

  Future<void> _loadPeminjaman() async {
    try {
      setState(() => _loading = true);
      final data = await SupabaseServices.getPeminjamanByStatus(activeFilter);
      if (!mounted) return;
      setState(() {
        _peminjamanList = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateStatus(int idPeminjaman, String newStatus, int idAlat, int jumlah) async {
    try {
      await SupabaseServices.updateStatusPeminjaman(
        idPeminjaman: idPeminjaman,
        newStatus: newStatus,
        idPetugas: _idPetugas!,
        stokDikurangi: newStatus == 'disetujui' ? jumlah : null,
        idAlat: newStatus == 'disetujui' ? idAlat : null,
      );

      if (!mounted) return;

      final message = newStatus == 'disetujui' 
          ? 'Peminjaman berhasil disetujui' 
          : 'Peminjaman ditolak';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data
      await _loadPeminjaman();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeFilter(String newFilter) {
    if (activeFilter == newFilter) return;
    
    // Unsubscribe channel lama
    if (_peminjamanChannel != null) {
      SupabaseServices.unsubscribeChannel(_peminjamanChannel!);
    }

    setState(() {
      activeFilter = newFilter;
    });

    // Load data baru dan setup realtime baru
    _loadPeminjaman();
    _setupRealtimeSubscription();
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

          // --- FILTER BAR ---
          _buildScrollableFilter(),

          const SizedBox(height: 10),

          // --- INFO DENDA ---
          if (activeFilter == 'disetujui') _buildInfoDenda(),

          // --- LIST CONTENT ---
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1F4F6F),
                    ),
                  )
                : _peminjamanList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data peminjaman',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        itemCount: _peminjamanList.length,
                        itemBuilder: (context, index) => _buildLoanCard(_peminjamanList[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableFilter() {
    List<Map<String, String>> filters = [
      {'value': 'menunggu', 'label': 'Menunggu'},
      {'value': 'disetujui', 'label': 'Disetujui'},
      {'value': 'ditolak', 'label': 'Ditolak'},
      {'value': 'dikembalikan', 'label': 'Selesai'},
    ];

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
            bool isSelected = activeFilter == filter['value'];
            return GestureDetector(
              onTap: () => _changeFilter(filter['value']!),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF769DCB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter['label']!,
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

  Widget _buildLoanCard(Map<String, dynamic> data) {
    // Parse data
    final String kodePeminjaman = data['kode_peminjaman'];
    final String username = data['users']['username'];
    final String status = data['status'];
    
    // Get detail peminjaman (ambil yang pertama)
    final detailList = data['detail_peminjaman'] as List;
    if (detailList.isEmpty) return const SizedBox.shrink();
    
    final detail = detailList[0];
    final String namaAlat = detail['alat']['nama_alat'];
    final int jumlah = detail['jumlah'];
    final int idAlat = detail['alat']['id_alat'] ?? 0;
    final int dendaPerHari = detail['alat']['denda_per_hari'] ?? 5000;
    
    // Parse tanggal
    final DateTime tanggalPinjam = DateTime.parse(data['tanggal_pinjam']);
    final DateTime estimasiKembali = DateTime.parse(data['estimasi_kembali']);
    
    // Data pengembalian (jika ada)
    String? dikembalikanPada;
    int? totalDenda;
    if (data['pengembalian'] != null && (data['pengembalian'] as List).isNotEmpty) {
      final pengembalian = (data['pengembalian'] as List)[0];
      dikembalikanPada = dateFormatter.format(DateTime.parse(pengembalian['tanggal_pengembalian']));
      totalDenda = pengembalian['total_denda'];
    }

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
          // Detail Informasi
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaAlat,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                _buildStatusBadge(status, totalDenda),
                const SizedBox(height: 12),
                _buildTextRow('Kode Peminjaman', ': $kodePeminjaman'),
                _buildTextRow('Peminjam', ': $username'),
                _buildTextRow('Jumlah', ': $jumlah unit'),
                _buildTextRow('Tanggal Peminjaman', ': ${dateFormatter.format(tanggalPinjam)}'),
                _buildTextRow('Estimasi Pengembalian', ': ${dateFormatter.format(estimasiKembali)}'),
                if (dikembalikanPada != null)
                  _buildTextRow('Dikembalikan Pada', ': $dikembalikanPada'),
                _buildTextRow('Denda/Hari', ': Rp ${dendaPerHari.toString()}'),
              ],
            ),
          ),

          // Tombol Aksi (Hanya di Tab Menunggu)
          if (activeFilter == 'menunggu')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF769DCB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      'Setujui',
                      const Color(0xFF8DC33E),
                      () => _showConfirmDialog(
                        'Setujui Peminjaman?',
                        'Yakin ingin menyetujui peminjaman ini?',
                        () => _updateStatus(
                          data['id_peminjaman'],
                          'disetujui',
                          idAlat,
                          jumlah,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _actionButton(
                      'Tolak',
                      const Color(0xFFE52510),
                      () => _showConfirmDialog(
                        'Tolak Peminjaman?',
                        'Yakin ingin menolak peminjaman ini?',
                        () => _updateStatus(
                          data['id_peminjaman'],
                          'ditolak',
                          idAlat,
                          jumlah,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 35,
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
      ),
    );
  }

  Widget _buildStatusBadge(String status, int? totalDenda) {
    if (status == 'disetujui') {
      return Row(
        children: [
          _badge('Disetujui', const Color(0xFF8DC33E)),
          if (totalDenda != null && totalDenda > 0) ...[
            const SizedBox(width: 8),
            _badge('Denda: Rp $totalDenda', const Color(0xFFE52510)),
          ],
        ],
      );
    }
    
    String text;
    Color color;
    
    switch (status) {
      case 'menunggu':
        text = 'Menunggu';
        color = const Color(0xFF757B8C);
        break;
      case 'ditolak':
        text = 'Ditolak';
        color = const Color(0xFFE52510);
        break;
      case 'dikembalikan':
        text = 'Dikembalikan';
        color = const Color(0xFF769DCB);
        break;
      default:
        text = status;
        color = const Color(0xFF769DCB);
    }
    
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
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
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

  Future<void> _showConfirmDialog(String title, String message, VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F4F6F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF769DCB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Ya',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}