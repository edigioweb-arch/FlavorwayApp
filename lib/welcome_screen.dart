import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _offsetAnimation; // Changé en Animation<Offset>

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Correction du Slide : On utilise un Tween d'Offset directement lié au contrôleur
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeFlavor = Color(0xFFF36A2D);
    const Color violetFlavor = Color(0xFF4B1F5C);

    return Scaffold(
      backgroundColor: orangeFlavor,
      body: Stack(
        children: [
          // Bulles décoratives
          Positioned(
            top: -50,
            left: -30,
            child: FadeInUp(
              child: _buildBackgroundBubble(200, Colors.white.withOpacity(0.1)),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -20,
            child: FadeInDown(
              child:
                  _buildBackgroundBubble(150, Colors.black.withOpacity(0.05)),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO AVEC ANIMATIONS CORRIGÉES
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SlideTransition(
                      position:
                          _offsetAnimation, // Utilisation de l'offset corrigé
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 20,
                                offset: Offset(0, 10))
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.restaurant_menu,
                                color: Color(0xFFF36A2D),
                                size: 60,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                FadeIn(
                  delay: const Duration(milliseconds: 1000),
                  child: Text(
                    'Bien manger,\nun plaisir à partager',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOUTON COMMENCER
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: BounceInUp(
              delay: const Duration(milliseconds: 1200),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: violetFlavor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Commencer',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildBackgroundBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
