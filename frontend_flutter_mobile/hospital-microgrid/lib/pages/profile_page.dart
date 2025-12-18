import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hospital_microgrid/services/auth_service.dart';
import 'package:hospital_microgrid/services/establishment_service.dart';
import 'package:hospital_microgrid/pages/comprehensive_results_page.dart';
import 'package:hospital_microgrid/pages/institution_choice_page.dart';
import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/utils/navigation_helper.dart';
import 'package:hospital_microgrid/providers/theme_provider.dart';

/// Page de profil utilisateur avec CRUD sur user et établissements
class ProfilePage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const ProfilePage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserResponse? _user;
  List<EstablishmentResponse> _establishments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0 = Profil, 1 = Établissements

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getCurrentUser();
      final establishments = await EstablishmentService.getUserEstablishments();
      
      setState(() {
        _user = user;
        _establishments = establishments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement : ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCreateEstablishment() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await NavigationHelper.push(
        context,
        InstitutionChoicePage(position: position),
      );
    } catch (_) {
      await NavigationHelper.push(
        context,
        InstitutionChoicePage(
          position: Position(
            latitude: 33.5731,
            longitude: -7.5898,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          ),
        ),
      );
    }

    _loadData();
  }

  Future<void> _editUserProfile() async {
    if (_user == null) return;

    final firstNameController = TextEditingController(text: _user!.firstName);
    final lastNameController = TextEditingController(text: _user!.lastName);
    final emailController = TextEditingController(text: _user!.email);
    final phoneController = TextEditingController(text: _user!.phone ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditUserDialog(
        firstNameController: firstNameController,
        lastNameController: lastNameController,
        emailController: emailController,
        phoneController: phoneController,
      ),
    );

    if (result != null) {
      // TODO: Implémenter l'endpoint de mise à jour utilisateur dans le backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour du profil utilisateur à implémenter dans le backend'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _editEstablishment(EstablishmentResponse establishment) async {
    // TODO: Implémenter la page d'édition d'établissement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Édition d\'établissement à implémenter'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteEstablishment(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'établissement'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "$name" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await EstablishmentService.deleteEstablishment(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Établissement supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? MedicalSolarColors.softGrey : MedicalSolarColors.offWhite,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Header avec onglets
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          MedicalSolarColors.medicalBlue,
                                          MedicalSolarColors.solarGreen,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}',
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _user?.email ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.7)
                                                : MedicalSolarColors.softGrey.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: _editUserProfile,
                                    tooltip: 'Modifier le profil',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Onglets
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTabButton(
                                      'Profil',
                                      0,
                                      Icons.person,
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTabButton(
                                      'Établissements (${_establishments.length})',
                                      1,
                                      Icons.business,
                                      isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Contenu selon l'onglet sélectionné
                        Expanded(
                          child: _selectedTab == 0
                              ? _buildProfileTab(isDark)
                              : _buildEstablishmentsTab(isDark),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon, bool isDark) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? MedicalSolarColors.medicalBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: MedicalSolarColors.medicalBlue,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? MedicalSolarColors.medicalBlue
                  : (isDark ? Colors.white.withOpacity(0.5) : MedicalSolarColors.softGrey.withOpacity(0.5)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? MedicalSolarColors.medicalBlue
                    : (isDark ? Colors.white.withOpacity(0.7) : MedicalSolarColors.softGrey.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations Personnelles',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            icon: Icons.person,
            label: 'Prénom',
            value: _user?.firstName ?? '',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.person_outline,
            label: 'Nom',
            value: _user?.lastName ?? '',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.email,
            label: 'Email',
            value: _user?.email ?? '',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.phone,
            label: 'Téléphone',
            value: _user?.phone ?? 'Non renseigné',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.calendar_today,
            label: 'Membre depuis',
            value: _user?.createdAt != null
                ? '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'
                : 'N/A',
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          // Bouton modifier profil
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _editUserProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Modifier le profil'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstablishmentsTab(bool isDark) {
    return Column(
      children: [
        // Bouton ajouter établissement
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateEstablishment,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un établissement'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        // Liste des établissements
        Expanded(
          child: _establishments.isEmpty
              ? _buildEmptyEstablishments(isDark)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _establishments.length,
                    itemBuilder: (context, index) {
                      return _buildEstablishmentCard(_establishments[index], isDark);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MedicalSolarColors.medicalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: MedicalSolarColors.medicalBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : MedicalSolarColors.softGrey.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstablishmentCard(EstablishmentResponse establishment, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          NavigationHelper.push(
            context,
            ComprehensiveResultsPage(
              establishmentId: establishment.id,
              themeProvider: widget.themeProvider,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: MedicalSolarColors.medicalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: MedicalSolarColors.medicalBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      establishment.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      establishment.type ?? 'Type non spécifié',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : MedicalSolarColors.softGrey.withOpacity(0.7),
                      ),
                    ),
                    ...[
                    const SizedBox(height: 4),
                    Text(
                      '${establishment.numberOfBeds} lits',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : MedicalSolarColors.softGrey.withOpacity(0.6),
                      ),
                    ),
                  ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white.withOpacity(0.7) : MedicalSolarColors.softGrey,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editEstablishment(establishment);
                  } else if (value == 'delete') {
                    _deleteEstablishment(establishment.id, establishment.name);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEstablishments(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: isDark ? Colors.white.withOpacity(0.3) : MedicalSolarColors.softGrey.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun établissement',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier établissement pour commencer',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : MedicalSolarColors.softGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToCreateEstablishment,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un établissement'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  const _EditUserDialog({
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        'Modifier le profil',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: widget.firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'email est requis';
                  }
                  if (!value.contains('@')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                {
                  'firstName': widget.firstNameController.text,
                  'lastName': widget.lastNameController.text,
                  'email': widget.emailController.text,
                  'phone': widget.phoneController.text,
                },
              );
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}





