import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Vérification via FormState
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: pwd,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String errorMsg = "Erreur de connexion";
        final errorStr = e.toString().toLowerCase();

        // Analyse claire des codes d'erreur couramment renvoyés par Firebase Auth
        if (errorStr.contains('wrong-password') ||
            errorStr.contains('user-not-found') ||
            errorStr.contains('invalid-credential')) {
          errorMsg =
              "Identifiants incorrects. Veuillez vérifier votre adresse email et votre mot de passe.";
        } else if (errorStr.contains('invalid-email')) {
          errorMsg = "L'adresse email saisie n'est pas dans un format valide.";
        } else if (errorStr.contains('user-disabled')) {
          errorMsg =
              "Ce compte a été suspendu ou désactivé par un administrateur.";
        } else if (errorStr.contains('too-many-requests')) {
          errorMsg =
              "Trop de tentatives de connexion échouées. Essayez à nouveau plus tard.";
        } else {
          errorMsg = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("⛔ $errorMsg",
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.redL),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir votre adresse e-mail dans le champ ci-dessus pour réinitialiser votre mot de passe."),
          backgroundColor: AppTheme.redL,
        ),
      );
      return;
    }

    final regex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+");
    if (!regex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir une adresse e-mail valide."),
          backgroundColor: AppTheme.redL,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("E-mail de réinitialisation envoyé ! Vérifiez votre boîte de réception."),
            backgroundColor: AppTheme.greenXl,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith("Exception: ")) {
          errorMsg = errorMsg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⛔ $errorMsg"),
            backgroundColor: AppTheme.redL,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo officiel
                Center(
                  child: Image.asset(
                    'assets/logo_splash.jpg',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: const Center(
                          child: Text("Logo",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12))),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Te revoilà !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.cream),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Connecte-toi pour continuer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted, fontSize: 14),
                ),

                const SizedBox(height: 48),

                // Email
                _buildInputLabel("Adresse Email"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.cream),
                  decoration: _buildInputDecoration(
                      hint: "exemple@gmail.com", icon: Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "L'email est requis";
                    }
                    final regex = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+");
                    if (!regex.hasMatch(value)) {
                      return "L'email n'est pas valide";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Mot de passe
                _buildInputLabel("Mot de passe"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.cream),
                  decoration: _buildInputDecoration(
                    hint: "Ton mot de passe",
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.muted,
                          size: 20),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Le mot de passe est requis";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: const Text("Mot de passe oublié ?",
                        style: TextStyle(
                            color: AppTheme.greenXl,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 48),

                // Bouton
                GestureDetector(
                  onTap: _isLoading ? null : _signIn,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.green, Color(0xFF145C26)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.green.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3))
                          : const Text(
                              "Se connecter",
                              style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Créer un compte
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Nouveau ici ? ",
                        style: TextStyle(color: AppTheme.muted)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()));
                      },
                      child: const Text("Créer un compte",
                          style: TextStyle(
                              color: AppTheme.greenXl,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.muted2,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.muted),
      prefixIcon: Icon(icon, color: AppTheme.muted, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      errorStyle:
          const TextStyle(color: AppTheme.redL, fontWeight: FontWeight.w600),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.redL, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.redL, width: 2),
      ),
    );
  }
}
