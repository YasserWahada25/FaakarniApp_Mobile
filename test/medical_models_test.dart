import 'package:fakarniapp/models/medical.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON shapes of Dossier-Medical-Service (`DossierMedicalResponse`),
/// Detection-Maladie-Service (`AnalyseIRMResponse`) and User-Service.
void main() {
  Map<String, dynamic> analysis(int id, String prediction, String date, {String risk = 'MODERE'}) => {
    'id': id,
    'analyseIrmId': id + 100,
    'nomFichier': '1731060000000_scan$id.jpg',
    'prediction': prediction,
    'confidence': 96.05,
    'niveauRisque': risk,
    'couleurRisque': 'ORANGE',
    'descriptionRisque': 'Signes détectés.',
    'conseilMedecin': null,
    'notesCliniques': 'RAS',
    'probMildDemented': 96.05,
    'probModerateDemented': 1.2,
    'probNonDemented': 0.5,
    'probVeryMildDemented': 2.25,
    'dateAnalyse': date,
  };

  test('MedicalDossier.fromJson sorts analyses newest first', () {
    final dossier = MedicalDossier.fromJson({
      'id': 1,
      'patientId': '6af03c5566019019914eaaa2',
      'dateCreation': '2026-11-01T10:00:00',
      'dateDerniereMaj': '2026-11-08T10:00:00',
      'dernierePrediction': 'Mild_Demented',
      'nombreAnalyses': 2,
      'analyses': [
        analysis(1, 'Non_Demented', '2026-11-01T10:00:00', risk: 'AUCUN'),
        analysis(2, 'Mild_Demented', '2026-11-08T10:00:00'),
      ],
    });
    expect(dossier.analyses.map((a) => a.id), [2, 1]);
    final latest = dossier.latest!;
    expect(latest.prediction, DementiaStage.mild);
    expect(latest.riskLevel, RiskLevel.moderate);
    expect(latest.probabilities[DementiaStage.mild], 96.05);
    expect(latest.clinicalNotes, 'RAS');
    expect(latest.doctorAdvice, isNull);
    expect(latest.estimatedMmse, 16);
    expect(dossier.analyses.last.riskLevel, RiskLevel.low);
  });

  test('RiskLevel.fromLabel falls back on the stage', () {
    expect(RiskLevel.fromLabel('ÉLEVÉ', DementiaStage.mild), RiskLevel.high);
    expect(RiskLevel.fromLabel(null, DementiaStage.moderate), RiskLevel.high);
    expect(RiskLevel.fromLabel('?', DementiaStage.nonDemented), RiskLevel.low);
  });

  test('FollowUpPatient.fromJson', () {
    final p = FollowUpPatient.fromJson({
      'id': '6af03c',
      'nom': 'Yasser',
      'prenom': 'Wahada',
      'email': 'w@x.tn',
      'role': 'PATIENT_PROFILE',
      'numTel': '42335596',
    });
    expect(p.fullName, 'Wahada Yasser');
    expect(p.initials, 'WY');
    expect(p.condition, 'Patient');

    final unnamed = FollowUpPatient.fromJson({'id': 'x', 'email': 'anon@x.tn'});
    expect(unnamed.fullName, 'anon@x.tn');
    expect(unnamed.initials, 'A');
  });
}
