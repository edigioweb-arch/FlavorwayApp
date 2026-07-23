

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditGalleryScreen extends StatelessWidget {
  const EditGalleryScreen({super.key});

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color background = Color(0xFFFAF8F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: violetFlavor),
        title: Text(
          'Photos et galerie',
          style: GoogleFonts.poppins(
            color: violetFlavor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ajoutez ici les photos du restaurant.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: orangeFlavor,
        onPressed: () {},
        child: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
    );
  }
}