import 'package:flutter/material.dart';
import 'package:hospital_microgrid/utils/navigation_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/services/establishment_service.dart';
import 'package:hospital_microgrid/utils/establishment_mapper.dart';
import 'package:hospital_microgrid/services/draft_service.dart';
import 'package:hospital_microgrid/pages/comprehensive_results_page.dart';
import 'package:hospital_microgrid/providers/theme_provider.dart';
import 'package:hospital_microgrid/widgets/progress_indicator.dart';
import 'package:hospital_microgrid/theme/semantic_colors.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class FormA5Page extends StatefulWidget {
  final String institutionType;
  final String institutionName;
  final Position location;
  final int numberOfBeds;
  final double solarSurface;
  final double nonCriticalSurface;
  final double monthlyConsumption;
  final double recommendedPVPower;
  final double recommendedBatteryCapacity;

  const FormA5Page({
    super.key,
    required this.institutionType,
    required this.institutionName,
    required this.location,
    required this.numberOfBeds,
    required this.solarSurface,
    required this.nonCriticalSurface,
    required this.monthlyConsumption,
    required this.recommendedPVPower,
    required this.recommendedBatteryCapacity,
  });

  @override
  State<FormA5Page> createState() => _FormA5PageState();
}

class _FormA5PageState extends State<FormA5Page> {
  String? _selectedPanel;
  String? _selectedBattery;
  String? _selectedInverter;
  String? _selectedController;
  final bool _isLoadingRecommendations = false;
  double? _aiRecommendedPVPower;
  double? _aiRecommendedBatteryCapacity;

  // �quipements avec prix r�alistes BasÃ©�s sur le march� marocain (2024)
  // Prix en DH (Dirhams Marocains) - Estimations BasÃ©�es sur le march� local
  // Note: Les prix peuvent varier selon le fournisseur, la marque et les conditions du march�
  final List<Map<String, String>> solarPanels = [
    {'id': 'panel1', 'name': 'Panneau Solaire Monocristallin 400W', 'price': '850', 'efficiency': '21.5%', 'note': 'Prix moyen march�: 2.1-2.3 DH/W'},
    {'id': 'panel2', 'name': 'Panneau Solaire Polycristallin 380W', 'price': '720', 'efficiency': '19.2%', 'note': 'Prix moyen march�: 1.8-2.0 DH/W'},
    {'id': 'panel3', 'name': 'Panneau Solaire Bifacial 450W', 'price': '1100', 'efficiency': '22.8%', 'note': 'Prix moyen march�: 2.4-2.6 DH/W'},
    {'id': 'panel4', 'name': 'Panneau Solaire PERC 410W', 'price': '950', 'efficiency': '21.8%', 'note': 'Prix moyen march�: 2.2-2.4 DH/W'},
  ];

  final List<Map<String, String>> batteries = [
    {'id': 'battery1', 'name': 'Batterie Lithium-ion 10kWh', 'price': '45000', 'cycles': '6000', 'note': 'Prix moyen: 4000-5000 DH/kWh'},
    {'id': 'battery2', 'name': 'Batterie Lithium-ion 15kWh', 'price': '65000', 'cycles': '6000', 'note': 'Prix moyen: 4000-5000 DH/kWh'},
    {'id': 'battery3', 'name': 'Batterie Lithium Fer Phosphate 12kWh', 'price': '52000', 'cycles': '8000', 'note': 'Prix moyen: 4000-5000 DH/kWh (meilleure dur�e de vie)'},
    {'id': 'battery4', 'name': 'Batterie AGM 20kWh', 'price': '38000', 'cycles': '1500', 'note': 'Prix moyen: 1500-2500 DH/kWh (moins cher mais moins de cycles)'},
  ];

