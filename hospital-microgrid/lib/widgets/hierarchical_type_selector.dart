import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hospital_microgrid/models/establishment_type.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

/// Widget pour sélectionner un type d'établissement avec hiérarchie parent-enfant
class HierarchicalTypeSelector extends StatefulWidget {
  final String? selectedValue;
  final Function(String) onChanged;
  final bool isDark;

  const HierarchicalTypeSelector({
    super.key,
    this.selectedValue,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<HierarchicalTypeSelector> createState() => _HierarchicalTypeSelectorState();
}

class _HierarchicalTypeSelectorState extends State<HierarchicalTypeSelector> {
  String? _selectedBackendValue;
  EstablishmentTypeModel? _selectedType;

  @override
  void initState() {
    super.initState();
    if (widget.selectedValue != null) {
      _selectedType = EstablishmentTypeModel.findByBackendValue(widget.selectedValue!);
      _selectedBackendValue = widget.selectedValue;
    }
  }

  void _showTypeSelectionDialog() {
    final types = EstablishmentTypeModel.getHierarchicalTypes();
    final isDark = widget.isDark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sélectionner le type',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white70 : Colors.grey,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Liste des types
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: types.length,
                  itemBuilder: (context, index) {
                    final type = types[index];
                    return _buildTypeItem(type, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeItem(EstablishmentTypeModel type, bool isDark) {
    final isSelected = _selectedBackendValue == type.backendValue;
    final hasChildren = type.hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (hasChildren) {
              // Afficher les sous-types
              _showChildrenDialog(type, isDark);
            } else {
              // Sélectionner directement
              setState(() {
                _selectedType = type;
                _selectedBackendValue = type.backendValue;
              });
              widget.onChanged(type.backendValue!);
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              children: [
                Icon(
                  hasChildren ? Icons.folder : Icons.category,
                  color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                    ),
                  ),
                ),
                if (hasChildren)
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white70 : Colors.grey,
                    size: 20,
                  ),
                if (isSelected && !hasChildren)
                  const Icon(
                    Icons.check_circle,
                    color: MedicalSolarColors.medicalBlue,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (hasChildren && isSelected) ...[
          const SizedBox(height: 4),
          ...type.children!.map((child) => Padding(
                padding: const EdgeInsets.only(left: 32),
                child: _buildChildItem(child, isDark),
              )),
        ],
      ],
    );
  }

  Widget _buildChildItem(EstablishmentTypeModel child, bool isDark) {
    final isSelected = _selectedBackendValue == child.backendValue;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = child;
          _selectedBackendValue = child.backendValue;
        });
        widget.onChanged(child.backendValue!);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
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
          children: [
            Icon(
              Icons.arrow_right,
              color: isDark ? Colors.white70 : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                child.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: MedicalSolarColors.medicalBlue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _showChildrenDialog(EstablishmentTypeModel parent, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec retour
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        parent.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Liste des sous-types
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: parent.children!.length,
                  itemBuilder: (context, index) {
                    final child = parent.children![index];
                    return _buildChildItem(child, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return InkWell(
      onTap: _showTypeSelectionDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedType?.name ?? 'Sélectionnez le type',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: _selectedType != null
                      ? (isDark ? Colors.white : MedicalSolarColors.softGrey)
                      : (isDark ? Colors.white70 : Colors.grey),
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
