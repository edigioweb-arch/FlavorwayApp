import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

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
              color: Colors.white, // FOND DU LOGO PASSÉ EN BLANC
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
        onPressed: () {
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();

          if (email == 'admin@jolicoin.com' && password == '123456') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/restaurant-dashboard',
              (route) => false,
            );
            return;
          }

          if (UserAuthService.instance.login(
            email: email,
            password: password,
          )) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Identifiants incorrects'),
            ),
          );
        },
        child: const Text('Se connecter',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  Widget _buildSignUpText() {
    return Center(
      child: GestureDetector(
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
    );
  }
}
