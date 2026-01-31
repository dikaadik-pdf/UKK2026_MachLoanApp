import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ukk2026_machloanapp/screens/admin/logoutpage.dart';
import 'package:ukk2026_machloanapp/screens/petugas/listalatpetugas.dart';
import 'package:ukk2026_machloanapp/screens/petugas/laporanpetugas.dart';
import 'package:ukk2026_machloanapp/screens/petugas/peminjamanpetugas.dart';

class DashboardScreenPetugas extends StatefulWidget {
  final String username;

  const DashboardScreenPetugas({super.key, required this.username});

  @override
  State<DashboardScreenPetugas> createState() => _DashboardScreenPetugasState();
}

class _DashboardScreenPetugasState extends State<DashboardScreenPetugas> {
  final List<double> weeklyData = [30, 12, 10, 20, 85, 40, 50];
  final List<String> weekDays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      endDrawer: _buildSidebar(context),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dashboard Petugas',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Halo, ${widget.username}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 34,
                      ),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
            ),

            // ===== CONTENT =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // STAT CARDS
                    Row(
                      children: [
                        _buildStatCard('Total\nAlat', '20', Icons.build_circle),
                        const SizedBox(width: 12),
                        _buildStatCard('Tersedia', '15', Icons.check_circle),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildStatCard('Dipinjam', '5', Icons.assignment),
                        const SizedBox(width: 12),
                        _buildStatCard('Peminjam', '8', Icons.people),
                      ],
                    ),

                    const SizedBox(height: 25),

                    _buildChartSection(),

                    const SizedBox(height: 25),

                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== STAT CARD =====
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F4F6F),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CHART SECTION =====
  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Grafik Peminjaman Minggu Ini',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: _buildChartTitles(),
                gridData: _buildChartGrid(),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== QUICK ACTIONS =====
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Menu Cepat',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F4F6F),
            ),
          ),
        ),
        Row(
          children: [
            _buildQuickActionCard(
              'Daftar Alat',
              Icons.build,
              const Color(0xFF769DCB),
              () {
                // Navigator.push ke halaman alat
              },
            ),
            const SizedBox(width: 12),
            _buildQuickActionCard(
              'Peminjaman',
              Icons.assignment,
              const Color(0xFF5C8AB8),
              () {
                // Navigator.push ke halaman peminjaman
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildQuickActionCard(
              'Laporan',
              Icons.description,
              const Color(0xFF4A7BA7),
              () {
                // Navigator.push ke halaman laporan petugas
              },
            ),
            const SizedBox(width: 12),
            _buildQuickActionCard(
              'Pengaturan',
              Icons.settings,
              const Color(0xFF3B6B94),
              () {
                // Navigator.push ke halaman settings
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== SIDEBAR =====
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 260,
          margin: const EdgeInsets.only(top: 50, right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF769DCB),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // User info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.username,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Petugas',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white24, height: 24),

              _buildSidebarItem(Icons.dashboard, 'Dashboard', () {
                Navigator.pop(context);
              }),

              const Divider(color: Colors.white24),

               _buildSidebarItem(Icons.build, 'Daftar Alat', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlatScreenPetugas(username: widget.username),
                  ),
                );
              }),
              const Divider(color: Colors.white24),

               _buildSidebarItem(Icons.volunteer_activism, 'Peminjaman', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PeminjamanPetugasScreen (username: widget.username),
                  ),
                );
              }),

              const Divider(color: Colors.white24),

             _buildSidebarItem(Icons.assignment, 'Laporan Petugas', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LaporanPage (username: widget.username),
                  ),
                );
              }),

              const Divider(color: Colors.white24),

              _buildSidebarItem(Icons.settings, 'Pengaturan', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  // ===== CHART HELPERS =====
  List<BarChartGroupData> _buildBarGroups() => List.generate(
        weeklyData.length,
        (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: weeklyData[i],
              color: const Color(0xFF769DCB),
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );

  FlTitlesData _buildChartTitles() => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                weekDays[v.toInt()],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (v, _) => Text(
              '${v.toInt()}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      );

  FlGridData _buildChartGrid() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(
          color: Colors.white10,
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      );
}