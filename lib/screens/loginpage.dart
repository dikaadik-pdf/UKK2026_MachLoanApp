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
  bool _isSubmitted = false;
  final Set<String> _touchedFields = {};

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

  // Fungsi untuk validasi format email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Masukkan Email Kamu Ya!';
    }

    // Regular expression untuk validasi email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Format emailmu tidak sesuai :(';
    }

    return null;
  }

  Future<void> _handleLogin() async {
    setState(() => _isSubmitted = true);

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
            subtitle: 'Coba Cek Email atau Passwordmu Dulu Deh!',
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
                hint: 'Masukkan Emailmu Disini!',
                fieldName: 'email',
                validator: _validateEmail,
              ),
              const SizedBox(height: 25),
              _buildLabel('Password'),
              _buildInput(
                controller: _passwordController,
                hint: 'Masukkan Passwordmu Disini!',
                fieldName: 'password',
                obscure: _obscurePassword,
                validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Masukkan Password Kamu Ya!'
                        : null,
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
    required String fieldName,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    // Cek apakah error boleh ditampilkan:
    // - Sudah pernah klik tombol Login (_isSubmitted), atau
    // - Field ini sudah pernah di-tap (_touchedFields)
    final bool showError =
        _isSubmitted || _touchedFields.contains(fieldName);

    final String? errorText = showError ? validator?.call(controller.text) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
            autovalidateMode: AutovalidateMode.disabled,
            validator: validator,
            style: GoogleFonts.poppins(color: Colors.white),
            onTap: () {
              // Tandai field ini sudah pernah di-tap
              if (!_touchedFields.contains(fieldName)) {
                setState(() => _touchedFields.add(fieldName));
              }
            },
            onChanged: (value) {
              // Trigger rebuild supaya error text update real-time
              // setelah field ditouching atau sudah di-submit
              if (_touchedFields.contains(fieldName) || _isSubmitted) {
                setState(() {});
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.white60),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
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
        ),
        // Error text — hanya muncul kalau sudah di-submit atau field sudah di-tap
        if (errorText != null)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 335),
            padding: const EdgeInsets.only(left: 25, top: 8),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}