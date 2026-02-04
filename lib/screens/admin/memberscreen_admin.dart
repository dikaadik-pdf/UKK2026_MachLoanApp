import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/member_models.dart';
import 'package:ukk2026_machloanapp/screens/admin/tambahmember_admin.dart';
import 'package:ukk2026_machloanapp/screens/admin/editmember_admin.dart';
import 'package:ukk2026_machloanapp/widgets/filter_widgets.dart';
import 'package:ukk2026_machloanapp/services/member_services.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final MemberService _memberService = MemberService();
  List<MemberModel> _allMembers = [];
  bool _isLoading = true;
  String _currentFilter = 'Admin';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
          _buildFloatingButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              'Kelola Anggota',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1F4F6F)),
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
                  backgroundColor: const Color(0xFF1F4F6F),
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
              color: const Color(0xFF1F4F6F),
              child: _filteredMembers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filteredMembers.length,
                      padding: const EdgeInsets.only(bottom: 100),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => _handleEdit(member),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => _handleDelete(member),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit(MemberModel member) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditMemberDialog(member: member),
    );

    if (result != null && result['success'] == true) {
      await _loadMembers();
    }
  }

  Widget _buildFloatingButton() {
    return Positioned(
      bottom: 35,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _handleAdd,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1F4F6F),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdd() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddMemberDialog(),
    );

    if (result != null && result['success'] == true) {
      await _loadMembers();
    }
  }
}
