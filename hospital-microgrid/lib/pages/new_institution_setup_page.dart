import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/providers/theme_provider.dart';
import 'package:hospital_microgrid/main.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class NewInstitutionSetupPage extends StatefulWidget {
 final Position position;
 final SolarZone solarZone;

 const NewInstitutionSetupPage({
 super.key,
 required this.position,
 required this.solarZone,
 });

 @override
 State<NewInstitutionSetupPage> createState() => _NewInstitutionSetupPageState();
}

class _NewInstitutionSetupPageState extends State<NewInstitutionSetupPage> {
 final _formKey = GlobalKey<FormState>();
 final _nameController = TextEditingController();
 final _typeController = TextEditingController();
 String? _selectedType;

 final List<String> _institutionTypes = [
 'CHU (Centre Hospitalier Universitaire)',
 'Hé�pital Gé�né�ral',
 'Hé�pital Spé�cialisé�',
 'Clinique',
 'Centre de Santé�',
 'Autre',
 ];

 @override
 void dispose() {
 _nameController.dispose();
 _typeController.dispose();
 super.dispose();
 }

 void _submitForm() {
 if (_formKey.currentState!.validate()) {
 // Ici, on enverra les donn�es au backend
 // Pour l'instant, on navigue vers le dashboard
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(
 content: Text('Configuration enregistr�e avec succ�s!'),
 backgroundColor: Colors.green,
 ),
 );
 
 final themeProvider = ThemeProvider();
 Navigator.pushReplacement(
 context,
 MaterialPageRoute(
 builder: (context) => HomePage(themeProvider: themeProvider),
 ),
 );
 }
 }

 @override
 Widget build(BuildContext context) {
 final isDark = Theme.of(context).brightness == Brightness.dark;

 return Scaffold(
 appBar: AppBar(
 title: const Text('Nouvelle Institution'),
 ),
 body: SafeArea(
 child: SingleChildScrollView(
 padding: const EdgeInsets.all(24.0),
 child: Form(
 key: _formKey,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Zone solaire info
 Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: Color(SolarZoneService.getZoneColor(widget.solarZone))
 .withOpacity(0.1),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: Color(SolarZoneService.getZoneColor(widget.solarZone))
 .withOpacity(0.3),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.wb_sunny,
 color: Color(SolarZoneService.getZoneColor(widget.solarZone)),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Text(
 SolarZoneService.getZoneName(widget.solarZone),
 style: const TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 16,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 8),
 Text(
 'Votre microgrid sera configuré� selon cette zone solaire.',
 style: TextStyle(
 fontSize: 12,
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 ),
 ],
 ),
 ),
 const SizedBox(height: 32),
 // Titre
 Text(
 'Informations de l\'Institution',
 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: 24),
 // Nom de l'institution
 TextFormField(
 controller: _nameController,
 decoration: InputDecoration(
 labelText: 'Nom de l\'institution',
 hintText: 'Ex: Hé�pital Ibn Sina',
 prefixIcon: const Icon(Icons.business),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 validator: (value) {
 if (value == null || value.isEmpty) {
 return 'Veuillez entrer le nom de l\'institution';
 }
 return null;
 },
 ),
 const SizedBox(height: 20),
 // Type d'institution
 DropdownButtonFormField<String>(
 initialValue: _selectedType,
 decoration: InputDecoration(
 labelText: 'Type d\'institution',
 prefixIcon: const Icon(Icons.category),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 items: _institutionTypes.map((type) {
 return DropdownMenuItem(
 value: type,
 child: Text(type),
 );
 }).toList(),
 onChanged: (value) {
 setState(() {
 _selectedType = value;
 });
 },
 validator: (value) {
 if (value == null || value.isEmpty) {
 return 'Veuillez s�leCoûtionner un type';
 }
 return null;
 },
 ),
 const SizedBox(height: 32),
 // Informations supplé�mentaires (optionnel)
 Text(
 'Informations suppl�mentaires (optionnel)',
 style: Theme.of(context).textTheme.titleMedium?.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 16),
 TextFormField(
 controller: _typeController,
 maxLines: 3,
 decoration: InputDecoration(
 labelText: 'Notes ou informations compl�mentaires',
 hintText: 'capacité�, nombre de lits, �quipements sp�ciaux...',
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 ),
 const SizedBox(height: 40),
 // Bouton de soumission
 ElevatedButton(
 onPressed: _submitForm,
 style: ElevatedButton.styleFrom(
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 child: const Text(
 'Cr�er l\'Institution',
 style: TextStyle(fontSize: 16),
 ),
 ),
 const SizedBox(height: 16),
 TextButton(
 onPressed: () => Navigator.pop(context),
 child: const Text('Retour'),
 ),
 ],
 ),
 ),
 ),
 ),
 );
 }
}

