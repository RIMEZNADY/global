import 'package:flutter/material.dart';
import 'package:hospital_microgrid/services/establishment_service.dart';
import 'package:hospital_microgrid/services/auth_service.dart';
import 'package:hospital_microgrid/pages/comprehensive_results_page.dart';
import 'package:hospital_microgrid/pages/institution_choice_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/providers/theme_provider.dart';
import 'package:hospital_microgrid/utils/navigation_helper.dart';

/// Page de gestion des établissements de l'utilisateur
/// Affiche la liste, permet CRUD et navigation vers les résultats
class EstablishmentsListPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const EstablishmentsListPage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<EstablishmentsListPage> createState() =>
      _EstablishmentsListPageState();
}

class _EstablishmentsListPageState extends State<EstablishmentsListPage> {
  List<EstablishmentResponse> establishments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadEstablishments();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _userEmail = user.email;
      });
    } catch (_) {}
  }

  Future<void> _loadEstablishments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await EstablishmentService.getUserEstablishments();
      setState(() {
        establishments = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement : ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEstablishment(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l’établissement'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await EstablishmentService.deleteEstablishment(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement supprimé avec succès')),
      );
      _loadEstablishments();
    }
  }

  Future<void> _navigateToCreate() async {
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

    _loadEstablishments();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes établissements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Créer un établissement',
            onPressed: _navigateToCreate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEstablishments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : establishments.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: establishments.length,
                      itemBuilder: (_, i) =>
                          _buildCard(establishments[i], isDark),
                    ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 72),
          SizedBox(height: 16),
          Text('Aucun établissement'),
        ],
      ),
    );
  }

  Widget _buildCard(EstablishmentResponse e, bool isDark) {
    return Card(
      child: ListTile(
        title: Text(e.name),
        subtitle: Text(
          'Lits : ${e.numberOfBeds}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteEstablishment(e.id, e.name);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
        onTap: () {
          NavigationHelper.push(
            context,
            ComprehensiveResultsPage(
              establishmentId: e.id,
              themeProvider: widget.themeProvider,
            ),
          );
        },
      ),
    );
  }
}
