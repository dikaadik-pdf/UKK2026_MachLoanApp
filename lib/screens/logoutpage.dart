import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ukk2026_machloanapp/screens/splashscreen.dart';
import '../services/auth_services.dart';
import '../services/session_services.dart';
import '../services/supabase_services.dart';
import '../widgets/confirmation_widgets.dart';
import '../widgets/notification_widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  final ImagePicker _picker = ImagePicker();

  String _userName = 'Loading...';
  String _userRole = '';
  String? _avatarUrl;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _sessionService.getSession();
    if (user != null && mounted) {
      setState(() {
        _userName = user.username;
        _userRole = user.role;
        _userId = user.id;
        _avatarUrl = user.avatarUrl; // Load avatar from session
      });

      // Optional: Refresh avatar from database to ensure it's up to date
      if (_userId != null) {
        final latestAvatarUrl = await _authService.getUserAvatar(_userId!);
        if (mounted && latestAvatarUrl != null && latestAvatarUrl != _avatarUrl) {
          setState(() {
            _avatarUrl = latestAvatarUrl;
          });
          // Update session with latest avatar
          await _sessionService.updateAvatar(latestAvatarUrl);
        }
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 110,
          decoration: const BoxDecoration(
            color: Color(0xFF769DCB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(
                  'Ambil dari Galeri',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text(
                  'Ambil dari Kamera',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      try {
        String? uploadedUrl;

        if (kIsWeb) {
          // For web platform
          uploadedUrl = await SupabaseServices.uploadImageFromXFile(
            pickedFile,
            'avatar',
          );
        } else {
          // For mobile platform
          final File imageFile = File(pickedFile.path);
          uploadedUrl = await SupabaseServices.uploadImage(
            imageFile,
            'avatar',
          );
        }

        if (uploadedUrl != null && _userId != null) {
          // Update user avatar in database using AuthService
          await _authService.updateUserAvatar(_userId!, uploadedUrl);

          // Update session with new avatar
          await _sessionService.updateAvatar(uploadedUrl);

          setState(() {
            _avatarUrl = uploadedUrl;
          });

          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog

          // Show success dialog
          showDialog(
            context: context,
            builder: (_) => SuccessDialog(
              title: 'Berhasil!',
              subtitle: 'Foto profil berhasil diperbarui',
              onOk: () => Navigator.pop(context),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        // Show error dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              'Gagal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Gagal mengupload foto: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: const Color(0xFF769DCB)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Handle picker error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          // ================= HEADER =================
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
                    'Akun Kamu',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= CONTENT =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // ---------- CARD PROFIL ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF769DCB),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                backgroundImage: _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _avatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color(0xFF769DCB),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Color(0xFF769DCB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _userRole,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ---------- INFORMASI SISTEM ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF769DCB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Sistem',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Divider(color: Colors.white24),
                        _buildInfoRow('Nama Aplikasi', 'MachLoan App'),
                        const Divider(color: Colors.white24),
                        _buildInfoRow('Versi Aplikasi', 'V1.0.0'),
                        const Divider(color: Colors.white24),
                        _buildInfoRow(
                          'Didukung Oleh',
                          'SMKS BRANTAS KARANGKATES',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ---------- BUTTON LOGOUT ----------
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                      label: Text(
                        'LogOut',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOGOUT FLOW =================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmationDialog(
        title: 'Hmm...',
        subtitle: 'Keluar? Ingat Passwordmu Ya!',
        onBack: () => Navigator.pop(context),
        onContinue: () async {
          Navigator.pop(context);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );

          try {
            await _sessionService.clear();
            await _authService.logout();
          } catch (_) {}

          if (!mounted) return;
          Navigator.pop(context);

          _showLogoutSuccess(context);
        },
      ),
    );
  }

  void _showLogoutSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialog(
        title: 'Dadah!',
        subtitle: 'Anda telah keluar dari aplikasi.',
        onOk: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}