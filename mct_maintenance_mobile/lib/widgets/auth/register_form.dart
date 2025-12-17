import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Champs supplémentaires (CustomerForm)
  String? _companyType;
  String? _gender;
  String _country = 'Côte d\'Ivoire';
  String? _city;
  String? _commune;

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // Afficher un indicateur de chargement
      if (mounted) {
        SnackBarHelper.showLoading(context, 'Création du compte en cours...',
            duration: const Duration(seconds: 10));
      }

      final api = ApiService();
      // Appel à l'API d'inscription avec tous les champs du CustomerForm
      final response = await api.register({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'company_name': _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : null,
        'company_type': _companyType,
        'gender': _gender,
        'country': _country,
        'city': _city,
        'commune': _commune,
        'password': _passwordController.text,
        'role': 'customer',
      });

      if (mounted) {
        // Cacher le snackbar de chargement
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Sauvegarder le token et les données utilisateur
        if (response['data'] != null) {
          final data = response['data'];

          // Sauvegarder le token d'authentification
          if (data['accessToken'] != null) {
            await api.setAuthToken(data['accessToken']);
            debugPrint('✅ Token sauvegardé après inscription');
          }

          // Sauvegarder les données utilisateur
          if (data['user'] != null) {
            await api.saveUserData(data['user']);
            debugPrint('✅ Données utilisateur sauvegardées');
          }
        }

        // Afficher un message de succès
        SnackBarHelper.showSuccess(
            context, 'Bienvenue ! Votre compte a été créé avec succès',
            emoji: '🎉', duration: const Duration(seconds: 2));

        // Rediriger directement vers le dashboard client
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/client');
        }
      }
    } on FormatException {
      _showError('Format de réponse invalide du serveur');
    } on Exception catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      _showError('Une erreur inattendue est survenue');
      debugPrint('Erreur lors de l\'inscription: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Méthode utilitaire pour afficher les erreurs
  void _showError(String message) {
    if (mounted) {
      SnackBarHelper.hide(context);
      SnackBarHelper.showError(
        context,
        'Erreur: $message',
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => SnackBarHelper.hide(context),
        ),
      );
    }
  }

  // Helper pour créer un dropdown moderne
  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF0a543d).withOpacity(0.7),
          fontSize: 13,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0a543d).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0a543d), size: 18),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0a543d), width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // Helper pour créer un champ moderne
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF0a543d).withOpacity(0.7),
          fontSize: 13,
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0a543d).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0a543d), size: 18),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0a543d), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 11),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Titre du formulaire
            Text(
              'Informations personnelles',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0a543d),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Champ Prénom
            _buildModernTextField(
              controller: _firstNameController,
              label: 'Prénom',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                if (value.length < 2) {
                  return 'Le prénom doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Champ Nom
            _buildModernTextField(
              controller: _lastNameController,
              label: 'Nom',
              icon: Icons.person,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                if (value.length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Champ Email
            _buildModernTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              hintText: 'exemple@domaine.com',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre adresse email';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Veuillez entrer une adresse email valide';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Champ Entreprise (optionnel)
            _buildModernTextField(
              controller: _companyNameController,
              label: 'Entreprise (optionnel)',
              icon: Icons.business_outlined,
              textCapitalization: TextCapitalization.words,
              hintText: 'Nom de votre entreprise',
            ),

            const SizedBox(height: 14),

            // Champ Type d'entreprise
            _buildModernDropdown(
              label: 'Type d\'entreprise (optionnel)',
              icon: Icons.category_outlined,
              value: _companyType,
              items: [
                DropdownMenuItem(
                    value: 'particulier',
                    child: Text('Particulier',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'sante',
                    child: Text('Santé',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'commerce',
                    child: Text('Commerce',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'entreprise',
                    child: Text('Entreprise',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'administration',
                    child: Text('Administration',
                        style: GoogleFonts.poppins(fontSize: 14))),
              ],
              onChanged: (value) => setState(() => _companyType = value),
            ),

            const SizedBox(height: 14),

            // Champ Sexe
            _buildModernDropdown(
              label: 'Sexe (optionnel)',
              icon: Icons.wc_outlined,
              value: _gender,
              items: [
                DropdownMenuItem(
                    value: 'homme',
                    child: Text('Homme',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'femme',
                    child: Text('Femme',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'autre',
                    child: Text('Autre',
                        style: GoogleFonts.poppins(fontSize: 14))),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),

            const SizedBox(height: 14),

            // Champ Téléphone
            _buildModernTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              hintText: '+225 XX XX XX XX XX',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                final phoneRegex = RegExp(r'^[+]?[0-9]{8,15}$');
                final cleanedPhone = value.replaceAll(RegExp(r'[\s-]'), '');
                if (!phoneRegex.hasMatch(cleanedPhone)) {
                  return 'Numéro de téléphone invalide';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Champ Pays
            _buildModernDropdown(
              label: 'Pays',
              icon: Icons.flag_outlined,
              value: _country,
              items: [
                DropdownMenuItem(
                    value: 'Côte d\'Ivoire',
                    child: Text('Côte d\'Ivoire',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'Mali',
                    child:
                        Text('Mali', style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'Burkina Faso',
                    child: Text('Burkina Faso',
                        style: GoogleFonts.poppins(fontSize: 14))),
              ],
              onChanged: (value) => setState(() {
                _country = value!;
                _city = null;
                _commune = null;
              }),
            ),

            const SizedBox(height: 14),

            // Champ Ville
            _buildModernDropdown(
              label: 'Ville (optionnel)',
              icon: Icons.location_city_outlined,
              value: _city,
              items: [
                DropdownMenuItem(
                    value: 'Abidjan',
                    child: Text('Abidjan',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'Bouaké',
                    child: Text('Bouaké',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'Daloa',
                    child: Text('Daloa',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'Yamoussoukro',
                    child: Text('Yamoussoukro',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'San-Pédro',
                    child: Text('San-Pédro',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'Korhogo',
                    child: Text('Korhogo',
                        style: GoogleFonts.poppins(fontSize: 14))),
                DropdownMenuItem(
                    value: 'Man',
                    child:
                        Text('Man', style: GoogleFonts.poppins(fontSize: 14))),
              ],
              onChanged: (value) => setState(() {
                _city = value;
                if (value != 'Abidjan') _commune = null;
              }),
            ),

            const SizedBox(height: 14),

            // Champ Commune (seulement si Abidjan)
            if (_city == 'Abidjan')
              _buildModernDropdown(
                label: 'Commune',
                icon: Icons.location_on_outlined,
                value: _commune,
                items: [
                  DropdownMenuItem(
                      value: 'Abobo',
                      child: Text('Abobo',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Adjamé',
                      child: Text('Adjamé',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Attécoubé',
                      child: Text('Attécoubé',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Cocody',
                      child: Text('Cocody',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Koumassi',
                      child: Text('Koumassi',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Marcory',
                      child: Text('Marcory',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Plateau',
                      child: Text('Plateau',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Port-Bouët',
                      child: Text('Port-Bouët',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Treichville',
                      child: Text('Treichville',
                          style: GoogleFonts.poppins(fontSize: 14))),
                  DropdownMenuItem(
                      value: 'Yopougon',
                      child: Text('Yopougon',
                          style: GoogleFonts.poppins(fontSize: 14))),
                ],
                onChanged: (value) => setState(() => _commune = value),
              ),

            if (_city == 'Abidjan') const SizedBox(height: 14),

            // Champ Mot de passe
            _buildModernTextField(
              controller: _passwordController,
              label: 'Mot de passe',
              icon: Icons.lock_outline,
              obscureText: true,
              hintText: '••••••••',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                if (value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Champ Confirmation mot de passe
            _buildModernTextField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              icon: Icons.lock_outline,
              obscureText: true,
              hintText: '••••••••',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez confirmer votre mot de passe';
                }
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Bouton de soumission
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
                      onPressed: _register,
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
                            'Créer mon compte',
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
            const SizedBox(height: 20),

            // Lien vers la page de connexion
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Déjà un compte ? ',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  InkWell(
                    onTap: _isLoading
                        ? null
                        : () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Connectez-vous',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0a543d),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
