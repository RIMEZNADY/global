import 'package:flutter/material.dart';


import 'package:google_fonts/google_fonts.dart';


import 'package:geolocator/geolocator.dart';


import 'package:hospital_microgrid/providers/theme_provider.dart';


import 'package:hospital_microgrid/services/establishment_service.dart';


import 'package:hospital_microgrid/utils/establishment_mapper.dart';


import 'package:hospital_microgrid/pages/result_choice_page.dart';


import 'package:hospital_microgrid/pages/form_a1_page.dart';


import 'package:hospital_microgrid/pages/form_a2_page.dart';


import 'package:hospital_microgrid/pages/form_a5_page.dart';


import 'package:hospital_microgrid/services/draft_service.dart';


import 'package:hospital_microgrid/widgets/progress_indicator.dart';


import 'package:hospital_microgrid/theme/semantic_colors.dart';


import 'package:hospital_microgrid/theme/medical_solar_colors.dart';


/// Page de r�capitulatif et validation avant cr�ation de l'�Ã©tablissement


class EstablishmentReviewPage extends StatefulWidget {


  // Donn�es A1


  final String institutionType;


  final String institutionName;


  final Position location;


  final int numberOfBeds;


  // Donn�es A2


  final double solarSurface;


  final double nonCriticalSurface;


  final double monthlyConsumption;


  final double recommendedPVPower;


  final double recommendedBatteryCapacity;


  // Donn�es A5


  final String? selectedPanel;


  final String? selectedBattery;


  final String? selectedInverter;


  final String? selectedController;


  // Liste des �quipements pour afficher les noms


  final List<Map<String, String>> solarPanels;


  final List<Map<String, String>> batteries;


  final List<Map<String, String>> inverters;


  final List<Map<String, String>> controllers;


  const EstablishmentReviewPage({


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


    required this.selectedPanel,


    required this.selectedBattery,


    required this.selectedInverter,


    required this.selectedController,


    required this.solarPanels,


    required this.batteries,


    required this.inverters,


    required this.controllers,


  });


  @override


  State<EstablishmentReviewPage> createState() => _EstablishmentReviewPageState();


}


class _EstablishmentReviewPageState extends State<EstablishmentReviewPage> {


  bool _isCreating = false;


  String getEquipmentName(String? id, List<Map<String, String>> list) {


    if (id == null) return 'Non s�leCoûtionn�';


    final equipment = list.firstWhere(


      (e) => e['id'] == id,


      orElse: () => {'name': 'Non trouv�'},


    );


    return equipment['name'] ?? 'Non trouv�';


  }


  String getEquipmentPrice(String? id, List<Map<String, String>> list) {


    if (id == null) return '0';


    final equipment = list.firstWhere(


      (e) => e['id'] == id,


      orElse: () => {'price': '0'},


    );


    return equipment['price'] ?? '0';


  }


  double calculateTotalEquipmentCost() {


    final panelPrice = double.tryParse(getEquipmentPrice(widget.selectedPanel, widget.solarPanels)) ?? 0;


    final batteryPrice = double.tryParse(getEquipmentPrice(widget.selectedBattery, widget.batteries)) ?? 0;


    final inverterPrice = double.tryParse(getEquipmentPrice(widget.selectedInverter, widget.inverters)) ?? 0;


    final controllerPrice = double.tryParse(getEquipmentPrice(widget.selectedController, widget.controllers)) ?? 0;


    return panelPrice + batteryPrice + inverterPrice + controllerPrice;


  }


