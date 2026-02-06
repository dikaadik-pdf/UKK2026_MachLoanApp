import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/member_models.dart';
import 'package:ukk2026_machloanapp/screens/admin/tambahmember_admin.dart';
import 'package:ukk2026_machloanapp/screens/admin/editmember_admin.dart';
import 'package:ukk2026_machloanapp/widgets/filter_widgets.dart';
import 'package:ukk2026_machloanapp/services/member_services.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/appbar_widgets.dart';
import 'package:intl/intl.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();
  List<MemberModel> _allMembers = [];
  bool _isLoading = true;
  String _currentFilter = 'Admin';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await _memberService.getAllMembers();

      if (mounted) {
        setState(() {
          _allMembers = members;
          _isLoading = false;
        });

        print('✅ UI Updated: ${members.length} members loaded');
      }
    } catch (e) {
      print('❌ Error loading members: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<MemberModel> get _filteredMembers {
    return _allMembers.where((m) => m.status == _currentFilter).toList();
  }

  Future<void> _handleDelete(MemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hmm..',
        subtitle: 'Kamu Yakin Hapus Akun Dia?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final result = await _memberService.deleteMember(member.id);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (result['success']) {
        // Tampilkan success dialog
        await showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Berhasil!',
            subtitle: 'Anggota berhasil dihapus',
            onOk: () => Navigator.pop(context),
          ),
        );

        await _loadMembers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: CustomAppBarWithSearch(
        title: 'Keanggotaan',
        searchController: _searchController,
        searchHintText: 'Cari Anggota Disini!',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent()),
          _buildAddMemberButton(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF769DCB)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadMembers,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF769DCB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),

          // Filter Bar
          Center(
            child: CustomFilterBar(
              filters: const ['Admin', 'Petugas', 'Peminjam'],
              initialFilter: _currentFilter,
              onFilterSelected: (val) {
                setState(() => _currentFilter = val);
                print('🔍 Filter changed to: $val');
              },
            ),
          ),

          const SizedBox(height: 20),

          // Counter
          Text(
            '$_currentFilter : ${_filteredMembers.length}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMembers,
              color: const Color(0xFF769DCB),
              child: _filteredMembers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filteredMembers.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        return _buildMemberCard(_filteredMembers[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data $_currentFilter',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tarik ke bawah untuk refresh',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF769DCB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.nama,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.status,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inner container with badge and actions
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFDBEBFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge tanggal bergabung
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(member.createdAt),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handleEdit(member),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFF769DCB),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _handleDelete(member),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.delete,
                          color: Color(0xFF769DCB),
                          size: 22,
                        ),
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

  Future<void> _handleEdit(MemberModel member) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditMemberDialog(member: member),
    );

    if (result != null && result['success'] == true) {
      await _loadMembers();
    }
  }

  Widget _buildAddMemberButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF769DCB),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: _handleAdd,
          child: Container(
            height: 45,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Tambah Anggota',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdd() async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddMemberDialog(),
    );

    if (result != null && result['success'] == true) {
      await _loadMembers();
    }
  }
}