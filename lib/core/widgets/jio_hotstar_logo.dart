import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JioHotstarLogo extends StatelessWidget {
  final double size;
  final bool showBadge;

  const JioHotstarLogo({
    super.key,
    this.size = 24.0,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Jio',
              style: GoogleFonts.poppins(
                fontSize: size,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Hotstar',
              style: GoogleFonts.poppins(
                fontSize: size,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE50914),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        if (showBadge) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'PREMIUM',
              style: GoogleFonts.poppins(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
