import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/models/user_model.dart';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/utils/snackbar_helper.dart';

class ContactFormBottomSheet extends StatefulWidget {
  final UserModel? user;
  final Future<bool> Function(Map<String, dynamic> payload) onSubmit;

  const ContactFormBottomSheet({
    super.key,
    required this.user,
    required this.onSubmit,
  });

  /// Helper statique pour ouvrir facilement la modal depuis n'importe quel écran
  static void show(BuildContext context, {UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return ContactFormBottomSheet(
          user: user,
          onSubmit: (payload) async {
            try {
              final apiService = Provider.of<BaseApiService>(context, listen: false);
              final response = await apiService.post('/api/contact-requests', body: payload);
              if (response.statusCode == 200 || response.statusCode == 201) {
                if (context.mounted) {
                  SnackBarHelper.showSuccess(
                    context,
                    'Votre demande de rappel a été enregistrée',
                    emoji: '📞',
                  );
                }
                return true;
              } else {
                final errorData = jsonDecode(response.body);
                if (context.mounted) {
                  SnackBarHelper.showError(
                    context,
                    errorData['error'] ?? 'Erreur lors de l\'envoi de la demande',
                  );
                }
                return false;
              }
            } catch (e) {
              if (context.mounted) {
                SnackBarHelper.showError(
                  context,
                  'Une erreur est survenue: $e',
                );
              }
              return false;
            }
          },
        );
      },
    );
  }

  @override
  State<ContactFormBottomSheet> createState() => _ContactFormBottomSheetState();
}

class _ContactFormBottomSheetState extends State<ContactFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;

  String _selectedMotive = 'entretien';
  String _preferredChannel = 'phone';
  String _preferredTime = 'morning';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.user != null
            ? '${widget.user!.firstName} ${widget.user!.lastName}'
            : '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: true,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a543d).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF0a543d),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Demande de rappel',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0a543d),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Nos bureaux sont fermés. Laissez vos coordonnées pour être rappelé dès réouverture.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Informations personnelles',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom et prénoms *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez saisir votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez saisir votre numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Adresse e-mail (optionnelle)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Motif du contact',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMotive,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.help_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'entretien', child: Text('Entretien')),
                  DropdownMenuItem(value: 'reclamation', child: Text('Réclamation')),
                  DropdownMenuItem(
                      value: 'information_commerciale',
                      child: Text('Information commerciale')),
                  DropdownMenuItem(value: 'autre', child: Text('Autres')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMotive = val);
                  }
                },
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '⚠️ Pour les installations et dépannages, commandez un diagnostic.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0a543d),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Détails de la demande',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description détaillée du problème ou de la question *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez décrire votre demande';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Préférences de rappel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Canal de rappel souhaité',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChoiceChip('Téléphone', 'phone', _preferredChannel, (val) {
                    setState(() => _preferredChannel = val);
                  }),
                  _buildChoiceChip('E-mail', 'email', _preferredChannel, (val) {
                    setState(() => _preferredChannel = val);
                  }),
                  _buildChoiceChip('Chat', 'chat', _preferredChannel, (val) {
                    setState(() => _preferredChannel = val);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Plage horaire idéale',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChoiceChip('Matin (8h - 12h)', 'morning', _preferredTime, (val) {
                    setState(() => _preferredTime = val);
                  }),
                  _buildChoiceChip('Après-midi (13h30 - 17h30)', 'afternoon', _preferredTime, (val) {
                    setState(() => _preferredTime = val);
                  }),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0a543d),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Envoyer ma demande',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildChoiceChip(
      String label, String value, String currentValue, ValueChanged<String> onChanged) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onChanged(value);
      },
      selectedColor: const Color(0xFF0a543d).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF0a543d),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0a543d) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'motive': _selectedMotive,
      'message': _messageController.text.trim(),
      'preferredChannel': _preferredChannel,
      'preferredTime': _preferredTime,
    };

    final success = await widget.onSubmit(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }
}
