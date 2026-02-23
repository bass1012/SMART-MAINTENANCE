import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  bool _isPhone = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final contact = _contactController.text.trim();
      _isPhone = !contact.contains('@');

      await api.requestResetCode(contact);

      if (mounted) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });

        SnackBarHelper.showSuccess(
          context,
          _isPhone
              ? 'Un code de réinitialisation a été envoyé par SMS au $contact'
              : 'Un code de réinitialisation a été envoyé à $contact',
          emoji: _isPhone ? '📱' : '✉️',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        SnackBarHelper.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                const AssetImage('assets/images/image_smart_maintenance.jpeg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0a543d).withOpacity(0.7),
                const Color(0xFF0d6b4d).withOpacity(0.6),
                const Color(0xFF0f7d59).withOpacity(0.5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // AppBar personnalisé
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu principal
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icône
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _codeSent
                                  ? Icons.check_circle_outline
                                  : Icons.lock_reset,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Titre
                          Text(
                            _codeSent
                                ? 'Code envoyé !'
                                : 'Mot de passe oublié ?',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            _codeSent
                                ? _isPhone
                                    ? 'Vérifiez vos SMS. Vous avez reçu un code à 6 chiffres pour réinitialiser votre mot de passe.'
                                    : 'Vérifiez votre boîte mail. Vous avez reçu un code à 6 chiffres pour réinitialiser votre mot de passe.'
                                : 'Entrez votre email ou numéro de téléphone et nous vous enverrons un code à 6 chiffres pour réinitialiser votre mot de passe.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Carte de formulaire
                          if (!_codeSent)
                            Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.98),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Champ Contact (email ou téléphone)
                                          TextFormField(
                                            controller: _contactController,
                                            keyboardType: TextInputType.text,
                                            style: GoogleFonts.poppins(
                                                fontSize: 15),
                                            decoration: InputDecoration(
                                              labelText: 'Email ou téléphone',
                                              hintText:
                                                  'email@exemple.com ou 0709822377',
                                              labelStyle: GoogleFonts.poppins(
                                                color: const Color(0xFF0a543d)
                                                    .withOpacity(0.7),
                                              ),
                                              prefixIcon: Container(
                                                margin:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0a543d)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.person_outline,
                                                  color: Color(0xFF0a543d),
                                                  size: 20,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey.shade50,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF0a543d),
                                                  width: 2,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Entrez votre email ou téléphone';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 24),

                                          // Bouton d'envoi
                                          SizedBox(
                                            height: 56,
                                            child: _isLoading
                                                ? Center(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF0a543d)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      child:
                                                          const CircularProgressIndicator(
                                                        color:
                                                            Color(0xFF0a543d),
                                                        strokeWidth: 3,
                                                      ),
                                                    ),
                                                  )
                                                : ElevatedButton(
                                                    onPressed: _resetPassword,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      elevation: 0,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      shadowColor:
                                                          Colors.transparent,
                                                      padding: EdgeInsets.zero,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                    ),
                                                    child: Ink(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                          colors: [
                                                            Color(0xFF0a543d),
                                                            Color(0xFF0d6b4d),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFF0a543d)
                                                                .withOpacity(
                                                                    0.4),
                                                            blurRadius: 12,
                                                            offset:
                                                                const Offset(
                                                                    0, 6),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Container(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          'Envoyer le code',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Bouton retour après envoi
                          if (_codeSent) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 250,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Retour à la connexion',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 250,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/reset-password-code',
                                    arguments: _contactController.text.trim(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Color(0xFF0a543d),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "J'ai reçu le code",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }
}
