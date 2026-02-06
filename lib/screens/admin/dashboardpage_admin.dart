import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'alat_screen_admin.dart';
import 'peminjaman_admin.dart';
import 'logaktivitas_admin.dart';
import 'memberscreen_admin.dart';
import '../logoutpage.dart';
import '../../services/supabase_services.dart';

class DashboardScreenAdmin extends StatefulWidget {
  final String username;
  const DashboardScreenAdmin({super.key, required this.username});

  @override
  State<DashboardScreenAdmin> createState() => _DashboardScreenAdminState();
}

class _DashboardScreenAdminState extends State<DashboardScreenAdmin> {
  int totalAlat = 0;
  int alatTersedia = 0;
  int alatDipinjam = 0;
  List<Map<String, dynamic>> weeklyData = [];
  bool isLoading = true;
  bool isMenuOpen = false;

  final Color primaryAppbar = const Color(0xFF769DCB);
  final Color containerColor = const Color(0xFFDBEBFF);
  final Color textBlue = const Color(0xFF769DCB);
  final Color backgroundGrey = const Color(0xFFDDDDDD);
  final Color greyInnerChart = const Color(0xFF6B7280);

  RealtimeChannel? _alatChannel;
  RealtimeChannel? _peminjamanChannel;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_alatChannel != null) SupabaseServices.unsubscribeChannel(_alatChannel!);
    if (_peminjamanChannel != null) {
      SupabaseServices.unsubscribeChannel(_peminjamanChannel!);
    }
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    try {
      final stats = await SupabaseServices.getDashboardStats();
      final chart = await SupabaseServices.getWeeklyPeminjamanStats();
      if (mounted) {
        setState(() {
          totalAlat = stats['total_alat'] ?? 0;
          alatTersedia = stats['alat_tersedia'] ?? 0;
          alatDipinjam = stats['alat_dipinjam'] ?? 0;
          weeklyData = chart;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _subscribeRealtime() {
    _alatChannel = SupabaseServices.subscribeToDashboardAlat((data) {
      if (mounted) {
        setState(() {
          totalAlat = data['total_alat'] ?? 0;
          alatTersedia = data['alat_tersedia'] ?? 0;
          alatDipinjam = data['alat_dipinjam'] ?? 0;
        });
      }
    });

    _peminjamanChannel =
        SupabaseServices.subscribeToDashboardPeminjaman((data) {
      if (mounted) setState(() => weeklyData = data);
    });
  }

  String _getCurrentDate() {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
        .format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: Stack(
        children: [
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double maxWidth = 1100;

                        return Center(
                          child: Container(
                            width: constraints.maxWidth > maxWidth
                                ? maxWidth
                                : constraints.maxWidth,
                            child: Column(
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 22),
                                _buildWelcomeCard(),
                                const SizedBox(height: 28),
                                _buildStats(),
                                const SizedBox(height: 32),
                                _buildChartCard(),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          if (isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => isMenuOpen = false),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black12),
                ),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: isMenuOpen ? 95 : -220,
            left: 16,
            right: 16,
            child: _buildDropdownMenu(),
          ),
        ],
      ),
    );
  }

  // ================= APPBAR =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 35,
        left: 22,
        right: 22,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: primaryAppbar,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard Admin",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: InkWell(
              onTap: () => setState(() => isMenuOpen = !isMenuOpen),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFDDDDDDD),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= WELCOME =================
  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: _softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Halo, Selamat Datang!",
              style: GoogleFonts.poppins(
                color: textBlue,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.username,
              style: GoogleFonts.poppins(
                color: textBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getCurrentDate(),
              style: GoogleFonts.poppins(
                color: textBlue.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATS (SCROLLABLE) =================
  Widget _buildStats() {
    return SizedBox(
      height: 190,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            _statItem("Total\nAlat", "$totalAlat"),
            _statItem("Alat\nTersedia", "$alatTersedia"),
            _statItem("Sedang\nDipinjam", "$alatDipinjam"),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String title, String value) {
    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: _softShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: textBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: textBlue,
              fontSize: 45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= CHART =================
  Widget _buildChartCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: _softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: greyInnerChart,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "Grafik Peminjaman",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 180,
              child: weeklyData.isEmpty
                  ? const Center(child: Text("Belum ada data"))
                  : BarChart(
                      BarChartData(
                        maxY: _getMaxY(),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: _buildChartTitles(),
                        barGroups: _buildBarGroups(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DROPDOWN =================
  Widget _buildDropdownMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 15),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _menuIcon(Icons.grid_view, "Dashboard", () {}),
          _menuIcon(Icons.build, "Alat", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AlatScreen(username: widget.username)));
          }),
          _menuIcon(Icons.assignment, "Pinjam", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PeminjamanAdminScreen()));
          }),
          _menuIcon(Icons.history, "Log", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LogAktivitasScreen()));
          }),
          _menuIcon(Icons.person_add, "Tambah", () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemberScreen()));
          }),
          _menuIcon(Icons.settings, "Akun", () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountScreen()));
          }),
        ],
      ),
    );
  }

  Widget _menuIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        setState(() => isMenuOpen = false);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textBlue, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: textBlue,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ================= UTIL =================
  FlTitlesData _buildChartTitles() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              weeklyData[v.toInt()]['day_label'] ?? '',
              style: GoogleFonts.poppins(fontSize: 10),
            ),
          ),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (v, _) =>
              Text(v.toInt().toString(), style: GoogleFonts.poppins(fontSize: 10)),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _getMaxY() {
    if (weeklyData.isEmpty) return 10;
    return weeklyData
            .map((e) => (e['total'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) +
        5;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(weeklyData.length, (i) {
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: (weeklyData[i]['total'] as num).toDouble(),
          color: primaryAppbar,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        )
      ]);
    });
  }

  List<BoxShadow> _softShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(5, 5),
      ),
      const BoxShadow(
        color: Colors.white,
        blurRadius: 12,
        offset: Offset(-5, -5),
      ),
    ];
  }
}
