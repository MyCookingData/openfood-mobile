import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/location_provider.dart';
import '../providers/cart_provider.dart';
import '../services/notification_service.dart';
import 'address_picker_screen.dart';
import 'auth/login_screen.dart' as auth_screen;
import 'legal/legal_viewer_screen.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_feedback.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const ProfileScreen({super.key, this.onBackToHome});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  bool _isPhoneValidated = false;
  bool _isSendingOtp = false;
  bool _isSendingEmail = false;

  String? _userDisplayName;
  String? _userFirstName;
  String? _userLastName;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    String? phone = prefs.getString('phoneNumber');
    String? fName = prefs.getString('firstName');
    String? lName = prefs.getString('lastName');
    String? dName = prefs.getString('displayName');
    bool isPhoneVal = prefs.getBool('isPhoneValidated') ?? false;

    // Si non présent dans SharedPreferences et utilisateur connecté, interroger Firestore
    if (user != null && (phone == null || phone.isEmpty || fName == null || fName.isEmpty)) {
      final data = await _authService.getUserProfile(user.uid);
      if (data != null) {
        phone = data['phone'] ?? phone;
        fName = data['firstName'] ?? fName;
        lName = data['lastName'] ?? lName;
        dName = data['displayName'] ?? dName;
        if (data['isPhoneVerified'] == true) isPhoneVal = true;

        if (phone != null) await prefs.setString('phoneNumber', phone);
        if (fName != null) await prefs.setString('firstName', fName);
        if (lName != null) await prefs.setString('lastName', lName);
        if (dName != null) await prefs.setString('displayName', dName);
        if (isPhoneVal) await prefs.setBool('isPhoneValidated', true);
      }
    }

    if (mounted) {
      setState(() {
        _isPhoneValidated = isPhoneVal;
        _userFirstName = fName;
        _userLastName = lName;
        _userDisplayName = dName;
        if (phone != null && phone.isNotEmpty) {
          _phoneController.text = phone;
        } else if (_phoneController.text.isEmpty) {
          _phoneController.text = "+596 ";
        }
      });
    }
  }

  Future<void> _validatePhone() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty || rawPhone == "+596" || rawPhone.length < 8) {
      UiFeedback.showError(
        context,
        "Veuillez renseigner un numéro de mobile valide.",
      );
      return;
    }

    final formattedPhone = AuthService.formatPhoneNumber(rawPhone);

    setState(() => _isSendingOtp = true);

    try {
      await _authService.sendOTP(formattedPhone);
      if (mounted) {
        setState(() => _isSendingOtp = false);
        _showOtpVerificationDialog(formattedPhone);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  void _showOtpVerificationDialog(String formattedPhone) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.surface3),
            ),
            title: const Row(
              children: [
                Icon(Icons.sms_rounded, color: AppTheme.greenXl),
                SizedBox(width: 10),
                Text("Validation Mobile", style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Un code de validation à 6 chiffres a été envoyé par SMS au numéro suivant :",
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedPhone,
                  style: const TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.cream, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "000000",
                    hintStyle: TextStyle(color: AppTheme.muted2.withValues(alpha: 0.4), letterSpacing: 8),
                    filled: true,
                    fillColor: AppTheme.surface3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(ctx),
                child: const Text("Annuler", style: TextStyle(color: AppTheme.muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenXl,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isVerifying
                    ? null
                    : () async {
                        final code = otpController.text.trim();
                        if (code.length != 6) {
                          UiFeedback.showError(
                            context,
                            "Veuillez saisir les 6 chiffres du code SMS.",
                          );
                          return;
                        }

                        setDialogState(() => isVerifying = true);

                        try {
                          await _authService.verifyOTP(code, phoneNumber: formattedPhone);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isPhoneValidated', true);
                          await prefs.setString('phoneNumber', formattedPhone);

                          if (mounted) {
                            setState(() {
                              _isPhoneValidated = true;
                              _phoneController.text = formattedPhone;
                            });
                            Navigator.pop(ctx);
                            UiFeedback.showSuccess(
                              context,
                              "Numéro de mobile validé avec succès !",
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isVerifying = false);
                          if (mounted) {
                            UiFeedback.showError(context, "Code invalide : $e");
                          }
                        }
                      },
                child: isVerifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("Valider", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text("Mon Compte",
            style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                color: AppTheme.cream)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_downward,
                color: AppTheme.cream),
            onPressed: () {
              if (widget.onBackToHome != null) {
                widget.onBackToHome!();
              } else {
                Navigator.of(context).pop();
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header Profil ---
            StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;

                  // Calcul de l'initiale de l'avatar
                  String initial = "C";
                  if (_userFirstName != null && _userFirstName!.trim().isNotEmpty) {
                    initial = _userFirstName!.trim().substring(0, 1).toUpperCase();
                  } else if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
                    initial = user.displayName!.trim().substring(0, 1).toUpperCase();
                  }

                  // Calcul du nom d'affichage complet
                  String displayedName = "Client";
                  if (_userFirstName != null && _userFirstName!.trim().isNotEmpty) {
                    displayedName = _userLastName != null && _userLastName!.trim().isNotEmpty
                        ? "${_userFirstName!.trim()} ${_userLastName!.trim()}"
                        : _userFirstName!.trim();
                  } else if (_userDisplayName != null && _userDisplayName!.trim().isNotEmpty) {
                    displayedName = _userDisplayName!.trim();
                  } else if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
                    displayedName = user.displayName!.trim();
                  } else if (user?.email != null) {
                    displayedName = user!.email!.split('@').first;
                  }

                  return Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface3,
                          border: Border.all(color: AppTheme.greenXl, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.cream,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayedName,
                              style: const TextStyle(
                                  color: AppTheme.cream,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.email ?? "Non connecté",
                              style: TextStyle(
                                  color: AppTheme.green.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.1);
                }),

            // --- Carte Statut Validation E-mail ---
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user == null) return const SizedBox.shrink();

                final isVerified = user.emailVerified;

                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF1B5E20).withOpacity(0.14)
                        : const Color(0xFFE65100).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isVerified ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isVerified ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                        color: isVerified ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVerified ? "Adresse e-mail validée" : "E-mail en attente de validation",
                              style: TextStyle(
                                color: isVerified ? Colors.white : const Color(0xFFFFCC80),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isVerified
                                  ? (user.email ?? "")
                                  : "Vérifiez votre boîte de réception et spams (${user.email}).",
                              style: TextStyle(
                                color: isVerified ? AppTheme.muted : AppTheme.cream.withOpacity(0.9),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isVerified) ...[
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(60, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isSendingEmail
                              ? null
                              : () async {
                                  setState(() => _isSendingEmail = true);
                                  try {
                                    await _authService.sendEmailVerification();
                                    if (context.mounted) {
                                      UiFeedback.showSuccess(
                                        context,
                                        "E-mail de confirmation renvoyé à ${user.email} ! Vérifiez également votre dossier Spams/Courriers indésirables.",
                                        duration: const Duration(seconds: 7),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      UiFeedback.showError(context, e.toString());
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isSendingEmail = false);
                                  }
                                },
                          child: _isSendingEmail
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  "Renvoyer",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppTheme.cream, size: 20),
                          tooltip: "Actualiser",
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final verified = await _authService.reloadAndCheckEmailVerified();
                            if (context.mounted) {
                              if (verified) {
                                setState(() {});
                                UiFeedback.showSuccess(context, "E-mail validé avec succès !");
                              } else {
                                UiFeedback.showInfo(context, "E-mail non encore validé. Cliquez sur le lien dans l'e-mail reçu.");
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // --- Section Localisation ---
            const Text("CARNET D'ADRESSES",
                    style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2))
                .animate()
                .fade(delay: 100.ms),
            const SizedBox(height: 12),

            Consumer<LocationProvider>(builder: (context, loc, _) {
              return Column(
                children: [
                  if (loc.addresses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border2)),
                      child: const Text("Aucune adresse enregistrée",
                          style: TextStyle(color: AppTheme.muted),
                          textAlign: TextAlign.center),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: loc.addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = loc.addresses[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border2),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                                backgroundColor: AppTheme.surface3,
                                child: Icon(Icons.location_on,
                                    color: AppTheme.muted, size: 20)),
                            title: Text(item.label,
                                style: const TextStyle(
                                    color: AppTheme.cream,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(item.addressName,
                                style: const TextStyle(
                                    color: AppTheme.muted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.redL),
                              onPressed: () => loc.removeAddress(item.id),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cream,
                        side: BorderSide(color: AppTheme.border2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, color: AppTheme.greenL),
                      label: const Text("Ajouter une nouvelle adresse"),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddressPickerScreen())),
                    ),
                  ),
                ],
              );
            })
                .animate()
                .fade(duration: 400.ms, delay: 150.ms)
                .slideX(begin: 0.05),

            const SizedBox(height: 32),

            StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Section Téléphone ---
                        const Text("SÉCURITÉ & CONTACT",
                                style: TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2))
                            .animate()
                            .fade(delay: 200.ms),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border2)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Numéro de téléphone",
                                      style: TextStyle(
                                          color: AppTheme.cream, fontSize: 14)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isPhoneValidated
                                          ? AppTheme.green
                                              .withValues(alpha: 0.2)
                                          : AppTheme.redL
                                              .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _isPhoneValidated
                                          ? "Vérifié"
                                          : "Non vérifié",
                                      style: TextStyle(
                                          color: _isPhoneValidated
                                              ? AppTheme.green
                                              : AppTheme.redL,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                          color: AppTheme.cream,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppTheme.surface3,
                                        prefixIcon: const Icon(Icons.phone,
                                            color: AppTheme.muted2, size: 20),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (!_isPhoneValidated)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surface3,
                                    foregroundColor: AppTheme.cream,
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isSendingOtp ? null : _validatePhone,
                                  child: _isSendingOtp
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.greenXl,
                                          ),
                                        )
                                      : const Text(
                                          "Valider ce numéro par SMS",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        )
                            .animate()
                            .fade(duration: 400.ms, delay: 250.ms)
                            .slideX(begin: 0.05),

                        const SizedBox(height: 32),

                        // --- Bouton Déconnexion ---
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.redL.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.redL,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                  color: AppTheme.redL, width: 2),
                            ),
                          ),
                          onPressed: () async {
                            Provider.of<CartProvider>(context, listen: false)
                                .clearCart();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('isPhoneValidated');
                            await prefs.remove('phoneNumber');
                            NotificationService.instance.stopListening();

                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true)
                                  .popUntil((route) => route.isFirst);
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text("Déconnexion",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ).animate().fade(delay: 300.ms),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        // --- Bouton Connexion ---
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.greenXl.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.greenXl,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                  color: AppTheme.greenXl, width: 2),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const auth_screen.LoginScreen()));
                          },
                          icon: const Icon(Icons.login),
                          label: const Text("Se connecter / S'inscrire",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ).animate().fade().slideY(begin: 0.1),
                      ],
                    );
                  }
                }),

            const SizedBox(height: 32),

            // --- Section Informations Légales & CGU ---
            const Text("⚖️ INFORMATIONS LÉGALES & CGU",
                    style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2))
                .animate()
                .fade(delay: 280.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border2),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.surface3,
                      child: Icon(Icons.gavel_rounded, color: AppTheme.greenXl, size: 20),
                    ),
                    title: const Text("Conditions Générales (CGU / CGV)",
                        style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text("Commandes, livraisons, intermédiation N2D",
                        style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.muted2, size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LegalViewerScreen(initialTabIndex: 0)),
                    ),
                  ),
                  const Divider(color: AppTheme.surface3, height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.surface3,
                      child: Icon(Icons.assignment_return_rounded, color: AppTheme.gold, size: 20),
                    ),
                    title: const Text("Politique de Remboursement",
                        style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text("Indisponibilités, réclamations sous 24h",
                        style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.muted2, size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LegalViewerScreen(initialTabIndex: 1)),
                    ),
                  ),
                  const Divider(color: AppTheme.surface3, height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.surface3,
                      child: Icon(Icons.security_rounded, color: AppTheme.greenXl, size: 20),
                    ),
                    title: const Text("Mentions Légales & RGPD",
                        style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text("N2D NEW DELIVERY DRIVER SAS • RCS 992 130 476",
                        style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.muted2, size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LegalViewerScreen(initialTabIndex: 3)),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 28),

            // --- Signature & Attribution Cooking Data ---
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Développé par Cooking Data",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "Créateur de solutions informatiques sur-mesure",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Besoin d'une application mobile, d'un tableau de bord ou d'une IA pour votre entreprise ?",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "🌐 Visitez cookingdata.fr • Martinique 🇲🇶",
                    style: TextStyle(
                      color: AppTheme.greenXl,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 400.ms),

            const SizedBox(height: 120), // Espace pour BottomNavBar
          ],
        ),
      ),
    );
  }
}
