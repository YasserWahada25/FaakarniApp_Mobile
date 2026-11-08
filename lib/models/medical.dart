import '../core/network/json_parsing.dart';
import 'user.dart';

/// Medical module models (records, NeuroScan AI detection, follow-up dossiers).
/// Mini-Mental State Examination score (out of 30).
class MmsePoint {
  const MmsePoint(this.label, this.score);

  final String label;
  final int score;

  static const int max = 30;
}

/// The four classes predicted by the EfficientNetB3 model.
enum DementiaStage {
  nonDemented('Non_Demented', 'Non dément', 'Normal', 'I', 1),
  veryMild('Very_Mild_Demented', 'Très légèrement dément', 'Très léger', 'II', 2),
  mild('Mild_Demented', 'Légèrement dément', 'Léger', 'III', 3),
  moderate('Moderate_Demented', 'Modérément dément', 'Modéré', 'IV', 4);

  const DementiaStage(this.key, this.label, this.shortLabel, this.roman, this.number);

  final String key;
  final String label;
  final String shortLabel;
  final String roman;
  final int number;

  /// Class name returned by the AI model (`Mild_Demented`, …).
  static DementiaStage fromKey(Object? key) =>
      values.where((s) => s.key == key).firstOrNull ?? DementiaStage.nonDemented;
}

enum RiskLevel {
  low('Faible'),
  moderate('Modéré'),
  high('Élevé'),
  critical('Critique');

  const RiskLevel(this.label);
  final String label;

  /// Risk label of the AI model (`AUCUN`, `FAIBLE`, `MODERE`, `ELEVE`, …),
  /// falling back on the predicted stage.
  static RiskLevel fromLabel(Object? label, DementiaStage stage) {
    final l = (label?.toString() ?? '').toUpperCase().replaceAll('É', 'E').replaceAll('È', 'E');
    if (l.contains('CRITI') || l.contains('SEVERE')) return RiskLevel.critical;
    if (l.contains('ELEV') || l.contains('HAUT')) return RiskLevel.high;
    if (l.contains('MODER')) return RiskLevel.moderate;
    if (l.contains('FAIBLE') || l.contains('AUCUN') || l.contains('BAS')) return RiskLevel.low;
    return switch (stage) {
      DementiaStage.nonDemented || DementiaStage.veryMild => RiskLevel.low,
      DementiaStage.mild => RiskLevel.moderate,
      DementiaStage.moderate => RiskLevel.high,
    };
  }
}

class MriAnalysis {
  const MriAnalysis({
    required this.id,
    required this.fileName,
    required this.prediction,
    required this.confidence,
    required this.riskLevel,
    required this.description,
    required this.probabilities,
    required this.date,
    this.doctorAdvice,
    this.clinicalNotes,
  });

  /// Detection-Service `AnalyseIRMResponse` or an analysis of a Dossier-Medical-Service
  /// dossier (same field names; in a dossier [id] is the dossier-side id used to edit
  /// or delete it).
  factory MriAnalysis.fromJson(Map<String, dynamic> json) {
    final stage = DementiaStage.fromKey(json['prediction']);
    double pct(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return MriAnalysis(
      id: (json['id'] as num).toInt(),
      fileName: json['nomFichier']?.toString() ?? '',
      prediction: stage,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      riskLevel: RiskLevel.fromLabel(json['niveauRisque'], stage),
      description: json['descriptionRisque']?.toString() ?? '',
      probabilities: {
        DementiaStage.nonDemented: pct('probNonDemented'),
        DementiaStage.veryMild: pct('probVeryMildDemented'),
        DementiaStage.mild: pct('probMildDemented'),
        DementiaStage.moderate: pct('probModerateDemented'),
      },
      date: parseApiDate(json['dateAnalyse']),
      doctorAdvice: stringOrNull(json['conseilMedecin']),
      clinicalNotes: stringOrNull(json['notesCliniques']),
    );
  }

  final int id;
  final String fileName;
  final DementiaStage prediction;
  final double confidence;
  final RiskLevel riskLevel;
  final String description;

  /// Percent per stage (sums to ~100).
  final Map<DementiaStage, double> probabilities;
  final DateTime date;
  final String? doctorAdvice;
  final String? clinicalNotes;

  /// Indicative MMSE (/30) derived from the stage — same values as the web
  /// follow-up (`predictionToScore`).
  int get estimatedMmse => switch (prediction) {
    DementiaStage.nonDemented => 28,
    DementiaStage.veryMild => 22,
    DementiaStage.mild => 16,
    DementiaStage.moderate => 9,
  };
}

class MedicalDossier {
  const MedicalDossier({
    required this.id,
    required this.patientId,
    required this.createdAt,
    required this.updatedAt,
    required this.analyses,
  });

