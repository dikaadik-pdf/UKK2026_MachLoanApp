import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/appcolors_models.dart';
import 'package:ukk2026_machloanapp/screens/users/loginpage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/mesinkiri.png',
                width: 250,
                height: 350,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          Positioned(
            bottom: -20,
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
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/mechloan.png',
                  width: 170,
                  height: 170,
                ),
                
                const SizedBox(height: 10),
                
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.buttonPrimary,
                          ),
                        );
                      },
                    );
                    
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.of(context).pop(); 
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    minimumSize: const Size(120, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Ayo!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}