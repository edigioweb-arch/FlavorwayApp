// TOP PARTNERS SECTION - Équivalent HTML/CSS Glovo-style
// Full-width (100vw with calc margins), background primary color, padding spacing-xl, blob SVG + images partners
// Compatible Flutter web/mobile, responsive Row/Wrap

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopPartnersSection extends StatelessWidget {
  const TopPartnersSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors matching var(--brand-color-primary) = violetFlavor
    const Color violetFlavor = Color(0xFF4B1F5C);
    const Color highlightYellow = Color(0xFFFFD700); // mark highlight

    // Restaurants congo-adapted
    final List<Map<String, String>> partners = [
      {
        'name': 'McDonald\'s',
        'image':
            'https://glovo.dhmedia.io/image/customer-assets-glovo/countries/Stores/gnxccanx0ahfndxp2sce?t=W3sicmVzaXplIjp7Im1vZGUiOiJmaXQiLCJ3aWR0aCI6MjU2LCJoZWlnaHQiOjI1Nn19XQ==',
      },
      {
        'name': 'KFC',
        'image':
            'https://glovo.dhmedia.io/image/customer-assets-glovo/countries/Stores/rmwabp14jsoq3jqa0owm?t=W3sicmVzaXplIjp7Im1vZGUiOiJmaXQiLCJ3aWR0aCI6MjU2LCJoZWlnaHQiOjI1Nn19XQ==',
      },
      {
        'name': 'Burger King',
        'image':
            'https://glovo.dhmedia.io/image/customer-assets-glovo/countries/Stores/iq6pieolgsum8wjhik0n?t=W3sicmVzaXplIjp7Im1vZGUiOiJmaXQiLCJ3aWR0aCI6MjU2LCJoZWlnaHQiOjI1Nn19XQ==',
      },
      {
        'name': 'Pizza Hut',
        'image':
            'https://glovo.dhmedia.io/image/customer-assets-glovo/countries/Stores/rdh0te2q8k90xoh3bdlb?t=W3sicmVzaXplIjp7Im1vZGUiOiJmaXQiLCJ3aWR0aCI6MjU2LCJoZWlnaHQiOjI1Nn19XQ==',
      },
      {
        'name': 'Starbucks',
        'image':
            'https://glovo.dhmedia.io/image/customer-assets-glovo/countries/Stores/d45c9dweo5bhpesa5rbv?t=W3sicmVzaXplIjp7Im1vZGUiOiJmaXQiLCJ3aWR0aCI6MjU2LCJoZWlnaHQiOjI1Nn19XQ==',
      },
    ];

    return Container(
      // Full-width 100vw calc(50% - 50vw)
      width: double.infinity,
      // Background var(--background-color-primary)
      color: Colors.grey[50],
      // Padding calc(var(--spacing-xl))
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title: "Congo : Meilleurs restaurants et plus" with highlight mark
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: violetFlavor,
              ),
              children: [
                const TextSpan(text: "Congo "),
                TextSpan(
                  text: "Meilleurs restaurants et plus",
                  style: TextStyle(
                    backgroundColor: highlightYellow,
                    color: violetFlavor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Partners horizontal scroll/row, responsive
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: partners
                  .map(
                    (partner) => Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: PartnerCard(
                        name: partner['name']!,
                        image: partner['image']!,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Curve bottom (simplified gradient)
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PartnerCard extends StatelessWidget {
  final String name;
  final String image;

  const PartnerCard({super.key, required this.name, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Blob SVG background + image clip-path equivalent (ClipPath custom)
        ClipPath(
          clipper: BlobClipper(),
          child: Container(
            width: 128,
            height: 128,
            color: Colors.black12,
            child: Image.network(image, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        // Tag name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
        ),
      ],
    );
  }
}

class BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, size.height * 0.44);
    path.cubicTo(
      size.width * 1.05,
      size.height * 0.58,
      size.width * 1.02,
      size.height * 0.72,
      size.width * 0.92,
      size.height * 0.83,
    );
    path.cubicTo(
      size.width * 0.85,
      size.height * 0.93,
      size.width * 0.71,
      size.height * 0.98,
      size.width * 0.56,
      size.height * 1.0,
    );
    path.cubicTo(
      size.width * 0.41,
      size.height * 1.0,
      size.width * 0.27,
      size.height * 0.95,
      size.width * 0.16,
      size.height * 0.86,
    );
    path.cubicTo(
      size.width * 0.05,
      size.height * 0.77,
      0,
      size.height * 0.64,
      0,
      size.height * 0.51,
    );
    path.cubicTo(
      0,
      size.height * 0.38,
      size.width * 0.05,
      size.height * 0.26,
      size.width * 0.15,
      size.height * 0.17,
    );
    path.cubicTo(
      size.width * 0.26,
      size.height * 0.08,
      size.width * 0.61,
      0,
      size.width * 0.77,
      size.height * 0.003,
    );
    path.cubicTo(
      size.width * 0.93,
      size.height * 0.01,
      size.width * 1.02,
      size.height * 0.1,
      size.width,
      size.height * 0.44,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