  Future<void> _confirmAndCreate() async {


    // V�rifier que tous les �quipements sont s�leCoûtionn�s


    if (widget.selectedPanel == null ||


        widget.selectedBattery == null ||


        widget.selectedInverter == null ||


        widget.selectedController == null) {


        ScaffoldMessenger.of(context).showSnackBar(


          SnackBar(


            content: const Text('Veuillez s�leCoûtionner tous les �quipements avant de confirmer'),


            backgroundColor: SemanticColors.warning(context),


          ),


        );


      return;


    }


    // Afficher un dialog de confirmation


    final confirmed = await showDialog<bool>(


      context: context,


      builder: (context) => AlertDialog(


        title: const Text('Confirmer la cr�ation'),


        content: Column(


          mainAxisSize: MainAxisSize.min,


          crossAxisAlignment: CrossAxisAlignment.start,


          children: [


            const Text('�tes-vous s�r de vouloir cr�er cet �Ã©tablissement ?'),


            const SizedBox(height: 16),


            Text(


              'Nom: ${widget.institutionName}',


              style: const TextStyle(fontWeight: FontWeight.bold),


            ),


            Text('Type: ${widget.institutionType}'),


            Text('Lits: ${widget.numberOfBeds}'),


            Text('Surface: ${widget.solarSurface.toStringAsFixed(0)} m�'),


            Text('Consommation: ${widget.monthlyConsumption.toStringAsFixed(0)} kWh/mois'),


          ],


        ),


        actions: [


          TextButton(


            onPressed: () => Navigator.of(context).pop(false),


            child: const Text('Annuler'),


          ),


          ElevatedButton(


            onPressed: () => Navigator.of(context).pop(true),


            style: ElevatedButton.styleFrom(


              backgroundColor: SemanticColors.success(context),


              foregroundColor: Colors.white,


            ),


            child: const Text('Confirmer et cr�er'),


          ),


        ],


      ),


    );


    if (confirmed != true) {


      return; // L'utilisateur a annulé�


    }


    setState(() {


      _isCreating = true;


    });


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


        // Naviguer vers la page de choix des r�sultats


        final themeProvider = ThemeProvider();


        Navigator.pushAndRemoveUntil(


          context,


          MaterialPageRoute(


            builder: (context) => ResultChoicePage(


              establishmentId: created.id,


              themeProvider: themeProvider,


            ),


          ),


          (route) => false,


        );


      }


    } catch (e) {


      if (mounted) {


        Navigator.pop(context); // Fermer le dialog de chargement


        setState(() {


          _isCreating = false;


        });


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


  void _editSection(String section) {


    switch (section) {


      case 'A1':


        Navigator.push(


          context,


          MaterialPageRoute(


            builder: (context) => FormA1Page(position: widget.location),


          ),


        );


        break;


      case 'A2':


        Navigator.push(


          context,


          MaterialPageRoute(


            builder: (context) => FormA2Page(


              institutionType: widget.institutionType,


              institutionName: widget.institutionName,


              location: widget.location,


              numberOfBeds: widget.numberOfBeds,


            ),


          ),


        );


        break;


      case 'A5':


        Navigator.push(


          context,


          MaterialPageRoute(


            builder: (context) => FormA5Page(


              institutionType: widget.institutionType,


              institutionName: widget.institutionName,


              location: widget.location,


              numberOfBeds: widget.numberOfBeds,


              solarSurface: widget.solarSurface,


              nonCriticalSurface: widget.nonCriticalSurface,


              monthlyConsumption: widget.monthlyConsumption,


              recommendedPVPower: widget.recommendedPVPower,


              recommendedBatteryCapacity: widget.recommendedBatteryCapacity,


            ),


          ),


        );


        break;


    }


  }


  @override


  Widget build(BuildContext context) {


    final isDark = Theme.of(context).brightness == Brightness.dark;


    final isMobile = MediaQuery.of(context).size.width < 600;


    return Scaffold(


      appBar: AppBar(


        title: const Text('R�capitulatif'),


        leading: IconButton(


          icon: const Icon(Icons.arrow_back),


          onPressed: () => Navigator.pop(context),


        ),


      ),


      body: SafeArea(


        child: Container(


          color: isDark ? MedicalSolarColors.softGrey : MedicalSolarColors.offWhite,


          child: SingleChildScrollView(


            padding: EdgeInsets.all(isMobile ? 16 : 24),


            child: Column(


              crossAxisAlignment: CrossAxisAlignment.stretch,


              children: [


                // TEST: V�rifier que le Column fonCoûtionne


                Container(


                  padding: const EdgeInsets.all(16),


                  color: Colors.green,


                  child: Text(


                    'TEST: Column fonctionne - ${widget.institutionName}',


                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),


                  ),


                ),


                const SizedBox(height: 20),


                // Indicateur de progression


                const FormProgressIndicator(


                  currentStep: 4,


                  totalSteps: 4,


                  stepLabels: [


                    'Identification',


                    'Technique',


                    '�quipements',


                    'R�capitulatif',


                  ],


                ),


                const SizedBox(height: 24),


                // Header


                Container(


                  padding: const EdgeInsets.all(24),


                  decoration: BoxDecoration(


                    gradient: LinearGradient(


                      colors: [


                        Theme.of(context).colorScheme.primary,


                        Theme.of(context).colorScheme.tertiary,


                      ],


                    ),


                    borderRadius: BorderRadius.circular(16),


                  ),


                  child: Column(


                    children: [


                      const Icon(


                        Icons.check_circle_outline,


                        color: Colors.white,


                        size: 48,


                      ),


                      const SizedBox(height: 16),


                      Text(


                        'V�rifiez vos informations',


                        style: GoogleFonts.inter(


                          fontSize: 24,


                          fontWeight: FontWeight.bold,


                          color: Colors.white,


                        ),


                      ),


                      const SizedBox(height: 8),


                      Text(


                        'Veuillez v�rifier toutes les informations avant de cr�er votre �Ã©tablissement',


                        textAlign: TextAlign.center,


                        style: GoogleFonts.inter(


                          fontSize: 14,


                          color: Colors.white.withOpacity(0.9),


                        ),


                      ),


                    ],


                  ),


                ),


                const SizedBox(height: 32),


                // Section A1: Identification


                _buildSectionCard(


                  context: context,


                  isDark: isDark,


                  title: 'A1 - Identification de l\'�Ã©tablissement',


                  icon: Icons.business,


                  onEdit: () => _editSection('A1'),


                  children: [


                    _buildInfoRow('Type d\'�Ã©tablissement', widget.institutionType, isDark),


                    _buildInfoRow('Nom', widget.institutionName, isDark),


                    _buildInfoRow('Nombre de lits', '${widget.numberOfBeds}', isDark),


                    _buildInfoRow(


                      'Localisation',


                      'Lat: ${widget.location.latitude.toStringAsFixed(6)}\nLng: ${widget.location.longitude.toStringAsFixed(6)}',


                      isDark,


                    ),


                  ],


                ),


                const SizedBox(height: 16),


                // Section A2: Informations techniques


                _buildSectionCard(


                  context: context,


                  isDark: isDark,


                  title: 'A2 - Informations techniques',


                  icon: Icons.engineering,


                  onEdit: () => _editSection('A2'),


                  children: [


                    _buildInfoRow('Surface installable (m�)', widget.solarSurface.toStringAsFixed(2), isDark),


                    _buildInfoRow('Surface non critique (m�)', widget.nonCriticalSurface.toStringAsFixed(2), isDark),


                    _buildInfoRow('Consommation mensuelle (kWh)', widget.monthlyConsumption.toStringAsFixed(2), isDark),


                    const SizedBox(height: 8),


                    Container(


                      padding: const EdgeInsets.all(12),


                      decoration: BoxDecoration(


                        color: isDark ? MedicalSolarColors.darkSurface : Colors.blue.shade50,


                        borderRadius: BorderRadius.circular(8),


                      ),


                      child: Column(


                        crossAxisAlignment: CrossAxisAlignment.start,


                        children: [


                          Text(


                            'Recommandations calcul�es',


                            style: GoogleFonts.inter(


                              fontSize: 12,


                              fontWeight: FontWeight.bold,


                              color: isDark ? Colors.white : MedicalSolarColors.softGrey,


                            ),


                          ),


                          const SizedBox(height: 4),


                          _buildInfoRow('PV Recommandé', '${widget.recommendedPVPower.toStringAsFixed(2)} kW', isDark),


                          _buildInfoRow('Batterie Recommandée', '${widget.recommendedBatteryCapacity.toStringAsFixed(2)} kWh', isDark),


                        ],


                      ),


                    ),


                  ],


                ),


                const SizedBox(height: 16),


                // SeCoûtion A5: �quipements


                _buildSectionCard(


                  context: context,


                  isDark: isDark,


                  title: 'A5 - Choix des �quipements',


                  icon: Icons.shopping_cart,


                  onEdit: () => _editSection('A5'),


                  children: [


                    _buildInfoRow(


                      'Panneau solaire',


                      getEquipmentName(widget.selectedPanel, widget.solarPanels),


                      isDark,


                      price: getEquipmentPrice(widget.selectedPanel, widget.solarPanels),


                    ),


                    _buildInfoRow(


                      'Batterie',


                      getEquipmentName(widget.selectedBattery, widget.batteries),


                      isDark,


                      price: getEquipmentPrice(widget.selectedBattery, widget.batteries),


                    ),


                    _buildInfoRow(


                      'Onduleur',


                      getEquipmentName(widget.selectedInverter, widget.inverters),


                      isDark,


                      price: getEquipmentPrice(widget.selectedInverter, widget.inverters),


                    ),


                    _buildInfoRow(


                      'R�gulateur',


                      getEquipmentName(widget.selectedController, widget.controllers),


                      isDark,


                      price: getEquipmentPrice(widget.selectedController, widget.controllers),


                    ),


                    const SizedBox(height: 12),


                    Container(


                      padding: const EdgeInsets.all(16),


                      decoration: BoxDecoration(


                        color: isDark


                            ? SemanticColors.successDarkMode.withOpacity(0.2)


                            : SemanticColors.successLight.withOpacity(0.1),


                        borderRadius: BorderRadius.circular(8),


                        border: Border.all(


                          color: SemanticColors.success(context).withOpacity(0.5),


                          width: 2,


                        ),


                      ),


                      child: Row(


                        mainAxisAlignment: MainAxisAlignment.spaceBetween,


                        children: [


                          Text(


                            'Co�t total estim� des �quipements',


                            style: GoogleFonts.inter(


                              fontSize: 16,


                              fontWeight: FontWeight.bold,


                              color: isDark ? Colors.white : MedicalSolarColors.softGrey,


                            ),


                          ),


                          Text(


                            '${calculateTotalEquipmentCost().toStringAsFixed(0)} DH',


                            style: GoogleFonts.inter(


                              fontSize: 20,


                              fontWeight: FontWeight.bold,


                              color: SemanticColors.success(context),


                            ),


                          ),


                        ],


                      ),


                    ),


                  ],


                ),


                const SizedBox(height: 32),


                // Boutons d'action


                Container(


                  padding: EdgeInsets.all(isMobile ? 16 : 24),


                  decoration: BoxDecoration(


                    color: isDark ? MedicalSolarColors.darkSurface : Colors.white,


                    boxShadow: [


                      BoxShadow(


                        color: Colors.black.withOpacity(0.1),


                        blurRadius: 10,


                        offset: const Offset(0, -5),


                      ),


                    ],


                  ),


                  child: Column(


                    mainAxisSize: MainAxisSize.min,


                    children: [


                      SizedBox(


                        width: double.infinity,


                        child: ElevatedButton.icon(


                          onPressed: _isCreating ? null : _confirmAndCreate,


                          icon: _isCreating


                              ? const SizedBox(


                                  width: 20,


                                  height: 20,


                                  child: CircularProgressIndicator(


                                    strokeWidth: 2,


                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),


                                  ),


                                )


                              : const Icon(Icons.check_circle),


                          label: Text(


                            _isCreating ? 'Cr�ation en cours...' : 'Confirmer et cr�er',


                            style: GoogleFonts.inter(


                              fontSize: 16,


                              fontWeight: FontWeight.bold,


                            ),


                          ),


                          style: ElevatedButton.styleFrom(


                            padding: const EdgeInsets.symmetric(vertical: 16),


                            backgroundColor: SemanticColors.success(context),


                            foregroundColor: Colors.white,


                            shape: RoundedRectangleBorder(


                              borderRadius: BorderRadius.circular(12),


                            ),


                          ),


                        ),


                      ),


                      const SizedBox(height: 12),


                      TextButton(


                        onPressed: _isCreating ? null : () => Navigator.pop(context),


                        child: Text(


                          'Retour pour modifier',


                          style: GoogleFonts.inter(


                            fontSize: 14,


                            color: isDark ? Colors.white.withOpacity(0.7) : MedicalSolarColors.softGrey.withOpacity(0.7),


                          ),


                        ),


                      ),


                    ],


                  ),


                ),


              ],


            ),


          ),


        ),


      ),


    );


  }


  Widget _buildSectionCard({


    required BuildContext context,


    required bool isDark,


    required String title,


    required IconData icon,


    required VoidCallback onEdit,


    required List<Widget> children,


  }) {


    return Container(


      padding: const EdgeInsets.all(20),


      decoration: BoxDecoration(


        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,


        borderRadius: BorderRadius.circular(16),


        border: Border.all(


          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),


        ),


      ),


      child: Column(


        crossAxisAlignment: CrossAxisAlignment.start,


        children: [


          Row(


            mainAxisAlignment: MainAxisAlignment.spaceBetween,


            children: [


              Row(


                children: [


                  Container(


                    width: 40,


                    height: 40,


                    decoration: BoxDecoration(


                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),


                      borderRadius: BorderRadius.circular(10),


                    ),


                    child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),


                  ),


                  const SizedBox(width: 12),


                  Expanded(


                    child: Text(


                      title,


                      style: GoogleFonts.inter(


                        fontSize: 18,


                        fontWeight: FontWeight.bold,


                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,


                      ),


                    ),


                  ),


                ],


              ),


              TextButton.icon(


                onPressed: onEdit,


                icon: const Icon(Icons.edit, size: 18),


                label: const Text('Modifier'),


                style: TextButton.styleFrom(


                  foregroundColor: Theme.of(context).colorScheme.primary,


                ),


              ),


            ],


          ),


          const SizedBox(height: 16),


          ...children,


        ],


      ),


    );


  }


  Widget _buildInfoRow(String label, String value, bool isDark, {String? price}) {


    return Padding(


      padding: const EdgeInsets.only(bottom: 12),


      child: Row(


        crossAxisAlignment: CrossAxisAlignment.start,


        children: [


          Expanded(


            flex: 2,


            child: Text(


              label,


              style: GoogleFonts.inter(


                fontSize: 14,


                color: isDark ? Colors.white.withOpacity(0.7) : MedicalSolarColors.softGrey.withOpacity(0.7),


              ),


            ),


          ),


          Expanded(


            flex: 3,


            child: Column(


              crossAxisAlignment: CrossAxisAlignment.end,


              children: [


                Text(


                  value,


                  textAlign: TextAlign.right,


                  style: GoogleFonts.inter(


                    fontSize: 14,


                    fontWeight: FontWeight.w600,


                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,


                  ),


                ),


                if (price != null && price != '0')


                  Text(


                    '$price DH',


                    textAlign: TextAlign.right,


                    style: GoogleFonts.inter(


                      fontSize: 12,


                      color: isDark ? Colors.white.withOpacity(0.5) : MedicalSolarColors.softGrey.withOpacity(0.5),


                    ),


                  ),


              ],


            ),


          ),


        ],


      ),


    );


  }


}


