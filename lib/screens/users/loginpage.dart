import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/appcolors_models.dart';
import 'package:ukk2026_machloanapp/models/users_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String _usernameError = '';
  String _passwordError = '';

  void _handleLogin() {
    setState(() {
      _usernameError = '';
      _passwordError = '';
    });

    bool hasError = false;

    if (_usernameController.text.trim().isEmpty) {
      _usernameError = 'Masukan Username Anda!';
      hasError = true;
    }

    if (_passwordController.text.trim().isEmpty) {
      _passwordError = 'Masukan Password Anda!';
      hasError = true;
    }

    setState(() {});

    if (!hasError) {
      final loginData = LoginModel(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (loginData.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
                fit: BoxFit.contain,
              ),
            ),
          ),

          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/mechloan.png',
                          width: 90,
                          height: 90,
                        ),
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
                  ),

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
                          ),
                          _buildError(_usernameError),

                          const SizedBox(height: 25),

                          _buildLabel('Password'),
                          _buildInput(
                            controller: _passwordController,
                            hint: 'Masukan Password',
                            obscure: _obscurePassword,
                            suffix: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          _buildError(_passwordError),

                          const SizedBox(height: 50),

                          ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonPrimary,
                              minimumSize: const Size(120, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
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
                ],
              ),
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
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white60),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 18,
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    if (error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          error,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.errorRed,
          ),
        ),
      ),
    );
  }
}
