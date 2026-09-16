import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_auth_service.dart';
import '../widgets/auth_gate.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';
import 'restaurant_owner/restaurant_dashboard_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (kDebugMode) {
      // ignore: avoid_print
      print('=== LoginScreen _login DEBUT ===');
      // ignore: avoid_print
      print('Email: "$email"');
      // ignore: avoid_print
      print('Password vide: ${password.isEmpty}');
    }

    if (email.isEmpty || password.isEmpty) {
      _showError('Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        // ignore: avoid_print
        print('--- Appel signInWithProfileCheck ---');
      }

      await UserAuthService.instance.signInWithProfileCheck(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('--- signInWithProfileCheck réussi ---');
      }

      if (!mounted) return;

      final user = UserAuthService.instance.currentUser;
      if (user != null && !user.emailVerified) {
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const EmailVerificationScreen(
              noticeMessage:
                  'Veuillez vérifier votre adresse e-mail avant de vous connecter.',
            ),
          ),
          (route) => false,
        );
        return;
      }

      if (user != null) {
        final profile =
            await UserAuthService.instance.getUserProfile(uid: user.uid);
        final data = profile.data() ?? <String, dynamic>{};
        final role = (data['role'] as String?)?.trim().toLowerCase();

        if (role == 'restaurant' || role == 'restaurant_owner') {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Votre compte restaurateur est connecte. La validation admin reste en attente.',
              ),
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => RestaurantDashboardScreen(),
            ),
            (route) => false,
          );

          if (kDebugMode) {
            // ignore: avoid_print
            print(
                '--- LoginScreen: redirection vers /restaurant-dashboard ---');
          }

          return;
        }
      }

      // Retour vers la route racine (/) qui contient AuthGate.
      // AuthGate lira l'utilisateur Firebase connecté et affichera
      // le bon widget (HomeScreen ou EmailVerificationScreen).
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(
            loginWidget: WelcomePage(),
            verificationWidget: EmailVerificationScreen(),
            homeWidget: HomeScreen(),
          ),
        ),
        (route) => false,
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('--- LoginScreen: pushNamedAndRemoveUntil vers / ---');
      }
    } on UserAuthException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('UserAuthException attrapée: "${e.message}"');
      }
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Exception generique attrapée: $e');
        // ignore: avoid_print
        print('Type: ${e.runtimeType}');
      }
      if (!mounted) return;
      _showError(
          'Impossible de se connecter. Vérifiez votre connexion réseau.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      if (kDebugMode) {
        // ignore: avoid_print
        print('--- LoginScreen _login FIN (finally) ---');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: violetFlavor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildLogoSection(),
              const SizedBox(height: 40),
              _buildWelcomeText(),
              const SizedBox(height: 30),
              _buildInputField(
                  controller: _emailController,
                  hint: "Email ou utilisateur",
                  icon: Icons.person_outline),
              const SizedBox(height: 18),
              _buildInputField(
                  controller: _passwordController,
                  hint: "Mot de passe",
                  icon: Icons.lock_outline,
                  isPassword: true),
              _buildForgotPassword(),
              const SizedBox(height: 20),
              _buildLoginButton(),
              const SizedBox(height: 40),
              _buildSignUpText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
                height: 100,
                width: 100,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'FlavorWay',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: orangeFlavor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bon retour !',
            style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const Text('Connectez-vous pour continuer.',
            style: TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword))
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
          child: const Text('Mot de passe oublié ?',
              style: TextStyle(color: Colors.white70))),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: orangeFlavor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: _isLoading ? null : _login,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('Se connecter',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildSignUpText() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/signup'),
            child: RichText(
              text: TextSpan(
                text: "Pas de compte ? ",
                style: const TextStyle(color: Colors.white70),
                children: [
                  TextSpan(
                      text: 'Inscrivez-vous',
                      style: TextStyle(
                          color: orangeFlavor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SignUpScreen(initialRole: 'restaurant'),
                ),
              );
            },
            child: Text(
              'Créer un compte restaurateur',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
