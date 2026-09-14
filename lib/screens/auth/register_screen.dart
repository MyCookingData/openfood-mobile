import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // Default 18 years
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _signUp() async {
    // Vérification via FormState
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (_selectedDateOfBirth == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Veuillez sélectionner votre date de naissance.",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.redL),
        );
      }
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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = "Erreur de création de compte.";
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('email-already-in-use')) {
          errorMsg = "Cette adresse email est déjà utilisée.";
        } else if (errorStr.contains('weak-password')) {
          errorMsg = "Le mot de passe utilisé est trop faible.";
        } else if (errorStr.contains('invalid-email')) {
          errorMsg = "L'adresse email est invalide.";
        } else {
          errorMsg = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("⛔ $errorMsg",
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.redL),
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
                _buildInputLabel("Date de naissance"),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            color: AppTheme.muted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDateOfBirth == null
                              ? "Sélectionner une date"
                              : "${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.year}",
                          style: TextStyle(
                              color: _selectedDateOfBirth == null
                                  ? AppTheme.muted
                                  : AppTheme.cream,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
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
                    hint: "Min. 6 caractères",
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
                    if (value.length < 6) {
                      return "Doit faire au moins 6 caractères";
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
