import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';

class PeminjamanPetugasScreen extends StatefulWidget {
  final String username;

  const PeminjamanPetugasScreen({Key? key, required this.username})
      : super(key: key);

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
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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

  Future<void> _updateStatus(
    int idPeminjaman,
    String newStatus,
    int idAlat,
    int jumlah,
  ) async {
    try {
      await SupabaseServices.updateStatusPeminjaman(
        idPeminjaman: idPeminjaman,
        newStatus: newStatus,
        idPetugas: _idPetugas!,
        stokDikurangi: newStatus == 'disetujui' ? jumlah : null,
        idAlat: newStatus == 'disetujui' ? idAlat : null,
      );

      if (!mounted) return;

      // Show success dialog
      final message = newStatus == 'disetujui'
          ? 'Peminjaman berhasil disetujui!'
          : 'Peminjaman telah ditolak!';

      final title = newStatus == 'disetujui' ? 'Berhasil!' : 'Ditolak!';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(
          title: title,
          subtitle: message,
          onOk: () {
            Navigator.pop(context);
            _loadPeminjaman();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => SuccessDialog(
          title: 'Gagal!',
          subtitle: 'Gagal update status: $e',
          onOk: () => Navigator.pop(context),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day}/${months[date.month - 1]}/${date.year.toString().substring(2)}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
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
                        'Peminjaman',
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
                        color: const Color(0xFF1F4F6F),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Cari Alat Disini!',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF1F4F6F).withOpacity(0.5),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 22,
                          color: const Color(0xFF1F4F6F).withOpacity(0.7),
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
                        _buildFilterChip('menunggu', 'Menunggu'),
                        const SizedBox(width: 12),
                        _buildFilterChip('disetujui', 'Disetujui'),
                        const SizedBox(width: 12),
                        _buildFilterChip('ditolak', 'Ditolak'),
                        const SizedBox(width: 12),
                        _buildFilterChip('dikembalikan', 'Selesai'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Informasi untuk status menunggu
          if (activeFilter == 'menunggu') _buildInfoPending(),

          // Informasi untuk status disetujui
          if (activeFilter == 'disetujui') _buildInfoDisetujui(),

          // List Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _peminjamanList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPeminjaman,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 10,
                          ),
                          itemCount: _peminjamanList.length,
                          itemBuilder: (context, index) =>
                              _buildLoanCard(_peminjamanList[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterValue, String label) {
    final isSelected = activeFilter == filterValue;
    return GestureDetector(
      onTap: () => _changeFilter(filterValue),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data peminjaman',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${_getStatusDisplay(activeFilter)}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'dikembalikan':
        return 'Selesai';
      default:
        return status;
    }
  }

  Widget _buildInfoPending() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE52510),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Perhatian!\nSegera proses peminjaman yang masuk untuk memberikan persetujuan atau penolakan',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDisetujui() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE52510),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Informasi Pengembalian\nSelalu Ingatkan Peminjam Untuk Mengembalikan Alat Tepat Waktu Ya!',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> data) {
    // Parse data
    final detailList = data['detail_peminjaman'] as List;
    if (detailList.isEmpty) return const SizedBox.shrink();

    final detail = detailList[0];
    final String namaAlat = detail['alat']['nama_alat'];
    final int jumlah = detail['jumlah'];
    final int idAlat = detail['alat']['id_alat'] ?? 0;
    final int dendaPerHari = detail['alat']['denda_per_hari'] ?? 0;

    final String kodePeminjaman = data['kode_peminjaman'] ?? '-';
    final String username = data['users']['username'] ?? 'Unknown';
    final String status = data['status'] as String;

    // Data pengembalian (jika ada)
    final pengembalianList = data['pengembalian'] as List?;
    final pengembalian = (pengembalianList != null && pengembalianList.isNotEmpty)
        ? pengembalianList.first
        : null;
    final terlambat = pengembalian?['terlambat'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF769DCB),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content utama
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
                Text(
                  'Kode: $kodePeminjaman',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        username,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextRow('Jumlah', ': $jumlah unit'),
                _buildTextRow(
                  'Tanggal Peminjaman',
                  ': ${_formatDate(data['tanggal_pinjam'])}',
                ),
                _buildTextRow(
                  'Estimasi Pengembalian',
                  ': ${_formatDate(data['estimasi_kembali'])}',
                ),
                if (terlambat > 0)
                  _buildTextRow('Keterlambatan', ': $terlambat hari'),
                if (dendaPerHari > 0)
                  _buildTextRow(
                    'Denda/Hari',
                    ': Rp ${_formatCurrency(dendaPerHari)}',
                  ),
              ],
            ),
          ),

          // Inner child section berdasarkan status
          _buildInnerChild(data, status, idAlat, jumlah),
        ],
      ),
    );
  }

  Widget _buildInnerChild(
    Map<String, dynamic> data,
    String status,
    int idAlat,
    int jumlah,
  ) {
    if (status == 'menunggu') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () => _showConfirmDialog(
                    'Eh...?',
                    'Kamu Yakin Ingin Menyetujui Peminjaman Ini?',
                    () => _updateStatus(
                      data['id_peminjaman'],
                      'disetujui',
                      idAlat,
                      jumlah,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8DC33E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Setujui',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () => _showConfirmDialog(
                    'Hmm...?',
                    'Kamu Yakin Ingin Menolak Peminjaman Ini?',
                    () => _updateStatus(
                      data['id_peminjaman'],
                      'ditolak',
                      idAlat,
                      jumlah,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE52510),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Tolak',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'disetujui') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8DC33E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Disetujui',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else if (status == 'ditolak') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFCE0000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ditolak',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else if (status == 'dikembalikan') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFDBEBFF),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8BB501),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Dikembalikan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Future<void> _showConfirmDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title,
          subtitle: message,
          onBack: () => Navigator.pop(context),
          onContinue: () {
            Navigator.pop(context);
            onConfirm();
          },
        );
      },
    );
  }
}