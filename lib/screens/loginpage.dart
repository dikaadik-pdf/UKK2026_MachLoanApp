import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/appcolors_models.dart';
import 'package:ukk2026_machloanapp/models/users_models.dart';
import 'package:ukk2026_machloanapp/services/auth_services.dart';
import 'package:ukk2026_machloanapp/services/session_services.dart';
import 'package:ukk2026_machloanapp/services/navigation_services.dart';

// ================= SUCCESS DIALOG =================
class SuccessDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onOk;

  const SuccessDialog({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onOk,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          color: const Color(0xFF1F4F6F),
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: 120,
              height: 45,
              child: ElevatedButton(
                onPressed: onOk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3A40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Oke!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= LOGIN SCREEN =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final isLoggedIn = await _sessionService.isLoggedIn();
    if (isLoggedIn) {
      final user = await _sessionService.getSession();
      if (user != null && mounted) {
        NavigationService.navigateToHomeByRole(context, user);
      }
    }
  }

  // ================= HANDLE LOGIN =================
  void _handleLogin() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final user = result['user'] as UserModel;

        await _sessionService.saveSession(user);

        // ================= SHOW SUCCESS DIALOG =================
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialog(
            title: "Berhasil!",
            subtitle: "Selamat datang, ${user.username}",
            onOk: () {
              Navigator.pop(context); // tutup dialog
              NavigationService.navigateToHomeByRole(context, user);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login gagal!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 25,
            left: -20,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/mesinkanan.png',
                width: 250,
                height: 350,
              ),
            ),
          ),

          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),

                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.containerBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 40),

                            Text(
                              'LogIn',
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 40),

                            _buildLabel('Username'),
                            _buildInput(
                              controller: _usernameController,
                              hint: 'Masukan Username',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Masukan Username Anda!';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 25),

                            _buildLabel('Password'),
                            _buildInput(
                              controller: _passwordController,
                              hint: 'Masukan Password',
                              obscure: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Masukan Password Anda!';
                                }
                                return null;
                              },
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),

                            const SizedBox(height: 50),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonPrimary,
                                minimumSize: const Size(160, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Image.asset('assets/images/mechloan.png', width: 90, height: 90),
          const SizedBox(height: 45),

          Text(
            'Selamat Datang di MachLoan',
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Part Of',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'SMKS BRANTAS KARANGKATES',
            style: GoogleFonts.poppins(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
    Function(String)? onFieldSubmitted,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 335),
      height: 60,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.innerContainer,
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white60),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 25),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
