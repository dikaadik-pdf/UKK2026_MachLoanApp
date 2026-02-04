import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1F4F6F),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 100,
              height: 40,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
