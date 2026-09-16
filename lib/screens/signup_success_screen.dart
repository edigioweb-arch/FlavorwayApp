import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignupSuccessScreen extends StatefulWidget {
  const SignupSuccessScreen(
      {super.key,
      required this.title,
      required this.message,
      required this.resendEmail,
      required this.signOut,
      this.verificationError});
  final String title;
  final String message;
  final String? verificationError;
  final Future<void> Function() resendEmail;
  final Future<void> Function() signOut;

  @override
  State<SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends State<SignupSuccessScreen> {
  late String? _error = widget.verificationError;
  bool _busy = false;
  DateTime? _lastSent;

  Future<void> _resend() async {
    if (_busy) return;
    if (_lastSent != null &&
        DateTime.now().difference(_lastSent!).inSeconds < 60) {
      setState(() => _error = 'Patientez une minute avant un nouvel envoi.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.resendEmail();
      if (!mounted) return;
      setState(() {
        _error = null;
        _lastSent = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      await widget.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = 'Impossible de quitter la session. Réessayez.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF18A558),
          body: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 110),
              const SizedBox(height: 24),
              Text(widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              Text(
                  _error == null
                      ? 'L’envoi du lien de vérification a été accepté. Consultez votre boîte mail et vos courriers indésirables.'
                      : 'Votre compte est créé, mais l’envoi du lien de vérification a échoué.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              OutlinedButton(
                  onPressed: _busy ? null : _resend,
                  style:
                      OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Renvoyer l’email de vérification')),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _busy ? null : _login,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0E7A40)),
                  child: const Text('Se connecter')),
            ]),
          ))),
        ),
      );
}
