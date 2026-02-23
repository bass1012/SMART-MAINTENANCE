import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/support_fab_wrapper.dart';
import 'complaint_detail_screen.dart';
import '../../utils/snackbar_helper.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Complaint> _complaints = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final complaints = await _apiService.getCustomerComplaints();
      if (mounted) {
        setState(() {
          _complaints = complaints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      alignLeft: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Réclamations'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddComplaintDialog,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddComplaintDialog,
          child: const Icon(Icons.add),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/Maintenancier_SMART_Maintenance_two.png'),
              fit: BoxFit.cover,
              opacity: 0.4,
            ),
          ),
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _error != null
                  ? Center(child: Text('Erreur: $_error'))
                  : _complaints.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _complaints.length,
                          itemBuilder: (context, index) {
                            final complaint = _complaints[index];
                            return _buildComplaintCard(complaint);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: const Color(0xFF0a543d).withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune réclamation trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur le bouton + pour créer une nouvelle réclamation',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _getStatusColor(complaint.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  complaint.reference,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatStatus(complaint.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (complaint.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                complaint.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (complaint.relatedTo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Lié à: ${_formatRelatedTo(complaint.relatedTo!)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Créé le ${dateFormat.format(complaint.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ComplaintDetailScreen(complaint: complaint),
                      ),
                    );
                  },
                  child: const Text('VOIR PLUS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddComplaintDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedRelatedTo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec icône gradient
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.report_problem_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nouvelle Réclamation',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    'Titre *',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: titleController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ex: Problème avec le service',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0a543d), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.title_outlined,
                            color: Color(0xFF0a543d)),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description *',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre réclamation en détail',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0a543d), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Concerne
                  Text(
                    'Concerne (optionnel)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedRelatedTo,
                      isExpanded: true,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Sélectionnez une catégorie',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0a543d), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.category_outlined,
                            color: Color(0xFF0a543d), size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Aucun',
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'service',
                          child: Text('Service',
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'product',
                          child: Text('Produit',
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'billing',
                          child: Text('Facturation',
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Autre',
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedRelatedTo = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0a543d),
                              Color(0xFF0d6b4d),
                              Color(0xFF0f7d59)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0a543d).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            final description =
                                descriptionController.text.trim();

                            if (title.isEmpty || description.isEmpty) {
                              SnackBarHelper.showWarning(
                                context,
                                'Veuillez remplir tous les champs obligatoires',
                              );
                              return;
                            }

                            Navigator.pop(context);
                            await _createComplaint(title, description, 'medium',
                                selectedRelatedTo);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Créer',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createComplaint(
    String title,
    String description,
    String priority,
    String? relatedTo,
  ) async {
    try {
      setState(() => _isLoading = true);

      final complaint = Complaint(
        id: '',
        reference: '',
        title: title,
        description: description,
        status: 'open',
        priority: priority,
        relatedTo: relatedTo,
        createdAt: DateTime.now(),
      );

      await _apiService.createComplaint(complaint);

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Réclamation créée avec succès',
            emoji: '✓');
        _loadComplaints();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatPriority(String priority) {
    switch (priority) {
      case 'low':
        return 'Basse';
      case 'medium':
        return 'Moyenne';
      case 'high':
        return 'Haute';
      case 'critical':
        return 'Critique';
      default:
        return priority;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'open':
        return 'Ouverte';
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolue';
      case 'rejected':
        return 'Rejetée';
      default:
        return status;
    }
  }

  String _formatRelatedTo(String relatedTo) {
    switch (relatedTo) {
      case 'service':
        return 'Service';
      case 'product':
        return 'Produit';
      case 'billing':
        return 'Facturation';
      default:
        return 'Autre';
    }
  }
}
