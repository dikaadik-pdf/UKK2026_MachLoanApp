import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/member_services.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

class AddMemberDialog extends StatefulWidget {
  const AddMemberDialog({Key? key}) : super(key: key);

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final MemberService _memberService = MemberService();
  
  String _selectedRole = 'Admin';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleSubmit() async {
    // Validasi input
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Nama tidak boleh kosong', isError: true);
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showSnackbar('Email tidak boleh kosong', isError: true);
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showSnackbar('Password tidak boleh kosong', isError: true);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnackbar('Password minimal 6 karakter', isError: true);
      return;
    }

    // Tampilkan konfirmasi sebelum submit
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Konfirmasi',
        subtitle: 'Yakin ingin menambahkan anggota baru "${_nameController.text.trim()}" sebagai $_selectedRole?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final result = await _memberService.createMember(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _nameController.text.trim(),
      role: _memberService.roleToDatabase(_selectedRole),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        // Tampilkan success dialog
        await showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Berhasil!',
            subtitle: 'Anggota berhasil ditambahkan',
            onOk: () => Navigator.pop(context),
          ),
        );
        
        // Tutup dialog utama dan kirim result
        if (mounted) {
          Navigator.pop(context, result);
        }
      } else {
        _showSnackbar(result['message'], isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 345,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF769DCB),
          borderRadius: BorderRadius.circular(25),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tambah Anggota",
                style: GoogleFonts.poppins(
                  fontSize: 27,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 30),

              // Input Nama
              _buildField("Nama", _nameController),
              const SizedBox(height: 14),

              // Input Email
              _buildField("Email", _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),

              // Input Password
              _buildField(
                "Password",
                _passwordController,
                obscureText: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 14),

              // Dropdown Role
              _buildRoleDropdown(),
              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      "Kembali",
                      const Color(0xFF6B7280),
                      _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      "Tambah",
                      const Color(0xFF2F3A40),
                      _isLoading ? null : _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF1F4F6F),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Role",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1F4F6F),
            borderRadius: BorderRadius.circular(25),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              dropdownColor: const Color(0xFF1F4F6F),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              items: ['Admin', 'Petugas', 'Peminjam'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    String text,
    Color color,
    VoidCallback? onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null ? color.withOpacity(0.5) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}