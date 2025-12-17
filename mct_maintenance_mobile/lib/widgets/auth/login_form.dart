import 'dart:io' show SocketException;
import 'dart:async' show TimeoutException;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/fcm_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/test_keys.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier la connexion Internet
    try {
      setState(() => _isLoading = true);

      final api = ApiService();

      // Afficher un indicateur de chargement
      if (mounted) {
        SnackBarHelper.showLoading(context, 'Connexion en cours...',
            duration: const Duration(seconds: 10));
      }

      // Appel à l'API de connexion
      final response = await api.login(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        // Cacher le snackbar de chargement
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Vérifier si la réponse contient des données utilisateur
        if (response['data'] != null && response['data']['user'] != null) {
          final user = response['data']['user'];
          final role = user['role']?.toLowerCase() ?? '';

          // Afficher un message de succès
          SnackBarHelper.showSuccess(context, 'Connexion réussie !',
              emoji: '✅', duration: const Duration(seconds: 2));

          // Initialiser FCM (notifications push)
          try {
            await FCMService().initialize();
            debugPrint('✅ FCM initialisé avec succès après login');

            // Toujours rafraîchir le token après login (même si déjà initialisé)
            await FCMService().refreshToken();
            debugPrint('✅ Token FCM rafraîchi après login');
          } catch (e) {
            debugPrint('⚠️  Erreur initialisation FCM: $e');
            // Continuer même si FCM échoue
          }

          // Rediriger en fonction du rôle (supporter anglais et français)
          if (role.contains('technician') || role.contains('technicien')) {
            Navigator.pushReplacementNamed(context, '/technician');
          } else {
            Navigator.pushReplacementNamed(context, '/client');
          }
        } else {
          // Gérer le cas où les données utilisateur sont manquantes
          throw Exception('Données utilisateur manquantes dans la réponse');
        }
      }
    } on TimeoutException {
      _showError(
          'Le serveur ne répond pas. Vérifiez votre connexion internet.');
    } on SocketException {
      _showError(
          'Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } on FormatException {
      _showError('Erreur de format de données. Veuillez réessayer plus tard.');
    } on Exception catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showError(_getFriendlyErrorMessage(errorMessage));
    } catch (e) {
      _showError('Une erreur inattendue est survenue. Veuillez réessayer.');
      debugPrint('Erreur de connexion: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Méthode pour traduire les erreurs techniques en messages clairs
  String _getFriendlyErrorMessage(String errorMessage) {
    // Nettoyer le message d'erreur
    final cleanMessage = errorMessage.trim();

    // Erreurs d'authentification
    if (cleanMessage.contains('AUTH_ERROR') ||
        cleanMessage.contains('Invalid credentials') ||
        cleanMessage.contains('identifiants invalides')) {
      return 'Email ou mot de passe incorrect. Veuillez vérifier vos identifiants.';
    }

    if (cleanMessage.contains('User not found') ||
        cleanMessage.contains('utilisateur introuvable')) {
      return 'Aucun compte associé à cet email. Veuillez créer un compte.';
    }

    if (cleanMessage.contains('Account is inactive') ||
        cleanMessage.contains('compte inactif')) {
      return 'Votre compte est désactivé. Veuillez contacter le support.';
    }

    if (cleanMessage.contains('Email not verified') ||
        cleanMessage.contains('email non vérifié')) {
      return 'Veuillez vérifier votre email avant de vous connecter.';
    }

    // Erreurs réseau
    if (cleanMessage.contains('Network') ||
        cleanMessage.contains('Connection') ||
        cleanMessage.contains('timeout')) {
      return 'Problème de connexion. Vérifiez votre connexion internet.';
    }

    if (cleanMessage.contains('500') ||
        cleanMessage.contains('Internal Server Error')) {
      return 'Erreur du serveur. Veuillez réessayer dans quelques instants.';
    }

    // Si le message est déjà clair, le retourner
    if (!cleanMessage.contains('ERROR') &&
        !cleanMessage.contains('error') &&
        cleanMessage.length < 100) {
      return cleanMessage;
    }

    // Message générique si aucune correspondance
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  // Méthode utilitaire pour afficher les erreurs
  void _showError(String message) {
    if (mounted) {
      SnackBarHelper.hide(context);
      SnackBarHelper.showError(
        context,
        message,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => SnackBarHelper.hide(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Titre du formulaire
          Text(
            'Connexion',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0a543d),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Champ Email moderne
          TextFormField(
            key: const ValueKey(TestKeys.emailField),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF0a543d).withOpacity(0.7),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF0a543d),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF0a543d),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Entrez votre email' : null,
          ),
          const SizedBox(height: 20),

          // Champ Mot de passe moderne
          TextFormField(
            key: const ValueKey(TestKeys.passwordField),
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF0a543d).withOpacity(0.7),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF0a543d),
                  size: 20,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF0a543d).withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF0a543d),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Entrez votre mot de passe'
                : null,
          ),

          // Lien "Mot de passe oublié"
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: Text(
                'Mot de passe oublié ?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF0a543d),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bouton de connexion avec gradient
          SizedBox(
            height: 56,
            child: _isLoading
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a543d).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF0a543d),
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : ElevatedButton(
                    key: const ValueKey(TestKeys.loginButton),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _login();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0a543d),
                            Color(0xFF0d6b4d),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0a543d).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Se connecter',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Divider avec texte
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OU',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lien de création de compte
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Pas encore de compte ? ',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  'Créer un compte',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0a543d),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