  /// Dossier-Medical-Service `DossierMedicalResponse`.
  factory MedicalDossier.fromJson(Map<String, dynamic> json) => MedicalDossier(
    id: (json['id'] as num).toInt(),
    patientId: json['patientId']?.toString() ?? '',
    createdAt: parseApiDate(json['dateCreation']),
    updatedAt: parseApiDate(json['dateDerniereMaj']),
    analyses:
        (json['analyses'] as List? ?? const []).whereType<Map<String, dynamic>>().map(MriAnalysis.fromJson).toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
  );

  final int id;
  final String patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Most recent first.
  final List<MriAnalysis> analyses;

  MriAnalysis? get latest => analyses.isEmpty ? null : analyses.first;
  DementiaStage? get lastPrediction => latest?.prediction;
}

/// Patient card of the follow-up list.
class FollowUpPatient {
  const FollowUpPatient({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numTel,
    required this.condition,
  });

  /// User-Service `UserResponse` of a patient.
  factory FollowUpPatient.fromJson(Map<String, dynamic> json) => FollowUpPatient(
    id: json['id'].toString(),
    nom: stringOrNull(json['nom']) ?? '',
    prenom: stringOrNull(json['prenom']) ?? '',
    email: stringOrNull(json['email']) ?? '',
    numTel: stringOrNull(json['numTel']) ?? '',
    condition: UserRole.values.where((r) => r.backendValue == json['role']).firstOrNull?.label ?? 'Patient',
  );

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String numTel;
  final String condition;

  String get fullName => '$prenom $nom'.trim().isEmpty ? email : '$prenom $nom'.trim();
  String get initials {
    final letters = [prenom, nom].where((p) => p.isNotEmpty).map((p) => p[0]).join();
    return (letters.isEmpty ? (email.isEmpty ? '?' : email[0]) : letters).toUpperCase();
  }
}

enum CognitiveTrend {
  improving('Improving'),
  stable('Stable'),
  declining('Declining'),
  insufficient('Insufficient data');

  const CognitiveTrend(this.label);
  final String label;
}

/// A checkbox / radio item of the clinical questionnaire.
class ClinicalItem {
  const ClinicalItem(this.key, this.label, this.weight);

  final String key;
  final String label;
  final double weight;
}

/// Static content of the clinical questionnaire (mri-analysis.component.ts).
abstract final class ClinicalQuestionnaire {
  static const List<ClinicalItem> symptoms = [
    ClinicalItem('memoire', 'Troubles de la mémoire', 1),
    ClinicalItem('confusion', 'Confusion / désorientation', 1),
    ClinicalItem('langage', 'Difficultés de langage', 1),
    ClinicalItem('comportement', 'Changements comportementaux', 1),
    ClinicalItem('depression', 'Dépression / anxiété', 1),
    ClinicalItem('autonomie', "Perte d'autonomie (AVQ)", 1),
  ];

  static const List<ClinicalItem> antecedents = [
    ClinicalItem('familiaux', 'ATCD familiaux Alzheimer', 0.5),
    ClinicalItem('avc', 'AVC ou AIT', 0.5),
    ClinicalItem('hta', 'Hypertension artérielle', 0.5),
    ClinicalItem('diabete', 'Diabète de type 2', 0.5),
    ClinicalItem('depression2', 'Dépression chronique', 0.5),
    ClinicalItem('tc', 'Traumatisme crânien', 0.5),
  ];

  static const List<ClinicalItem> durations = [
    ClinicalItem('aucun', 'Aucun symptôme', 0),
    ClinicalItem('lt6', 'Moins de 6 mois', 0.5),
    ClinicalItem('6_12', '6 à 12 mois', 1),
    ClinicalItem('gt12', 'Plus de 12 mois', 1.5),
    ClinicalItem('gt2ans', 'Plus de 2 ans', 2),
  ];
}

class Recommendation {
  const Recommendation({required this.title, required this.detail, required this.urgent});

  final String title;
  final String detail;
  final bool urgent;
}
