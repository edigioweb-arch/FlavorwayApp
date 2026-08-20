import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/city_model.dart';
import '../services/city_api_service.dart';
import '../services/user_auth_service.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String? _userRole;

  // Contrôleurs
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _resNameController = TextEditingController();
  final TextEditingController _cuisineTypeController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _restaurantDeliveryFeeController =
      TextEditingController();

  bool _acceptTerms = false;
  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;
  String? _selectedCountry;
  String? _selectedCity;
  String? _usernameError;
  String? _confirmPasswordError;
  List<CityModel> _availableCities = const [];
  bool _isLoadingCities = false;
  bool _restaurantOwnDelivery = false;

  void _debugLog(String message) {
    // ignore: avoid_print
    debugPrint(message);
  }

  final List<String> _existingUsernames = ['jean242', 'flavor_user', 'admin'];

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _resNameController.dispose();
    _cuisineTypeController.dispose();
    _licenseController.dispose();
    _restaurantDeliveryFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoadingCities = true);

    try {
      final cities = await CityApiService().fetchCities();
      if (!mounted) {
        return;
      }

      setState(() {
        _availableCities = cities;
      });
    } catch (error) {
      _debugLog('Chargement villes inscription impossible: $error');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger les villes disponibles.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingCities = false);
      }
    }
  }

  bool _isStepValid() {
    if (_userRole == null) return false;

    if (_userRole == 'client') {
      if (_currentStep == 0) {
        final passwordValid = _passController.text.length >= 6;
        final confirmValid =
            _confirmPassController.text == _passController.text &&
                _confirmPassController.text.isNotEmpty;
        return _fullNameController.text.trim().isNotEmpty &&
            _usernameController.text.trim().isNotEmpty &&
            _usernameError == null &&
            _emailController.text.trim().contains('@') &&
            _phoneController.text.trim().isNotEmpty &&
            passwordValid &&
            confirmValid;
      }

      return _selectedCountry != null &&
          _selectedCity != null &&
          _addressController.text.trim().isNotEmpty &&
          _acceptTerms;
    }

    if (_currentStep == 0) {
      return _fullNameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _emailController.text.trim().contains('@');
    }

    if (_currentStep == 1) {
      return _resNameController.text.trim().isNotEmpty &&
          _cuisineTypeController.text.trim().isNotEmpty &&
          _licenseController.text.trim().isNotEmpty &&
          (!_restaurantOwnDelivery ||
              double.tryParse(_restaurantDeliveryFeeController.text.trim()) != null);
    }

    final passwordValid = _passController.text.length >= 6;
    final confirmValid = _confirmPassController.text == _passController.text &&
        _confirmPassController.text.isNotEmpty;
    return _selectedCountry != null &&
        _selectedCity != null &&
        _addressController.text.trim().isNotEmpty &&
        passwordValid &&
        confirmValid &&
        _acceptTerms;
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = null;
      } else if (value != _passController.text) {
        _confirmPasswordError = 'Les mots de passe ne correspondent pas.';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  Future<void> _goNext() async {
    if (_isLoading || !_isStepValid()) return;

    // Vérification finale de la confirmation du mot de passe avant soumission
    final bool isLast = (_userRole == 'client' && _currentStep == 1) ||
        (_userRole == 'restaurant' && _currentStep == 2);

    if (isLast) {
      // Vérifier que les mots de passe correspondent
      if (_passController.text != _confirmPassController.text) {
        setState(() {
          _confirmPasswordError = 'Les mots de passe ne correspondent pas.';
        });
        return;
      }
      // Vérifier que le mot de passe fait au moins 6 caractères
      if (_passController.text.length < 6) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Le mot de passe doit contenir au moins 6 caractères.'),
          ),
        );
        return;
      }
      await _createAccount();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );

    if (mounted) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _createAccount() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final String fullName = _fullNameController.text.trim();
      final List<String> nameParts = fullName.split(' ');
      final String firstName = nameParts.first;
      final String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final Map<String, dynamic> profileData = {
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'phone': _phoneController.text.trim(),
        'role': _userRole,
        'country': _selectedCountry,
        'city': _selectedCity ?? _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'status': _userRole == 'restaurant' ? 'pending' : 'active',
      };

      if (_userRole == 'client') {
        profileData['username'] = _usernameController.text.trim().toLowerCase();
      }

      if (_userRole == 'restaurant') {
        profileData.addAll({
          'restaurantName': _resNameController.text.trim(),
          'cuisineType': _cuisineTypeController.text.trim(),
          'licenseNumber': _licenseController.text.trim(),
          'deliveryMode': _restaurantOwnDelivery ? 'restaurant' : 'flavorway',
          'restaurantDeliveryFee': _restaurantOwnDelivery
              ? double.tryParse(_restaurantDeliveryFeeController.text.trim()) ?? 0
              : null,
        });
      }

      // Utiliser UserAuthService.signUp() qui crée Firebase Auth + Firestore
      await UserAuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passController.text,
        profileData: profileData,
      );

      if (!mounted) return;
      await UserAuthService.instance.signOut();
      await _showSuccessDialog();
    } on UserAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur inattendue est survenue.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    final bool isRestaurant = _userRole == 'restaurant';
    final String title = isRestaurant
        ? 'Compte restaurateur créé avec succès !'
        : 'Compte créé avec succès !';
    final String message = isRestaurant
        ? 'Votre demande restaurateur a bien été enregistrée.'
        : 'Votre compte FlavorWay a bien été créé.';
    final String subtitle = isRestaurant
        ? 'Vous pouvez maintenant vous connecter et suivre la validation de votre compte.'
        : 'Vous pouvez maintenant vous connecter.';

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _SignupSuccessScreen(
          title: title,
          message: message,
          subtitle: subtitle,
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (_isLoading) return;

    if (_userRole != null && _currentStep == 0) {
      setState(() => _userRole = null);
    } else if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: violetFlavor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    IconButton(
                      onPressed: () => _goBack(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 22),
                    ),
                    _buildLogoHeader(),
                    const SizedBox(height: 20),
                    _buildTitleSection(),
                    const SizedBox(height: 20),
                    if (_userRole == null)
                      _buildRoleSelection()
                    else ...[
                      _buildProgressIndicator(),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: _userRole == 'restaurant' ? 500 : 420,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _userRole == 'client'
                              ? [
                                  _stepClient1(),
                                  _stepFinal(isRestaurant: false)
                                ]
                              : [
                                  _stepResto1(),
                                  _stepResto2(),
                                  _stepFinal(isRestaurant: true)
                                ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_userRole != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 10),
                child: _buildBottomButton(),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _buildFooterLogin(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final bool isLast = (_userRole == 'client' && _currentStep == 1) ||
        (_userRole == 'restaurant' && _currentStep == 2);
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: orangeFlavor,
          disabledBackgroundColor: orangeFlavor.withOpacity(0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(90)),
        ),
        onPressed: _isLoading || !_isStepValid() ? null : _goNext,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? "Créer un compte" : "Suivant",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _stepClient1() => Column(children: [
        _buildInputField(
            hint: 'Nom complet',
            icon: Icons.person,
            controller: _fullNameController),
        const SizedBox(height: 15),
        _buildInputField(
            hint: 'Utilisateur',
            icon: Icons.alternate_email,
            controller: _usernameController,
            onChanged: (v) {
              setState(() => _usernameError =
                  _existingUsernames.contains(v.toLowerCase())
                      ? "Déjà pris"
                      : null);
            },
            errorText: _usernameError),
        const SizedBox(height: 15),
        _buildInputField(
            hint: 'Email',
            icon: Icons.email_outlined,
            controller: _emailController),
        const SizedBox(height: 15),
        _buildInputField(
            hint: 'Téléphone pour OTP',
            icon: Icons.phone_outlined,
            controller: _phoneController),
        const SizedBox(height: 15),
        _buildPasswordField(
          controller: _passController,
          hint: 'Mot de passe',
          isObscure: _isObscure,
          onToggleObscure: () => setState(() => _isObscure = !_isObscure),
          onChanged: (v) {
            // Re-valider la confirmation si elle a déjà été saisie
            if (_confirmPassController.text.isNotEmpty) {
              _validateConfirmPassword(_confirmPassController.text);
            }
            setState(() {});
          },
        ),
        const SizedBox(height: 15),
        _buildPasswordField(
          controller: _confirmPassController,
          hint: 'Confirmer le mot de passe',
          isObscure: _isConfirmObscure,
          onToggleObscure: () =>
              setState(() => _isConfirmObscure = !_isConfirmObscure),
          onChanged: _validateConfirmPassword,
          errorText: _confirmPasswordError,
        ),
      ]);

  Widget _stepResto1() => Column(children: [
        _restaurantStepHeader(
          icon: Icons.person_rounded,
          title: 'Responsable du restaurant',
          subtitle: 'Renseignez les informations du gérant ou propriétaire.',
        ),
        const SizedBox(height: 18),
        _buildInputField(
            hint: 'Nom du gérant',
            icon: Icons.person,
            controller: _fullNameController),
        const SizedBox(height: 15),
        _buildInputField(
            hint: 'Téléphone professionnel',
            icon: Icons.phone,
            controller: _phoneController),
        const SizedBox(height: 15),
        _buildInputField(
            hint: 'Email professionnel',
            icon: Icons.email_outlined,
            controller: _emailController),
      ]);

  Widget _stepResto2() => Column(children: [
        _restaurantStepHeader(
          icon: Icons.storefront_rounded,
          title: 'Informations du restaurant',
          subtitle: 'Ces informations seront visibles sur la fiche client.',
        ),
        const SizedBox(height: 18),
        _buildInputField(
            hint: 'Nom du restaurant',
            icon: Icons.restaurant,
            controller: _resNameController),
        const SizedBox(height: 15),
        _buildInputField(
            hint: 'Type de cuisine',
            icon: Icons.ramen_dining,
            controller: _cuisineTypeController),
        const SizedBox(height: 15),
        _buildInputField(
            hint: 'N° licence ou registre',
            icon: Icons.description_outlined,
            controller: _licenseController),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disposez-vous de votre propre service de livraison ?',
                style: GoogleFonts.poppins(
                  color: violetDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: true, label: Text('Oui')),
                  ButtonSegment<bool>(value: false, label: Text('Non')),
                ],
                selected: {_restaurantOwnDelivery},
                onSelectionChanged: (selection) {
                  setState(() {
                    _restaurantOwnDelivery = selection.first;
                    if (!_restaurantOwnDelivery) {
                      _restaurantDeliveryFeeController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_restaurantOwnDelivery) ...[
                _buildInputField(
                  hint: 'Tarif de livraison (FCFA)',
                  icon: Icons.local_shipping_outlined,
                  controller: _restaurantDeliveryFeeController,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous serez responsable de l’exécution de la livraison pour les commandes de votre restaurant.',
                  style: GoogleFonts.poppins(
                    color: violetDark.withOpacity(0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else
                Text(
                  'Les livraisons seront prises en charge selon la grille FlavorWay applicable à la zone de destination du client.',
                  style: GoogleFonts.poppins(
                    color: violetDark.withOpacity(0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ]);

  Widget _stepFinal({required bool isRestaurant}) => Column(children: [
        if (isRestaurant) ...[
          _restaurantStepHeader(
            icon: Icons.location_on_rounded,
            title: 'Localisation & accès',
            subtitle:
                'Ajoutez le pays, la ville, l\'adresse et le mot de passe de l\'espace restaurateur.',
          ),
          const SizedBox(height: 14),
        ],
        _buildCountryDropdown(),
        const SizedBox(height: 12),
        _buildCityDropdown(),
        const SizedBox(height: 12),
        _buildInputField(
            hint: 'Adresse',
            icon: Icons.map_outlined,
            controller: _addressController),
        if (isRestaurant) ...[
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _passController,
            hint: 'Mot de passe',
            isObscure: _isObscure,
            onToggleObscure: () => setState(() => _isObscure = !_isObscure),
            onChanged: (v) {
              if (_confirmPassController.text.isNotEmpty) {
                _validateConfirmPassword(_confirmPassController.text);
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _confirmPassController,
            hint: 'Confirmer le mot de passe',
            isObscure: _isConfirmObscure,
            onToggleObscure: () =>
                setState(() => _isConfirmObscure = !_isConfirmObscure),
            onChanged: _validateConfirmPassword,
            errorText: _confirmPasswordError,
          ),
        ],
        const SizedBox(height: 6),
        Row(children: [
          Checkbox(
              value: _acceptTerms,
              activeColor: orangeFlavor,
              side: const BorderSide(color: Colors.white),
              onChanged: (v) => setState(() => _acceptTerms = v ?? false)),
          Expanded(
              child: Text("J'accepte les conditions d'utilisation",
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12))),
        ]),
      ]);

  Widget _restaurantStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: orangeFlavor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(90),
            ),
            child: Icon(icon, color: orangeFlavor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: (v) {
        if (onChanged != null) onChanged(v);
        setState(() {});
      },
      style: GoogleFonts.poppins(
        color: violetDark,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: violetFlavor),
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(90),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(90),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(90),
            borderSide: const BorderSide(color: orangeFlavor, width: 1.4)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggleObscure,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      onChanged: (v) {
        if (onChanged != null) onChanged(v);
      },
      style: GoogleFonts.poppins(
        color: violetDark,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: violetFlavor),
        suffixIcon: IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade500),
            onPressed: onToggleObscure),
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(90),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(90),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(90),
            borderSide: const BorderSide(color: orangeFlavor, width: 1.4)),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return GestureDetector(
      onTap: _isLoadingCities || _countryLabels.isEmpty ? null : () => _showCountryPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(90)),
        child: Row(children: [
          const Icon(Icons.public, color: violetFlavor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(_selectedCountry ?? (_isLoadingCities ? 'Chargement des pays...' : 'Choisir un pays'),
                  style: GoogleFonts.poppins(
                      color: _selectedCountry == null
                          ? Colors.grey
                          : Colors.black))),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildCityDropdown() {
    final cities = _selectedCountry == null ? <String>[] : _citiesForCountry(_selectedCountry!);

    return GestureDetector(
      onTap: _isLoadingCities || cities.isEmpty ? null : () => _showCityPicker(cities),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(90),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_city, color: violetFlavor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedCity ??
                    (_selectedCountry == null
                        ? 'Choisir d’abord un pays'
                        : 'Choisir une ville'),
                style: GoogleFonts.poppins(
                  color: _selectedCity == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: _countryLabels
            .map((c) => ListTile(
                title: Text(c),
                onTap: () {
                  setState(() {
                    _selectedCountry = c;
                    _selectedCity = null;
                    _cityController.clear();
                  });
                  Navigator.pop(context);
                }))
            .toList(),
      ),
    );
  }

  void _showCityPicker(List<String> cities) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: cities
            .map((city) => ListTile(
                  title: Text(city),
                  onTap: () {
                    setState(() {
                      _selectedCity = city;
                      _cityController.text = city;
                    });
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  List<String> get _countryLabels {
    final labels = _availableCities
        .map((city) => _displayCountryLabel(city))
        .toSet()
        .toList(growable: false);
    labels.sort();
    return labels;
  }

  List<String> _citiesForCountry(String countryLabel) {
    final cities = _availableCities
        .where((city) => _displayCountryLabel(city) == countryLabel)
        .map((city) => city.name)
        .toList(growable: false);
    cities.sort();
    return cities;
  }

  String _displayCountryLabel(CityModel city) {
    switch (city.countryIsoCode.toUpperCase()) {
      case 'CG':
        return 'République du Congo (Brazzaville)';
      case 'CD':
        return 'RD Congo';
      default:
        return city.countryName;
    }
  }

  Widget _buildLogoHeader() {
    return Center(
        child: Column(children: [
      Container(
          height: 86,
          width: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(90),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.restaurant, color: orangeFlavor, size: 42)),
      const SizedBox(height: 10),
      Text('FlavorWay',
          style: GoogleFonts.poppins(
              fontSize: 25, fontWeight: FontWeight.w800, color: orangeFlavor)),
    ]));
  }

  Widget _buildTitleSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          _userRole == null
              ? 'Créer un compte'
              : (_userRole == 'client' ? 'Compte Client' : 'Compte Pro'),
          style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
      const Text('Veuillez remplir les informations ci-dessous.',
          style: TextStyle(color: Colors.white70)),
    ]);
  }

  Widget _buildRoleSelection() {
    return Column(children: [
      _roleButton("Je suis un client", Icons.person_outline, 'client'),
      const SizedBox(height: 16),
      _roleButton(
          "Je suis un restaurateur", Icons.storefront_outlined, 'restaurant'),
    ]);
  }

  Widget _roleButton(String text, IconData icon, String role) {
    return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90))),
            onPressed: () => setState(() {
                  _userRole = role;
                  _currentStep = 0;
                }),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: violetFlavor),
              const SizedBox(width: 10),
              Text(text,
                  style: GoogleFonts.poppins(
                      color: violetFlavor, fontWeight: FontWeight.w600))
            ])));
  }

  Widget _buildProgressIndicator() {
    int steps = _userRole == 'client' ? 2 : 3;
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            steps,
            (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentStep == i ? 24 : 8,
                decoration: BoxDecoration(
                    color: _currentStep >= i ? orangeFlavor : Colors.white24,
                    borderRadius: BorderRadius.circular(10)))));
  }

  Widget _buildFooterLogin() {
    return GestureDetector(
        onTap: _isLoading ? null : () => Navigator.pop(context),
        child: RichText(
            text: TextSpan(
                text: "Déjà un compte ? ",
                style: const TextStyle(color: Colors.white70),
                children: [
              TextSpan(
                  text: 'Se connecter',
                  style: TextStyle(
                      color: orangeFlavor, fontWeight: FontWeight.bold))
            ])));
  }
}

class _SignupSuccessScreen extends StatefulWidget {
  const _SignupSuccessScreen({
    required this.title,
    required this.message,
    required this.subtitle,
  });

  final String title;
  final String message;
  final String subtitle;

  @override
  State<_SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends State<_SignupSuccessScreen> {
  Timer? _redirectTimer;

  static const Color _successGreen = Color(0xFF18A558);
  static const Color _successGreenDark = Color(0xFF0E7A40);
  static const Color _surface = Color(0xFFEFFFF6);

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(seconds: 2), _goToLogin);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _goToLogin() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _successGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 78,
                  color: _successGreen,
                ),
              ),
              const SizedBox(height: 34),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _successGreenDark,
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _successGreenDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _goToLogin,
                  child: Text(
                    'Se connecter',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
