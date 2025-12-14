/// Mappe les types d'établissement du frontend vers le backend
class EstablishmentMapper {
 /// Convertit le type d'établissement du frontend vers le format backend
 static String mapInstitutionTypeToBackend(String frontendType) {
 // Les types dans FormA1 sont:
 // 'CHU (Centre Hospitalier Universitaire)'
 // 'Hôpital Gnral'
 // 'Hôpital Spcialis'
 // 'Clinique'
 // 'Centre de Sant'
 // 'Autre'
 
 if (frontendType.contains('CHU')) {
 return 'CHU';
 } else if (frontendType.contains('Hôpital Gnral')) {
 return 'HOPITAL_REGIONAL'; // ou HOPITAL_PROVINCIAL selon le besoin
 } else if (frontendType.contains('Hôpital Spcialis')) {
 return 'HOPITAL_REGIONAL';
 } else if (frontendType.contains('Clinique')) {
 return 'CLINIQUE_PRIVEE';
 } else if (frontendType.contains('Centre de Sant')) {
 return 'CENTRE_SANTE_PRIMAIRE';
 } else {
 return 'CENTRE_SANTE_PRIMAIRE'; // Par dfaut pour "Autre"
 }
 }
 
 /// Convertit la zone solaire du frontend vers le format backend
 static String? mapSolarZoneToIrradiationClass(String? solarZone) {
 if (solarZone == null) return null;
 
 // SolarZone enum: zone1, zone2, zone3, zone4
 // Backend IrradiationClass: A, B, C, D
 switch (solarZone) {
 case 'zone1':
 return 'A';
 case 'zone2':
 return 'B';
 case 'zone3':
 return 'C';
 case 'zone4':
 return 'D';
 default:
 return 'C'; // Par dfaut (Casablanca)
 }
 }
 
 /// Convertit SolarZone enum vers String pour le backend
 static String? mapSolarZoneEnumToIrradiationClass(dynamic solarZone) {
 if (solarZone == null) return null;
 
 final zoneName = solarZone.toString().replaceFirst('SolarZone.', '');
 return mapSolarZoneToIrradiationClass(zoneName);
 }
 
 /// Convertit le type d'établissement du backend vers le format frontend
 static String mapBackendToInstitutionType(String backendType) {
 switch (backendType) {
 case 'CHU':
 return 'CHU (Centre Hospitalier Universitaire)';
 case 'HOPITAL_REGIONAL':
 case 'HOPITAL_PROVINCIAL':
 return 'Hôpital Gnral';
 case 'HOPITAL_SPECIALISE':
 return 'Hôpital Spcialis';
 case 'CLINIQUE_PRIVEE':
 return 'Clinique';
 case 'CENTRE_SANTE_PRIMAIRE':
 return 'Centre de Sant';
 default:
 return 'Autre';
 }
 }
 
 /// Convertit la Priorité du frontend vers le format backend
 static String? mapPrioriteToBackend(String? frontendPriorite) {
   if (frontendPriorite == null) return null;

   // Les Priorités dans FormB3 sont:
 // 'Haute - Production maximale d\'énergie'
 // 'Moyenne - Équilibre coût/efficacité'
   // 'Basse - Coût minimal'

 if (frontendPriorite.contains('Haute') || frontendPriorite.contains('maximale')) {
 return 'MAXIMIZE_AUTONOMY';
 } else if (frontendPriorite.contains('Moyenne') || frontendPriorite.contains('Équilibre')) {
 return 'OPTIMIZE_ROI';
   } else if (frontendPriorite.contains('Basse') || frontendPriorite.contains('minimal')) {
 return 'MINIMIZE_COST';
 } else {
 return 'OPTIMIZE_ROI'; // Par défaut
 }
 }
}

