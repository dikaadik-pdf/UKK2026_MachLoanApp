import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onContinue,
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
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Button Kembali
                SizedBox(
                  width: 120,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7280),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFDDDDDD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Button Lanjut
                SizedBox(
                  width: 120,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3A40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lanjut',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFDDDDDD),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}