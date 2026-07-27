import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);

  final List<Map<String, String>> onboardingData = const [
    {
      'image': 'assets/images/logo.jpeg',
      'title': 'FlavorWay',
      'description':
          'Découvrez les meilleurs restaurants, menus QR et réservations à Brazzaville.',
    },
    {
      'image': 'assets/images/offer.png',
      'title': 'Découvrez les meilleures adresses culinaires',
      'description':
          'Trouvez des restaurants, offres spéciales et expériences culinaires locales autour de vous.',
    },
    {
      'image': 'assets/images/restaurants/joli_coin/gallery_1.png',
      'title': 'Créez votre collection de restaurants favoris',
      'description':
          'Enregistrez vos restaurants préférés et réservez votre prochaine table facilement.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    _goToLogin();
  }

  void _previousPage() {
    if (_currentPage == 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF7),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -70,
              left: -60,
              child: _buildBackgroundBubble(
                240,
                violetFlavor.withOpacity(0.12),
              ),
            ),
            Positioned(
              top: 170,
              right: -45,
              child: _buildBackgroundBubble(
                140,
                violetFlavor.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: 120,
              left: 24,
              child: _buildBackgroundBubble(
                90,
                violetFlavor.withOpacity(0.08),
              ),
            ),
            PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildOnboardingSlide(onboardingData[index], index);
              },
            ),
            Positioned(
              top: 14,
              right: 18,
              child: FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Passer',
                    style: GoogleFonts.poppins(
                      color: violetFlavor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _previousPage,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _currentPage > 0 ? 1 : 0,
                        child: Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: violetFlavor.withOpacity(0.25)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: violetFlavor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 9,
                          width: _currentPage == index ? 22 : 9,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? violetFlavor
                                : violetFlavor.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(90),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: orangeFlavor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: orangeFlavor.withOpacity(0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentPage == onboardingData.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingSlide(Map<String, String> data, int index) {
    final bool isLogoSlide = index == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          FadeInDown(
            duration: const Duration(milliseconds: 650),
            child: Container(
              height: isLogoSlide ? 245 : 310,
              width: double.infinity,
              alignment: Alignment.center,
              child: isLogoSlide
                  ? _buildLogoCard(data['image']!)
                  : _buildMockupCard(data['image']!),
            ),
          ),
          const Spacer(),
          FadeInUp(
            duration: const Duration(milliseconds: 650),
            child: Text(
              data['title']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isLogoSlide ? 34 : 27,
                height: 1.14,
                fontWeight: FontWeight.w800,
                color: isLogoSlide ? orangeFlavor : violetDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 750),
            child: Text(
              data['description']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.55,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildLogoCard(String imagePath) {
    return Container(
      width: 190,
      height: 190,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBFF),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: violetFlavor.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.restaurant_menu_rounded,
              color: orangeFlavor,
              size: 70,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMockupCard(String imagePath) {
    return Container(
      width: 230,
      height: 305,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: violetFlavor,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: violetFlavor.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          color: Colors.white,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.image_not_supported_rounded,
                color: violetFlavor,
                size: 60,
              );
            },
          ),
        ),
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
