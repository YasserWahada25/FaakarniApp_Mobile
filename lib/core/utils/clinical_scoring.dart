import '../../models/medical.dart';

/// Risk bands shared by the global risk index and the clinical questionnaire.
enum RiskBand { low, moderate, high, critical }

/// Scoring rules of the web NeuroScan page (mri-analysis.component.ts).
abstract final class ClinicalScoring {
  /// Epidemiological risk (%) from the patient's age.
  static int ageRisk(int? age) {
    if (age == null || age <= 0) return 0;
    if (age < 60) return 2;
    if (age < 65) return 5;
    if (age < 70) return 8;
    if (age < 75) return 13;
    if (age < 80) return 20;
    if (age < 85) return 32;
    if (age < 90) return 45;
    return 60;
  }

  /// Risk (%) associated with a predicted stage.
  static int stageRisk(DementiaStage stage) => switch (stage) {
        DementiaStage.nonDemented => 5,
        DementiaStage.veryMild => 35,
        DementiaStage.mild => 65,
        DementiaStage.moderate => 90,
      };

  /// Global index = 60 % AI + 40 % age once the MRI is analysed, age only before.
  static int globalRisk({required int ageRisk, int? aiRisk}) =>
      aiRisk == null ? ageRisk : (aiRisk * 0.6 + ageRisk * 0.4).round();

  static RiskBand globalBand(int pct) => pct <= 15
      ? RiskBand.low
      : pct <= 35
          ? RiskBand.moderate
          : pct <= 60
              ? RiskBand.high
              : RiskBand.critical;

  static String globalMessage(RiskBand band) => switch (band) {
        RiskBand.low => 'Risque global faible. Un suivi annuel standard est suffisant.',
        RiskBand.moderate => 'Risque modéré. Une surveillance neurologique rapprochée est recommandée.',
        RiskBand.high => 'Risque élevé. Consultation spécialisée et bilan complémentaire nécessaires.',
        RiskBand.critical => 'Risque très élevé. Prise en charge médicale urgente requise.',
      };

  /// Questionnaire score out of 10 (symptom = 1, antecedent = 0.5, duration 0–2).
  static double questionnaireScore({
    required Set<String> symptoms,
    required Set<String> antecedents,
    required String? duration,
  }) {
    double score = 0;
    for (final s in ClinicalQuestionnaire.symptoms) {
      if (symptoms.contains(s.key)) score += s.weight;
    }
    for (final a in ClinicalQuestionnaire.antecedents) {
      if (antecedents.contains(a.key)) score += a.weight;
    }
    for (final d in ClinicalQuestionnaire.durations) {
      if (d.key == duration) score += d.weight;
    }
    return (score * 10).round().clamp(0, 100) / 10;
  }

  static RiskBand questionnaireBand(double score) => score <= 2
      ? RiskBand.low
      : score <= 4
          ? RiskBand.moderate
          : score <= 7
              ? RiskBand.high
              : RiskBand.critical;

  static String questionnaireLabel(RiskBand band) => switch (band) {
        RiskBand.low => 'Profil rassurant',
        RiskBand.moderate => 'Vigilance modérée',
        RiskBand.high => 'Profil préoccupant',
        RiskBand.critical => 'Profil critique',
      };

  static String questionnaireMessage(RiskBand band) => switch (band) {
        RiskBand.low => "Peu de signes cliniques. L'analyse IRM permettra de confirmer.",
        RiskBand.moderate => 'Quelques indicateurs à surveiller. Un suivi neurologique est conseillé.',
        RiskBand.high => 'Plusieurs facteurs de risque présents. Consultation spécialisée recommandée.',
        RiskBand.critical => 'Cumul élevé de symptômes et antécédents. Prise en charge urgente recommandée.',
      };
}
