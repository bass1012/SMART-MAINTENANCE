import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final int userId;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.userId,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _getCode();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Veuillez entrer les 6 chiffres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.verifyEmailCode(widget.email, code);

      if (response['success']) {
        if (mounted) {
          // Afficher message de succès
          final successMessage = widget.email.contains('@')
              ? '✅ Email vérifié avec succès !'
              : '✅ Numéro vérifié avec succès !';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Se connecter automatiquement et rediriger vers le dashboard
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            // Le compte est maintenant actif, on peut utiliser les tokens de l'inscription
            final apiService = ApiService();

            debugPrint('🔄 Récupération du profil utilisateur...');
            // Récupérer les données utilisateur avec le token existant
            try {
              final userResponse = await apiService.getProfile();
              debugPrint('📊 Réponse profil: ${userResponse['success']}');

              if (userResponse['success'] == true &&
                  userResponse['data'] != null &&
                  userResponse['data']['user'] != null) {
                await apiService.saveUserData(userResponse['data']['user']);
                debugPrint(
                    '✅ Données utilisateur sauvegardées après vérification');

                // Attendre un peu pour que l'UI se mette à jour
                await Future.delayed(const Duration(milliseconds: 300));

                // Rediriger vers le dashboard client
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/client', (route) => false);
                }
              } else {
                debugPrint(
                    '⚠️ Échec récupération profil, redirection vers login');
                // Si échec de récupération du profil, rediriger vers le login
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            } catch (e) {
              debugPrint('❌ Erreur récupération profil: $e');
              // En cas d'erreur, rediriger vers le login
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            }
          }
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Code invalide';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion. Veuillez réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode({String method = 'sms'}) async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.resendVerificationCode(
        widget.email,
        verificationMethod: method,
      );

      if (response['success']) {
        if (mounted) {
          final usedMethod = response['verificationMethod'] ?? method;
          final message = usedMethod == 'sms'
              ? '✅ Code renvoyé par SMS !'
              : '✅ Code renvoyé par email !';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
          _startResendCountdown();

          // Effacer les champs
          for (var controller in _codeControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erreur lors de l\'envoi';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion. Veuillez réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Widget _buildCodeInput(int index) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        // Activer l'auto-fill SMS uniquement sur le premier champ
        autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0a543d), width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _CodeInputFormatter(index, _handlePastedCode),
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Auto-focus next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last digit entered, hide keyboard
              _focusNodes[index].unfocus();
              // Auto-verify
              _verifyCode();
            }
          } else {
            // Backspace: focus previous field
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {
            _errorMessage = null;
          });
        },
      ),
    );
  }
  
  /// Gérer le collage automatique du code SMS (auto-fill iOS/Android)
  void _handlePastedCode(String pastedCode) {
    // Nettoyer le code (garder uniquement les chiffres)
    final digits = pastedCode.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Remplir les champs avec les chiffres disponibles
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _codeControllers[i].text = digits[i];
    }
    
    // Focus sur le dernier champ rempli ou le premier vide
    final filledCount = digits.length.clamp(0, 6);
    if (filledCount >= 6) {
      // Code complet, lancer la vérification
      _focusNodes[5].unfocus();
      _verifyCode();
    } else if (filledCount > 0) {
      _focusNodes[filledCount].requestFocus();
    }
    
    setState(() {
      _errorMessage = null;
    });
  }

  // Afficher le choix de méthode de renvoi
  void _showResendOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Renvoyer le code par :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Option SMS
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a543d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  color: Color(0xFF0a543d),
                ),
              ),
              title: const Text('SMS'),
              subtitle: Text(
                widget.email.contains('@')
                    ? 'Numéro de téléphone'
                    : widget.email,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _resendCode(method: 'sms');
              },
            ),

            const Divider(),

            // Option Email
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Colors.blue,
                ),
              ),
              title: const Text('Email'),
              subtitle: Text(
                widget.email.contains('@') ? widget.email : 'Adresse email',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _resendCode(method: 'email');
              },
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bool isEmail = widget.email.contains('@');
        // Afficher une confirmation avant de quitter
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter la vérification ?'),
            content: Text(
              'Votre compte n\'est pas encore vérifié. Vous pourrez revenir vérifier ${isEmail ? 'votre email' : 'votre numéro'} en vous connectant.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Rester'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quitter'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.email.contains('@')
              ? 'Vérification Email'
              : 'Vérification SMS'),
          backgroundColor: const Color(0xFF0a543d),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Icon
                Icon(
                  widget.email.contains('@')
                      ? Icons.email_outlined
                      : Icons.sms_outlined,
                  size: 80,
                  color: const Color(0xFF0a543d),
                ),

                const SizedBox(height: 30),

                // Title
                Text(
                  widget.email.contains('@')
                      ? 'Vérifiez votre email'
                      : 'Vérifiez votre numéro',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Nous avons envoyé un code de vérification ${widget.email.contains('@') ? 'à' : 'au'}\n${widget.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Code inputs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => _buildCodeInput(index),
                  ),
                ),

                const SizedBox(height: 20),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a543d),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 20),

                // Resend code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Vous n\'avez pas reçu le code ? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    if (_resendCountdown > 0)
                      Text(
                        'Renvoyer dans ${_resendCountdown}s',
                        style: const TextStyle(color: Colors.grey),
                      )
                    else
                      TextButton(
                        onPressed: _isResending
                            ? null
                            : () => _resendCode(method: 'sms'),
                        child: _isResending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Renvoyer',
                                style: TextStyle(
                                  color: Color(0xFF0a543d),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                  ],
                ),

                // Lien "Autre option" en dessous
                if (_resendCountdown == 0)
                  TextButton(
                    onPressed: _isResending ? null : _showResendOptions,
                    child: const Text(
                      'Autre option (Email)',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // Back to login
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Retour à la connexion',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formatter personnalisé pour intercepter le collage du code SMS complet
class _CodeInputFormatter extends TextInputFormatter {
  final int index;
  final Function(String) onPastedCode;
  
  _CodeInputFormatter(this.index, this.onPastedCode);
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    
    // Si plusieurs chiffres sont collés (auto-fill SMS)
    if (newText.length > 1) {
      // Appeler le callback pour distribuer le code dans tous les champs
      // On utilise addPostFrameCallback pour éviter les problèmes de setState pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPastedCode(newText);
      });
      // Garder seulement le premier caractère pour ce champ
      return TextEditingValue(
        text: newText.isNotEmpty ? newText[0] : '',
        selection: const TextSelection.collapsed(offset: 1),
      );
    }
    
    // Comportement normal: garder un seul caractère
    if (newText.length <= 1) {
      return newValue;
    }
    
    return TextEditingValue(
      text: newText[0],
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}
