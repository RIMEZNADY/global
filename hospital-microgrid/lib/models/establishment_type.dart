/// Modèle pour les types d'Ãé©tablissements avec hirarchie parent-enfant
class EstablishmentTypeModel {
 final String id;
 final String name;
 final String? backendValue; // Valeur pour le backend (null si c'est un parent)
 final List<EstablishmentTypeModel>? children; // Sous-types (null si c'est une feuille)

 EstablishmentTypeModel({
 required this.id,
 required this.name,
 this.backendValue,
 this.children,
 });

 /// Retourne true si ce type a des sous-types
 bool get hasChildren => children != null && children!.isNotEmpty;

 /// Retourne true si c'est un type final (feuille)
 bool get isLeaf => backendValue != null;

 /// StruCoûture hirarchique selon le PDF Institutions_Sante_Maroc_Lois.pdf
 static List<EstablishmentTypeModel> getHierarchicalTypes() {
 return [
 // CHU (Centre Hospitalier Universitaire) - Type parent
 EstablishmentTypeModel(
 id: 'chu',
 name: 'CHU (Centre Hospitalier Universitaire)',
 backendValue: 'CHU',
 ),

 // Hôpitaux - Type parent avec sous-types
 EstablishmentTypeModel(
 id: 'hopitaux',
 name: 'Hôpitaux',
 children: [
 EstablishmentTypeModel(
 id: 'hopital_regional',
 name: 'Hôpital Rgional',
 backendValue: 'HOPITAL_REGIONAL',
 ),
 EstablishmentTypeModel(
 id: 'hopital_provincial',
 name: 'Hôpital Provincial',
 backendValue: 'HOPITAL_PROVINCIAL',
 ),
 EstablishmentTypeModel(
 id: 'hopital_general',
 name: 'Hôpital Gnral',
 backendValue: 'HOPITAL_GENERAL',
 ),
 EstablishmentTypeModel(
 id: 'hopital_specialise',
 name: 'Hôpital Spcialis',
 backendValue: 'HOPITAL_SPECIALISE',
 ),
 ],
 ),

 // Centres de soins spcialiss - Type parent avec sous-types
 EstablishmentTypeModel(
 id: 'centres_specialises',
 name: 'Centres de Soins Spcialiss',
 children: [
 EstablishmentTypeModel(
 id: 'centre_regional_oncologie',
 name: 'Centre Rgional d\'Oncologie',
 backendValue: 'CENTRE_REGIONAL_ONCOLOGIE',
 ),
 EstablishmentTypeModel(
 id: 'centre_hemodialyse',
 name: 'Centre d\'Hmodialyse',
 backendValue: 'CENTRE_HEMODIALYSE',
 ),
 EstablishmentTypeModel(
 id: 'centre_reeducation',
 name: 'Centre de Rducation',
 backendValue: 'CENTRE_REEDUCATION',
 ),
 EstablishmentTypeModel(
 id: 'centre_addiCoûtologie',
 name: 'Centre d\'AddiCoûtologie',
 backendValue: 'CENTRE_ADDICoûtOLOGIE',
 ),
 ],
 ),

 // Urgences - Type parent avec sous-types
 EstablishmentTypeModel(
 id: 'urgences',
 name: 'Dispositifs d\'Urgences',
 children: [
 EstablishmentTypeModel(
 id: 'umh',
 name: 'UMH (Urgences Mdico-Hospitalières)',
 backendValue: 'UMH',
 ),
 EstablishmentTypeModel(
 id: 'ump',
 name: 'UMP (Urgences Mdicales de Proximit)',
 backendValue: 'UMP',
 ),
 EstablishmentTypeModel(
 id: 'uph',
 name: 'UPH (Urgences Pr-Hospitalières)',
 backendValue: 'UPH',
 ),
 ],
 ),

 // Soins primaires
 EstablishmentTypeModel(
 id: 'centre_sante_primaire',
 name: 'Centre de Sant Primaire',
 backendValue: 'CENTRE_SANTE_PRIMAIRE',
 ),

 // SeCoûteur priv
 EstablishmentTypeModel(
 id: 'clinique_privee',
 name: 'Clinique Prive',
 backendValue: 'CLINIQUE_PRIVEE',
 ),

 // Autre
 EstablishmentTypeModel(
 id: 'autre',
 name: 'Autre',
 backendValue: 'AUTRE',
 ),
 ];
 }

 /// Trouve un type par sa valeur backend
 static EstablishmentTypeModel? findByBackendValue(String backendValue) {
 for (var type in getHierarchicalTypes()) {
 if (type.backendValue == backendValue) {
 return type;
 }
 if (type.hasChildren) {
 for (var child in type.children!) {
 if (child.backendValue == backendValue) {
 return child;
 }
 }
 }
 }
 return null;
 }
}