  final List<Map<String, String>> inverters = [
    {'id': 'inv1', 'name': 'Onduleur Hybride 5kW', 'price': '12000', 'type': 'Hybride', 'note': 'Prix moyen: 2000-2500 DH/kW'},
    {'id': 'inv2', 'name': 'Onduleur Hybride 10kW', 'price': '22000', 'type': 'Hybride', 'note': 'Prix moyen: 2000-2500 DH/kW'},
    {'id': 'inv3', 'name': 'Onduleur Grid-Tie 8kW', 'price': '15000', 'type': 'Grid-Tie', 'note': 'Prix moyen: 1500-2000 DH/kW'},
    {'id': 'inv4', 'name': 'Onduleur Hybride 15kW', 'price': '32000', 'type': 'Hybride', 'note': 'Prix moyen: 2000-2500 DH/kW'},
  ];

  final List<Map<String, String>> controllers = [
    {'id': 'Coûtrl1', 'name': 'R�gulateur MPPT 60A', 'price': '3500', 'type': 'MPPT', 'note': 'Prix moyen: 55-65 DH/A'},
    {'id': 'Coûtrl2', 'name': 'R�gulateur MPPT 80A', 'price': '4800', 'type': 'MPPT', 'note': 'Prix moyen: 55-65 DH/A'},
    {'id': 'Coûtrl3', 'name': 'R�gulateur MPPT 100A', 'price': '6200', 'type': 'MPPT', 'note': 'Prix moyen: 55-65 DH/A'},
    {'id': 'Coûtrl4', 'name': 'R�gulateur PWM 50A', 'price': '1800', 'type': 'PWM', 'note': 'Prix moyen: 30-40 DH/A (moins efficace)'},
  ];

