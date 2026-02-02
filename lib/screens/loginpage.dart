import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appcolors_models.dart';
import '../models/users_models.dart';
import '../services/auth_services.dart';
import '../services/session_services.dart';
import '../services/navigation_services.dart';
import '../widgets/notification_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ===== LOGIN BERHASIL =====
      if (result['success'] == true) {
        final user = result['user'] as UserModel;
        await _sessionService.saveSession(user);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialog(
            title: 'Berhasil!',
            subtitle: 'Selamat datang, ${user.username}',
            onOk: () {
              Navigator.pop(context);
              NavigationService.navigateToHomeByRole(context, user);
            },
          ),
        );
      }
      // ===== LOGIN GAGAL =====
      else {
        showDialog(
          context: context,
          builder: (_) => SuccessDialog(
            title: 'Yah..',
            subtitle: result['message'] ?? 'Email atau password salah',
            onOk: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // ===== ERROR TAK TERDUGA =====
      showDialog(
        context: context,
        builder: (_) => SuccessDialog(
          title: 'Terjadi Kesalahan',
          subtitle: e.toString(),
          onOk: () => Navigator.pop(context),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                  _buildForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildForm() {
    return Container(
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
              _buildLabel('Email'),
              _buildInput(
                controller: _emailController,
                hint: 'Masukkan Email',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Masukkan Email!' : null,
              ),
              const SizedBox(height: 25),
              _buildLabel('Password'),
              _buildInput(
                controller: _passwordController,
                hint: 'Masukkan Password',
                obscure: _obscurePassword,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Masukkan Password!' : null,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 40),
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
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
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
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white60),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffix,
                ),
        ),
      ),
    );
  }
}
