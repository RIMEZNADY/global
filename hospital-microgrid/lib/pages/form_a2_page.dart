import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/pages/form_a5_page.dart';
import 'package:hospital_microgrid/services/draft_service.dart';
import 'package:hospital_microgrid/widgets/progress_indicator.dart';
import 'package:hospital_microgrid/widgets/help_tooltip.dart';
import 'package:hospital_microgrid/theme/semantic_colors.dart';
import 'package:hospital_microgrid/utils/navigation_helper.dart';
import 'package:hospital_microgrid/utils/app_spacing.dart';
import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class FormA2Page extends StatefulWidget {
  final String institutionType;
  final String institutionName;
  final Position location;
  final int numberOfBeds;

  const FormA2Page({
    super.key,
    required this.institutionType,
    required this.institutionName,
    required this.location,
    required this.numberOfBeds,
  });

  @override
  State<FormA2Page> createState() => _FormA2PageState();
}

class _FormA2PageState extends State<FormA2Page> {
  final _formKey = GlobalKey<FormState>();
  final _solarSurfaceController = TextEditingController();
  final _solarSurfaceMinController = TextEditingController();
  final _solarSurfaceMaxController = TextEditingController();
  final _nonCriticalSurfaceController = TextEditingController();
  final _nonCriticalSurfaceMinController = TextEditingController();
  final _nonCriticalSurfaceMaxController = TextEditingController();
  final _monthlyConsumptionController = TextEditingController();
  final _monthlyConsumptionMinController = TextEditingController();
  final _monthlyConsumptionMaxController = TextEditingController();
  