  Future<void> _handleFinish() async {
    if (_selectedPanel == null || _selectedBattery == null || _selectedInverter == null || _selectedController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez s�leCoûtionner tous les �quipements'),
          backgroundColor: SemanticColors.warning(context),
        ),
      );
      return;
    }

    // Cr�er direCoûtement l'�Ã©tablissement
    await _createEstablishment();
  }

  Future<void> _createEstablishment() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Cr�er l'�Ã©tablissement dans le backend
      final request = EstablishmentRequest(
        name: widget.institutionName,
        type: EstablishmentMapper.mapInstitutionTypeToBackend(widget.institutionType),
        numberOfBeds: widget.numberOfBeds,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        installableSurfaceM2: widget.solarSurface,
        nonCriticalSurfaceM2: widget.nonCriticalSurface,
        monthlyConsumptionKwh: widget.monthlyConsumption,
        existingPvInstalled: false,
      );

      final created = await EstablishmentService.createEstablishment(request);

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement

        // Supprimer tous les brouillons apr�s cr�ation r�ussie
        await DraftService.clearAllDrafts();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('�Ã©tablissement cr�� avec succ�s!'),
            backgroundColor: SemanticColors.success(context),
            duration: const Duration(seconds: 2),
          ),
        );

        // Naviguer direCoûtement vers la page de r�sultats complets
        final themeProvider = ThemeProvider();
        NavigationHelper.pushAndRemoveUntil(
          context,
          ComprehensiveResultsPage(
            establishmentId: created.id,
            themeProvider: themeProvider,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la cr�ation: ${e.toString()}'),
            backgroundColor: SemanticColors.error(context),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('S�leCoûtion des �quipements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? MedicalSolarColors.softGrey : MedicalSolarColors.offWhite,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Indicateur de progression
                const FormProgressIndicator(
                  currentStep: 3,
                  totalSteps: 3,
                  stepLabels: [
                    'Identification',
                    'Technique',
                    '�quipements',
                  ],
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Choisissez vos �quipements',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'S�leCoûtionnez les �quipements recommand�s pour votre installation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : MedicalSolarColors.softGrey.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                // Recommended Power Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MedicalSolarColors.medicalBlue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [MedicalSolarColors.medicalBlue, MedicalSolarColors.solarGreen],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recommandations',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingRecommendations
                                ? Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Chargement des recommandations AI...',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : MedicalSolarColors.softGrey.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'PV: ${(_aiRecommendedPVPower ?? widget.recommendedPVPower).toStringAsFixed(2)} kW | Batterie: ${(_aiRecommendedBatteryCapacity ?? widget.recommendedBatteryCapacity).toStringAsFixed(2)} kWh ${_aiRecommendedPVPower != null ? "?? AI" : ""}',
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Note sur les prix
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? MedicalSolarColors.darkSurface.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark 
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.blue : Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Les prix affich�s sont des estimations BasÃ©�es sur le march� marocain (2024). Les prix r�els peuvent varier selon le fournisseur, la marque et les conditions du march�.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : MedicalSolarColors.softGrey.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 1. Panneaux Solaires
                _buildSectionTitle('Panneaux Solaires', Icons.solar_power, isDark),
                const SizedBox(height: 16),
                ...solarPanels.map((panel) => _buildEquipmentCard(
                      context: context,
                      isDark: isDark,
                      isMobile: isMobile,
                      id: panel['id']!,
                      name: panel['name']!,
                      details: 'Efficacit�: ${panel['efficiency']}',
                      price: panel['price']!,
                      isSelected: _selectedPanel == panel['id'],
                      onTap: () {
                        setState(() {
                          _selectedPanel = panel['id'];
                        });
                      },
                    )),
                const SizedBox(height: 32),
                // 2. Batteries
                _buildSectionTitle('Batteries', Icons.battery_std, isDark),
                const SizedBox(height: 16),
                ...batteries.map((battery) => _buildEquipmentCard(
                      context: context,
                      isDark: isDark,
                      isMobile: isMobile,
                      id: battery['id']!,
                      name: battery['name']!,
                      details: 'Cycles: ${battery['cycles']}',
                      price: battery['price']!,
                      isSelected: _selectedBattery == battery['id'],
                      onTap: () {
                        setState(() {
                          _selectedBattery = battery['id'];
                        });
                      },
                    )),
                const SizedBox(height: 32),
                // 3. Onduleurs
                _buildSectionTitle('Onduleurs', Icons.bolt, isDark),
                const SizedBox(height: 16),
                ...inverters.map((inverter) => _buildEquipmentCard(
                      context: context,
                      isDark: isDark,
                      isMobile: isMobile,
                      id: inverter['id']!,
                      name: inverter['name']!,
                      details: 'Type: ${inverter['type']}',
                      price: inverter['price']!,
                      isSelected: _selectedInverter == inverter['id'],
                      onTap: () {
                        setState(() {
                          _selectedInverter = inverter['id'];
                        });
                      },
                    )),
                const SizedBox(height: 32),
                // 4. R�gulateurs
                _buildSectionTitle('R�gulateurs de Charge', Icons.tune, isDark),
                const SizedBox(height: 16),
                ...controllers.map((controller) => _buildEquipmentCard(
                      context: context,
                      isDark: isDark,
                      isMobile: isMobile,
                      id: controller['id']!,
                      name: controller['name']!,
                      details: 'Type: ${controller['type']}',
                      price: controller['price']!,
                      isSelected: _selectedController == controller['id'],
                      onTap: () {
                        setState(() {
                          _selectedController = controller['id'];
                        });
                      },
                    )),
                const SizedBox(height: 40),
                // Finish Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MedicalSolarColors.medicalBlue,
                        MedicalSolarColors.solarGreen,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MedicalSolarColors.medicalBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleFinish,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'Finaliser',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: MedicalSolarColors.medicalBlue, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : MedicalSolarColors.softGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard({
    required BuildContext context,
    required bool isDark,
    required bool isMobile,
    required String id,
    required String name,
    required String details,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? MedicalSolarColors.medicalBlue
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? MedicalSolarColors.medicalBlue.withOpacity(0.3)
                    : (isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1)),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? MedicalSolarColors.medicalBlue.withOpacity(0.2)
                      : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? MedicalSolarColors.medicalBlue : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : MedicalSolarColors.softGrey.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$price DH',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: MedicalSolarColors.medicalBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

