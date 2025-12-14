import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hospital_microgrid/services/establishment_service.dart';

class PdfExportService {
  /// Génère et exporte un PDF professionnel des résultats complets
  static Future<void> exportResultsToPdf({
    required EstablishmentResponse establishment,
    required RecommendationsResponse recommendations,
    required Map<String, dynamic> comprehensiveResults,
  }) async {
    final pdf = pw.Document();
    
    // Couleurs professionnelles
    const primaryColor = PdfColors.blue700;
    const secondaryColor = PdfColors.green700;
    const accentColor = PdfColors.orange700;
    const textColor = PdfColors.grey900;
    const lightGrey = PdfColors.grey300;
    
    // PAGE 1 : Page de couverture
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Bandeau suprieur avec dgrad
              pw.Container(
                height: 150,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
              ),
              // Contenu
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 150,
                    alignment: pw.Alignment.centerLeft,
                    padding: const pw.EdgeInsets.only(left: 60, top: 40),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RAPPORT MICROGRID',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Analyse Complète & Recommandations',
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(60),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 40),
                        // Nom établissement (grand)
                        pw.Text(
                          establishment.name.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 40),
                        // Informations établissement
                        PdfExportService._buildInfoCard(
                          'Informations de l\'établissement',
                          [
                            PdfExportService._buildInfoRow('Type', establishment.type, false),
                            PdfExportService._buildInfoRow('Nombre de lits', '${establishment.numberOfBeds}', false),
                            if (establishment.latitude != null && establishment.longitude != null)
                              PdfExportService._buildInfoRow(
                                'Localisation',
                                'Lat: ${establishment.latitude!.toStringAsFixed(6)}, Lng: ${establishment.longitude!.toStringAsFixed(6)}',
                                false,
                              ),
                          ],
                          primaryColor,
                        ),
                        pw.SizedBox(height: 30),
                        // Score global (si disponible)
                        if (comprehensiveResults['globalScore'] != null) ...[
                          _buildScoreHighlight(comprehensiveResults['globalScore'] as Map<String, dynamic>, primaryColor, secondaryColor),
                          pw.SizedBox(height: 30),
                        ],
                        // Recommandations principales (cartes)
                        pw.Text(
                          'Résultats Clés',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 20),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: PdfExportService._buildMetricCard(
                                'Puissance PV',
                                '${recommendations.recommendedPvPower.toStringAsFixed(1)} kW',
                                primaryColor,
                              ),
                            ),
                            pw.SizedBox(width: 16),
                            pw.Expanded(
                              child: PdfExportService._buildMetricCard(
                                'Capacité Batterie',
                                '${recommendations.recommendedBatteryCapacity.toStringAsFixed(1)} kWh',
                                secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 16),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: PdfExportService._buildMetricCard(
                                'Autonomie',
                                '${recommendations.energyAutonomy.toStringAsFixed(1)}%',
                                accentColor,
                              ),
                            ),
                            pw.SizedBox(width: 16),
                            pw.Expanded(
                              child: PdfExportService._buildMetricCard(
                                'ROI',
                                '${recommendations.roi.toStringAsFixed(1)} ans',
                                PdfColors.purple700,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 40),
                        // Date et signature
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          padding: const pw.EdgeInsets.only(top: 40),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Gnr le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    // PAGE 2+ : Dtails
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: primaryColor, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Rapport Microgrid - ${establishment.name}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: lightGrey, width: 1),
              ),
            ),
            child: pw.Text(
              'Rapport gnr par Hospital Microgrid System',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Section Financière
            PdfExportService._buildSectionTitle('Analyse Financière Détaillée', primaryColor),
            pw.SizedBox(height: 15),
            if (comprehensiveResults['financial'] != null)
              PdfExportService._buildFinancialSection(comprehensiveResults['financial'] as Map<String, dynamic>, primaryColor),
            pw.SizedBox(height: 30),
            
            // Section Environnementale
            PdfExportService._buildSectionTitle('Impact Environnemental', secondaryColor),
            pw.SizedBox(height: 15),
            if (comprehensiveResults['environmental'] != null)
              PdfExportService._buildEnvironmentalSection(comprehensiveResults['environmental'] as Map<String, dynamic>, secondaryColor),
            pw.SizedBox(height: 30),
            
            // Score Global Détaillé
            if (comprehensiveResults['globalScore'] != null) ...[
              PdfExportService._buildSectionTitle('Score de Performance Détaillé', accentColor),
              pw.SizedBox(height: 15),
              PdfExportService._buildDetailedScoreSection(comprehensiveResults['globalScore'] as Map<String, dynamic>, accentColor),
              pw.SizedBox(height: 30),
            ],
            
            // Comparaison Avant/Après
            if (comprehensiveResults['beforeAfter'] != null) ...[
              PdfExportService._buildSectionTitle('Comparaison Avant/Après Installation', PdfColors.purple700),
              pw.SizedBox(height: 15),
              PdfExportService._buildBeforeAfterSection(comprehensiveResults['beforeAfter'] as Map<String, dynamic>),
              pw.SizedBox(height: 30),
            ],
            
            // Recommandations Techniques
            PdfExportService._buildSectionTitle('Recommandations Techniques', primaryColor),
            pw.SizedBox(height: 15),
            PdfExportService._buildTechnicalRecommendations(recommendations, comprehensiveResults),
          ];
        },
      ),
    );
    
    // Sauvegarder et partager le PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
  
  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }
  
  static pw.Widget _buildInfoCard(String title, List<pw.Widget> children, PdfColor borderColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: borderColor,
            ),
          ),
          pw.SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
  
  static pw.Widget _buildInfoRow(String label, String value, bool useBoldLabel) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: useBoldLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildScoreHighlight(Map<String, dynamic> globalScore, PdfColor primaryColor, PdfColor secondaryColor) {
    final score = (globalScore['globalScore'] as num?)?.toDouble() ?? 0.0;
    final scoreColor = score >= 80 ? secondaryColor : (score >= 60 ? PdfColors.orange700 : PdfColors.red700);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: scoreColor,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'SCORE GLOBAL',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.normal,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                score.toStringAsFixed(0),
                style: pw.TextStyle(
                  fontSize: 48,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '/ 100',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          if (globalScore['autonomyScore'] != null || globalScore['economicScore'] != null) ...[
            pw.SizedBox(width: 40),
            pw.Container(
              width: 1,
              height: 80,
              color: PdfColors.grey400,
            ),
            pw.SizedBox(width: 40),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (globalScore['autonomyScore'] != null)
                  PdfExportService._buildScoreDetail('Autonomie', (globalScore['autonomyScore'] as num).toDouble()),
                if (globalScore['economicScore'] != null)
                  PdfExportService._buildScoreDetail('Économique', (globalScore['economicScore'] as num).toDouble()),
                if (globalScore['resilienceScore'] != null)
                  PdfExportService._buildScoreDetail('Résilience', (globalScore['resilienceScore'] as num).toDouble()),
                if (globalScore['environmentalScore'] != null)
                  PdfExportService._buildScoreDetail('Environnement', (globalScore['environmentalScore'] as num).toDouble()),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _buildScoreDetail(String label, double score) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Text(
            '${score.toStringAsFixed(0)}/100',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFinancialSection(Map<String, dynamic> financial, PdfColor color) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        PdfExportService._buildTableRow('Coût d\'installation', '${(financial['installationCost'] as num?)?.toStringAsFixed(2) ?? 'N/A'} DH', true, color),
        PdfExportService._buildTableRow('Économies annuelles', '${(financial['annualSavings'] as num?)?.toStringAsFixed(2) ?? 'N/A'} DH/an', false, color),
        PdfExportService._buildTableRow('ROI (Retour sur Investissement)', '${(financial['roi'] as num?)?.toStringAsFixed(2) ?? 'N/A'} années', false, color),
        PdfExportService._buildTableRow('NPV (20 ans)', '${(financial['npv20'] as num?)?.toStringAsFixed(2) ?? 'N/A'} DH', false, color),
        PdfExportService._buildTableRow('IRR (Taux de rendement interne)', '${(financial['irr'] as num?)?.toStringAsFixed(2) ?? 'N/A'}%', false, color),
        PdfExportService._buildTableRow('Économies cumulées (10 ans)', '${(financial['cumulativeSavings10'] as num?)?.toStringAsFixed(2) ?? 'N/A'} DH', false, color),
        PdfExportService._buildTableRow('Économies cumulées (20 ans)', '${(financial['cumulativeSavings20'] as num?)?.toStringAsFixed(2) ?? 'N/A'} DH', false, color),
      ],
    );
  }
  
  static pw.Widget _buildEnvironmentalSection(Map<String, dynamic> environmental, PdfColor color) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        PdfExportService._buildTableRow('Production PV annuelle', '${(environmental['annualPvProduction'] as num?)?.toStringAsFixed(0) ?? 'N/A'} kWh/an', true, color),
        PdfExportService._buildTableRow('CO₂ évité', '${(environmental['co2Avoided'] as num?)?.toStringAsFixed(2) ?? 'N/A'} tonnes/an', false, color),
        PdfExportService._buildTableRow('Équivalent arbres plantés', '${(environmental['equivalentTrees'] as num?)?.toStringAsFixed(0) ?? 'N/A'} arbres', false, color),
        PdfExportService._buildTableRow('Équivalent voitures retirées', '${(environmental['equivalentCars'] as num?)?.toStringAsFixed(0) ?? 'N/A'} voitures', false, color),
      ],
    );
  }
  
  static pw.Widget _buildDetailedScoreSection(Map<String, dynamic> globalScore, PdfColor color) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        PdfExportService._buildTableRow('Score Global', '${(globalScore['globalScore'] as num?)?.toStringAsFixed(1) ?? 'N/A'}/100', true, color),
        PdfExportService._buildTableRow('Score autonomie', '${(globalScore['autonomyScore'] as num?)?.toStringAsFixed(1) ?? 'N/A'}/100', false, color),
        PdfExportService._buildTableRow('Score Économique', '${(globalScore['economicScore'] as num?)?.toStringAsFixed(1) ?? 'N/A'}/100', false, color),
        PdfExportService._buildTableRow('Score Résilience', '${(globalScore['resilienceScore'] as num?)?.toStringAsFixed(1) ?? 'N/A'}/100', false, color),
        PdfExportService._buildTableRow('Score Environnemental', '${(globalScore['environmentalScore'] as num?)?.toStringAsFixed(1) ?? 'N/A'}/100', false, color),
      ],
    );
  }
  
  static pw.Widget _buildBeforeAfterSection(Map<String, dynamic> beforeAfter) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        PdfExportService._buildTableHeaderRow(['Métrique', 'Avant', 'Après']),
        PdfExportService._buildComparisonRow(
          'Consommation mensuelle',
          '${(beforeAfter['beforeGridConsumption'] as num?)?.toStringAsFixed(0) ?? 'N/A'} kWh',
          '${(beforeAfter['afterGridConsumption'] as num?)?.toStringAsFixed(0) ?? 'N/A'} kWh',
        ),
        PdfExportService._buildComparisonRow(
          'Facture mensuelle',
          '${(beforeAfter['beforeMonthlyBill'] as num?)?.toStringAsFixed(0) ?? 'N/A'} DH',
          '${(beforeAfter['afterMonthlyBill'] as num?)?.toStringAsFixed(0) ?? 'N/A'} DH',
        ),
        PdfExportService._buildComparisonRow(
          'Autonomie énergétique',
          '${(beforeAfter['beforeAutonomy'] as num?)?.toStringAsFixed(1) ?? '0'}%',
          '${(beforeAfter['afterAutonomy'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%',
        ),
      ],
    );
  }
  
  static pw.Widget _buildTechnicalRecommendations(RecommendationsResponse recommendations, Map<String, dynamic> comprehensiveResults) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfExportService._buildInfoRow('Puissance PV recommandée', '${recommendations.recommendedPvPower.toStringAsFixed(2)} kW', true),
        PdfExportService._buildInfoRow('Capacité batterie recommandée', '${recommendations.recommendedBatteryCapacity.toStringAsFixed(2)} kWh', true),
        PdfExportService._buildInfoRow('Surface PV nécessaire', '~${(recommendations.recommendedPvPower * 5).toStringAsFixed(0)} m² (approximatif)', true),
        PdfExportService._buildInfoRow('Autonomie énergétique', '${recommendations.energyAutonomy.toStringAsFixed(2)}%', true),
        if (comprehensiveResults['resilience'] != null) ...[
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Métriques de Résilience',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if ((comprehensiveResults['resilience'] as Map)['autonomyHours'] != null)
            PdfExportService._buildInfoRow('Autonomie totale', '${((comprehensiveResults['resilience'] as Map)['autonomyHours'] as num).toStringAsFixed(1)} heures', false),
          if ((comprehensiveResults['resilience'] as Map)['criticalAutonomyHours'] != null)
            PdfExportService._buildInfoRow('Autonomie services critiques', '${((comprehensiveResults['resilience'] as Map)['criticalAutonomyHours'] as num).toStringAsFixed(1)} heures', false),
        ],
      ],
    );
  }
  
  static pw.TableRow _buildTableRow(String label, String value, bool isHeader, PdfColor color) {
    return pw.TableRow(
      decoration: isHeader ? pw.BoxDecoration(color: color) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.white : PdfColors.black,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.white : PdfColors.black,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
  
  static pw.TableRow _buildTableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey700),
      children: headers.map((header) => pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          header,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      )).toList(),
    );
  }
  
  static pw.TableRow _buildComparisonRow(String metric, String before, String after) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            metric,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            before,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.red700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            after,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.green700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }
}
