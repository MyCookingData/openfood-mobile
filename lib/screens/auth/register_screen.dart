import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_feedback.dart';
import '../legal/legal_viewer_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  final UserRole _selectedRole = UserRole.client;
  DateTime? _selectedDateOfBirth;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  int? get _currentCalculatedAge {
    if (_selectedDateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDateOfBirth!.year;
    if (now.month < _selectedDateOfBirth!.month || (now.month == _selectedDateOfBirth!.month && now.day < _selectedDateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final defaultInitial = DateTime(now.year - 20, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? defaultInitial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: "VOTRE DATE DE NAISSANCE (18 ANS MINIMUM REQUIS)",
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.greenXl,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.cream,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });

      int age = now.year - picked.year;
      if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
        age--;
      }

      if (age < 18) {
        if (mounted) {
          UiFeedback.showError(
            context,
            "Âge invalide ($age an${age > 1 ? 's' : ''}) : Vous devez avoir au moins 18 ans révolus pour vous inscrire sur OpenFood (CGU Art. 4.1).",
            duration: const Duration(seconds: 7),
          );
        }
      } else {
        if (mounted) {
          UiFeedback.showSuccess(
            context,
            "Âge validé : $age ans (Majeur).",
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  Future<void> _signUp() async {
    // 1. Vérification de la date de naissance
    if (_selectedDateOfBirth == null) {
      UiFeedback.showError(
        context,
        "Veuillez sélectionner votre date de naissance.",
      );
      return;
    }

    final age = _currentCalculatedAge ?? 0;
    if (age < 18) {
      UiFeedback.showError(
        context,
        "Âge invalide ($age an${age > 1 ? 's' : ''}) : Vous devez être majeur (au moins 18 ans révolus) pour créer un compte sur OpenFood.",
      );
      return;
    }

    // 2. Validation des champs du formulaire
    if (!_formKey.currentState!.validate()) {
      UiFeedback.showWarning(
        context,
        "Veuillez renseigner tous les champs obligatoires du formulaire.",
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    // 3. Validation de sécurité du mot de passe
    final pwdError = AuthService.validatePasswordStrength(pwd);
    if (pwdError != null) {
      UiFeedback.showError(
        context,
        pwdError,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: pwd,
        role: _selectedRole,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _selectedDateOfBirth,
      );

      if (user != null && mounted) {
        UiFeedback.showSuccess(
          context,
          "Compte créé avec succès ! Un e-mail de confirmation vous a été envoyé.",
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UiFeedback.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.cream),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/logo_long.png',
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Créer un compte",
                  style: TextStyle(
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.cream),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Rejoignez OpenFood pour commander vos plats préférés ou livrer !",
                  style: TextStyle(color: AppTheme.muted, fontSize: 14),
                ),
                const SizedBox(height: 40),

                const SizedBox(height: 12),

                // Prénom
                _buildInputLabel("Prénom"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppTheme.cream),
                  decoration: _buildInputDecoration(
                      hint: "Votre prénom", icon: Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Le prénom est requis";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Nom
                _buildInputLabel("Nom"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppTheme.cream),
                  decoration: _buildInputDecoration(
                      hint: "Votre nom", icon: Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Le nom est requis";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Date de naissance
                _buildInputLabel("Date de naissance (18 ans minimum)"),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final isSet = _selectedDateOfBirth != null;
                    final isMinor = isSet && (_currentCalculatedAge ?? 0) < 18;
                    final isAdult = isSet && (_currentCalculatedAge ?? 0) >= 18;

                    return GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isMinor
                              ? const Color(0xFFC62828).withOpacity(0.12)
                              : isAdult
                                  ? const Color(0xFF1B5E20).withOpacity(0.12)
                                  : AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMinor
                                ? const Color(0xFFFF8A80)
                                : isAdult
                                    ? AppTheme.greenXl
                                    : AppTheme.border,
                            width: isSet ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isMinor
                                  ? Icons.error_outline_rounded
                                  : isAdult
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cake_outlined,
                              color: isMinor
                                  ? const Color(0xFFFF8A80)
                                  : isAdult
                                      ? AppTheme.greenXl
                                      : AppTheme.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                !isSet
                                    ? "Sélectionner une date"
                                    : "${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.year} (${_currentCalculatedAge} ans ${isMinor ? '- Mineur' : '- Majeur'})",
                                style: TextStyle(
                                  color: isMinor
                                      ? const Color(0xFFFF8A80)
                                      : isAdult
                                          ? Colors.white
                                          : AppTheme.muted,
                                  fontWeight: isSet ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Téléphone
                _buildInputLabel("Numéro de téléphone"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.cream),
                  decoration: _buildInputDecoration(
                      hint: "06 12 34 56 78", icon: Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Le numéro de téléphone est requis";
                    }
                    if (value.trim().length < 10) {
                      return "Numéro de téléphone invalide";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

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
                    hint: "8+ car. (1 Maj, 1 Min, 1 Chiffre, 1 Symbole)",
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
                    if (value.length < 8) {
                      return "Au moins 8 caractères requis";
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return "Au moins 1 majuscule (A-Z) requise";
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return "Au moins 1 minuscule (a-z) requise";
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return "Au moins 1 chiffre (0-9) requis";
                    }
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\_\-+=\[\]/\\]').hasMatch(value)) {
                      return "Au moins 1 caractère spécial (@, #, !, %, &...) requis";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 48),

                // Bouton
                GestureDetector(
                  onTap: _isLoading ? null : _signUp,
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
                              "S'inscrire",
                              style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Mention légale N2D
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LegalViewerScreen()),
                    ),
                    child: const Text(
                      "En créant un compte, vous acceptez les Conditions Générales (CGU / CGV) & la Politique de Remboursement de N2D NEW DELIVERY DRIVER.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        height: 1.4,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Déjà un compte ?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Déjà un compte ? ",
                        style: TextStyle(color: AppTheme.muted)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Revient à LoginScreen
                      },
                      child: const Text("Se connecter",
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
      errorStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
      errorMaxLines: 3,
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
