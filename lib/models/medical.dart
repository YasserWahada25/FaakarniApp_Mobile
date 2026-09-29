/// Medical module models (records, NeuroScan AI detection, follow-up dossiers).
class PatientProfile {
  const PatientProfile({
    required this.name,
    required this.age,
    required this.bloodType,
    required this.condition,
    required this.lastVisit,
  });

  final String name;
  final int age;
  final String bloodType;
  final String condition;
  final DateTime lastVisit;
}

class Vitals {
  const Vitals({required this.bloodPressure, required this.heartRate, required this.weight, required this.temperature});

  final String bloodPressure;
  final int heartRate;
  final int weight;
  final double temperature;
}

class MedicalHistoryEntry {
  const MedicalHistoryEntry({
    required this.date,
    required this.type,
    required this.doctor,
    required this.diagnosis,
    required this.treatment,
  });

  final DateTime date;
  final String type;
  final String doctor;
  final String diagnosis;
  final String treatment;
}

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
}

enum RiskLevel {
  low('Faible'),
  moderate('Modéré'),
  high('Élevé'),
  critical('Critique');

  const RiskLevel(this.label);
  final String label;
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
  });

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

  /// Estimated MMSE derived from the stage (used by the follow-up gauges).
  int get estimatedMmse => switch (prediction) {
        DementiaStage.nonDemented => 28,
        DementiaStage.veryMild => 24,
        DementiaStage.mild => 19,
        DementiaStage.moderate => 13,
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

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String numTel;
  final String condition;

  String get fullName => '$nom $prenom';
  String get initials => '${nom[0]}${prenom[0]}'.toUpperCase();
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