  bool _useIntervalSolar = false;
  bool _useIntervalNonCritical = false;
  bool _useIntervalConsumption = false;
  String? _contextualAlert;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    // Sauvegarder automatiquement quand les valeurs changent
    _solarSurfaceController.addListener(_saveDraft);
    _solarSurfaceMinController.addListener(_saveDraft);
    _solarSurfaceMaxController.addListener(_saveDraft);
    _nonCriticalSurfaceController.addListener(_saveDraft);
    _nonCriticalSurfaceMinController.addListener(_saveDraft);
    _nonCriticalSurfaceMaxController.addListener(_saveDraft);
    _monthlyConsumptionController.addListener(_saveDraft);
    _monthlyConsumptionMinController.addListener(_saveDraft);
    _monthlyConsumptionMaxController.addListener(_saveDraft);
    // Vérifier les alertes contextuelles
    _solarSurfaceController.addListener(_checkContextualAlerts);
    _monthlyConsumptionController.addListener(_checkContextualAlerts);
  }

  Future<void> _loadDraft() async {
    final draft = await DraftService.getFormA2Draft();
    if (draft != null && mounted) {
      setState(() {
        if (draft['solarSurface'] != null) {
          _solarSurfaceController.text = draft['solarSurface'].toString();
        }
        if (draft['solarSurfaceMin'] != null) {
          _solarSurfaceMinController.text = draft['solarSurfaceMin'].toString();
        }
        if (draft['solarSurfaceMax'] != null) {
          _solarSurfaceMaxController.text = draft['solarSurfaceMax'].toString();
        }
        _useIntervalSolar = draft['useIntervalSolar'] ?? false;
        
        if (draft['nonCriticalSurface'] != null) {
          _nonCriticalSurfaceController.text = draft['nonCriticalSurface'].toString();
        }
        if (draft['nonCriticalSurfaceMin'] != null) {
          _nonCriticalSurfaceMinController.text = draft['nonCriticalSurfaceMin'].toString();
        }
        if (draft['nonCriticalSurfaceMax'] != null) {
          _nonCriticalSurfaceMaxController.text = draft['nonCriticalSurfaceMax'].toString();
        }
        _useIntervalNonCritical = draft['useIntervalNonCritical'] ?? false;
        
        if (draft['monthlyConsumption'] != null) {
          _monthlyConsumptionController.text = draft['monthlyConsumption'].toString();
        }
        if (draft['monthlyConsumptionMin'] != null) {
          _monthlyConsumptionMinController.text = draft['monthlyConsumptionMin'].toString();
        }
        if (draft['monthlyConsumptionMax'] != null) {
          _monthlyConsumptionMaxController.text = draft['monthlyConsumptionMax'].toString();
        }
        _useIntervalConsumption = draft['useIntervalConsumption'] ?? false;
      });
      _checkContextualAlerts();
    }
  }

  void _saveDraft() {
    final solarSurface = double.tryParse(_solarSurfaceController.text);
    final solarSurfaceMin = double.tryParse(_solarSurfaceMinController.text);
    final solarSurfaceMax = double.tryParse(_solarSurfaceMaxController.text);
    final nonCriticalSurface = double.tryParse(_nonCriticalSurfaceController.text);
    final nonCriticalSurfaceMin = double.tryParse(_nonCriticalSurfaceMinController.text);
    final nonCriticalSurfaceMax = double.tryParse(_nonCriticalSurfaceMaxController.text);
    final monthlyConsumption = double.tryParse(_monthlyConsumptionController.text);
    final monthlyConsumptionMin = double.tryParse(_monthlyConsumptionMinController.text);
    final monthlyConsumptionMax = double.tryParse(_monthlyConsumptionMaxController.text);
    
    DraftService.saveFormA2Draft(
      solarSurface: solarSurface,
      solarSurfaceMin: solarSurfaceMin,
      solarSurfaceMax: solarSurfaceMax,
      useIntervalSolar: _useIntervalSolar,
      nonCriticalSurface: nonCriticalSurface,
      nonCriticalSurfaceMin: nonCriticalSurfaceMin,
      nonCriticalSurfaceMax: nonCriticalSurfaceMax,
      useIntervalNonCritical: _useIntervalNonCritical,
      monthlyConsumption: monthlyConsumption,
      monthlyConsumptionMin: monthlyConsumptionMin,
      monthlyConsumptionMax: monthlyConsumptionMax,
      useIntervalConsumption: _useIntervalConsumption,
    );
  }

  void _checkContextualAlerts() {
    final solarSurface = _useIntervalSolar
        ? ((double.tryParse(_solarSurfaceMinController.text) ?? 0) + 
           (double.tryParse(_solarSurfaceMaxController.text) ?? 0)) / 2
        : double.tryParse(_solarSurfaceController.text);
    final monthlyConsumption = _useIntervalConsumption
        ? ((double.tryParse(_monthlyConsumptionMinController.text) ?? 0) + 
           (double.tryParse(_monthlyConsumptionMaxController.text) ?? 0)) / 2
        : double.tryParse(_monthlyConsumptionController.text);
    
    if (solarSurface != null && monthlyConsumption != null && monthlyConsumption > 0) {
      // Calcul approximatif de l'autonomie: Surface × 4.5 kWh/m²/jour × 0.2 (efficacit) × 30 jours
      final monthlyProduction = solarSurface * 4.5 * 0.2 * 30;
      final autonomy = (monthlyProduction / monthlyConsumption) * 100;
      
      setState(() {
        if (autonomy < 50 && solarSurface < 500) {
          _contextualAlert = '⚠️ Surface solaire insuffisante: Avec cette configuration, votre production solaire couvrirait seulement ${autonomy.toStringAsFixed(1)}% de votre consommation mensuelle. Pour une autonomie > 50%, une surface d\'au moins 500 m² est recommandée.';
        } else if (autonomy > 100) {
          _contextualAlert = '✅ Excellente configuration: Votre production solaire (${autonomy.toStringAsFixed(1)}% de votre consommation) pourrait couvrir l\'ensemble de vos besoins, voire produire un excédent d\'énergie.';
        } else if (autonomy >= 50) {
          _contextualAlert = '✅ Bonne configuration: Votre production solaire pourrait couvrir ${autonomy.toStringAsFixed(1)}% de votre consommation mensuelle. Cela signifie que plus de la moitié de votre énergie proviendrait du solaire, réduisant significativement votre facture.';
        } else {
          _contextualAlert = null;
        }
      });
    } else {
      setState(() {
        _contextualAlert = null;
      });
    }
  }

  @override
  void dispose() {
    _solarSurfaceController.dispose();
    _solarSurfaceMinController.dispose();
    _solarSurfaceMaxController.dispose();
    _nonCriticalSurfaceController.dispose();
    _nonCriticalSurfaceMinController.dispose();
    _nonCriticalSurfaceMaxController.dispose();
    _monthlyConsumptionController.dispose();
    _monthlyConsumptionMinController.dispose();
    _monthlyConsumptionMaxController.dispose();
    super.dispose();
  }

  // Helper function to validate and get value from interval or exact
  double? _getValueFromField({
    required bool useInterval,
    required TextEditingController exactController,
    required TextEditingController minController,
    required TextEditingController maxController,
    required String fieldName,
  }) {
    if (useInterval) {
      final min = double.tryParse(minController.text);
      final max = double.tryParse(maxController.text);
      
      if (min == null || max == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez entrer des valeurs valides pour l\'intervalle de $fieldName'),
            backgroundColor: SemanticColors.error(context),
          ),
        );
        return null;
      }
      
      if (min >= max) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La valeur minimale doit être infrieure à la valeur maximale pour $fieldName'),
            backgroundColor: SemanticColors.error(context),
          ),
        );
        return null;
      }
      
      // Return average for calculations
      return (min + max) / 2;
    } else {
      final value = double.tryParse(exactController.text);
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez entrer une valeur valide pour $fieldName'),
            backgroundColor: SemanticColors.error(context),
          ),
        );
        return null;
      }
      return value;
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Validate and get solar surface value
      final solarSurface = _getValueFromField(
        useInterval: _useIntervalSolar,
        exactController: _solarSurfaceController,
        minController: _solarSurfaceMinController,
        maxController: _solarSurfaceMaxController,
        fieldName: 'Surface installable',
      );
      if (solarSurface == null) return;

      // Validate and get non-critical surface value
      final nonCriticalSurface = _getValueFromField(
        useInterval: _useIntervalNonCritical,
        exactController: _nonCriticalSurfaceController,
        minController: _nonCriticalSurfaceMinController,
        maxController: _nonCriticalSurfaceMaxController,
        fieldName: 'Surface non critiques',
      );
      if (nonCriticalSurface == null) return;

      // Validate and get monthly consumption value
      final monthlyConsumption = _getValueFromField(
        useInterval: _useIntervalConsumption,
        exactController: _monthlyConsumptionController,
        minController: _monthlyConsumptionMinController,
        maxController: _monthlyConsumptionMaxController,
        fieldName: 'Consommation mensuelle',
      );
      if (monthlyConsumption == null) return;

      // Calculate basic recommendations for FormA5 (real values will come from backend after creation)
      // Using average values from intervals for calculations
      final recommendedPVPower = solarSurface * 0.2; // kW - assume 200W per m²
      final avgHourlyConsumption = monthlyConsumption / (30 * 24);
      final recommendedBatteryCapacity = avgHourlyConsumption * 12; // Enough for 12 hours

      // Navigate directly to Form A5 (Material Selection)
      NavigationHelper.push(
        context,
        FormA5Page(
          institutionType: widget.institutionType,
          institutionName: widget.institutionName,
          location: widget.location,
          numberOfBeds: widget.numberOfBeds,
          solarSurface: solarSurface,
          nonCriticalSurface: nonCriticalSurface,
          monthlyConsumption: monthlyConsumption,
          recommendedPVPower: recommendedPVPower,
          recommendedBatteryCapacity: recommendedBatteryCapacity,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulaire 2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    MedicalSolarColors.darkBackground,
                    MedicalSolarColors.darkSurface,
                  ]
                : [
                    MedicalSolarColors.offWhite,
                    const Color(0xFFE8F4F8),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Indicateur de progression
                  const FormProgressIndicator(
                    currentStep: 2,
                    totalSteps: 3,
                    stepLabels: [
                      'Identification',
                      'Technique',
                      'Équipements',
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Informations techniques',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 32),
                // Alerte contextuelle
                if (_contextualAlert != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _contextualAlert!.contains('⚠️')
                          ? (isDark 
                              ? SemanticColors.warningDarkMode.withOpacity(0.2) 
                              : SemanticColors.warningLight.withOpacity(0.1))
                          : (isDark 
                              ? SemanticColors.successDarkMode.withOpacity(0.2) 
                              : SemanticColors.successLight.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _contextualAlert!.contains('⚠️')
                            ? SemanticColors.warning(context).withOpacity(0.5)
                            : SemanticColors.success(context).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _contextualAlert!.contains('⚠️') ? Icons.warning_amber : Icons.check_circle,
                          color: _contextualAlert!.contains('⚠️') 
                              ? SemanticColors.warning(context) 
                              : SemanticColors.success(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _contextualAlert!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // 1. Surface installable pour panneau solaire (m2)
                  const LabelWithHelp(
                    label: 'Surface installable pour panneau solaire',
                    helpTitle: 'Surface installable pour panneaux solaires',
                    helpMessage: 'Surface totale disponible sur les toits ou au sol pour installer des panneaux photovoltaïques. '
                        'Cette surface détermine la capacité de production d\'énergie solaire de votre microgrid.\n\n'
                        'Exemple : Pour un hôpital moyen (500 lits), une surface de 1000-2000 m² est typique.',
                  ),
                  const SizedBox(height: 8),
                  // Toggle for interval/exact value
                  Row(
                    children: [
                      Text(
                        'Valeur exacte',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF0F172A).withOpacity(0.7),
                        ),
                      ),
                      Switch(
                        value: _useIntervalSolar,
                        onChanged: (value) {
                          setState(() {
                            _useIntervalSolar = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                      Text(
                        'Intervalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF0F172A).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_useIntervalSolar)
                    TextFormField(
                      controller: _solarSurfaceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 500',
                        suffixText: 'm²',
                        prefixIcon: const Icon(Icons.solar_power),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer la surface';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _solarSurfaceMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'Ex: 400',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_downward),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  isDark ? const Color(0xFF1E293B) : Colors.white,
                            ),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Min requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _solarSurfaceMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'Ex: 600',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_upward),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  isDark ? const Color(0xFF1E293B) : Colors.white,
                            ),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Max requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // 2. Surface non critiques dispo
                  const LabelWithHelp(
                    label: 'Surface non critiques disponible',
                    helpTitle: 'Surface non critiques',
                    helpMessage: 'Surface disponible sur les toits ou au sol pour installer des panneaux solaires sur des zones NON critiques.\n\n'
                        'Les zones non critiques sont les parties de l\'établissement où une panne de production solaire n\'affecterait pas les opérations vitales (parkings, entrepôts, bureaux administratifs, etc.).\n\n'
                        'Cette distinction permet d\'optimiser la résilience : les besoins critiques restent alimentés même si cette zone de production tombe en panne.',
                  ),
                  const SizedBox(height: 8),
                  // Toggle for interval/exact value
                  Row(
                    children: [
                      Text(
                        'Valeur exacte',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF0F172A).withOpacity(0.7),
                        ),
                      ),
                      Switch(
                        value: _useIntervalNonCritical,
                        onChanged: (value) {
                          setState(() {
                            _useIntervalNonCritical = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                      Text(
                        'Intervalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF0F172A).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_useIntervalNonCritical)
                    TextFormField(
                      controller: _nonCriticalSurfaceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 200',
                        suffixText: 'm²',
                        prefixIcon: const Icon(Icons.grid_view),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer la surface';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nonCriticalSurfaceMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'Ex: 150',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_downward),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            ),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Min requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nonCriticalSurfaceMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'Ex: 250',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_upward),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            ),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Max requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // 3. Consommation mensuelle actuel (Kwh)
                  const LabelWithHelp(
                    label: 'Consommation mensuelle actuelle',
                    helpTitle: 'Consommation énergétique mensuelle',
                    helpMessage: 'Consommation totale d\'électricité de votre établissement par mois, en kilowattheures (kWh).\n\n'
                        'Cette valeur détermine la taille nécessaire du système de microgrid pour couvrir vos besoins énergétiques.\n\n'
                        'Vous pouvez la trouver sur vos factures d\'électricité mensuelles. Si vous avez plusieurs factures, additionnez-les.\n\n'
                        'Exemple : Un hôpital de 200 lits consomme typiquement entre 30 000 et 80 000 kWh par mois.',
                  ),
                  const SizedBox(height: 8),
                  // Toggle for interval/exact value
                  Row(
                    children: [
                      Text(
                        'Valeur exacte',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF0F172A).withOpacity(0.7),
                        ),
                      ),
                      Switch(
                        value: _useIntervalConsumption,
                        onChanged: (value) {
                          setState(() {
                            _useIntervalConsumption = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                      Text(
                        'Intervalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF0F172A).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_useIntervalConsumption)
                    TextFormField(
                      controller: _monthlyConsumptionController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 50000',
                        suffixText: 'Kwh',
                        prefixIcon: const Icon(Icons.bolt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer la consommation';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _monthlyConsumptionMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'Ex: 40000',
                              suffixText: 'Kwh',
                              prefixIcon: const Icon(Icons.arrow_downward),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            ),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Min requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _monthlyConsumptionMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'Ex: 60000',
                              suffixText: 'Kwh',
                              prefixIcon: const Icon(Icons.arrow_upward),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6366F1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            ),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Max requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  // Submit Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF06B6D4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleSubmit,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'Soumettre',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

