import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/medical.dart';

/// Medical follow-up, through the gateway:
/// - Detection-Maladie-Service (`/api/detection/**`): MRI analysis by the AI
///   model (Flask, EfficientNetB3) and the stored MRI images;
/// - Dossier-Medical-Service (`/api/dossiers/**`): a patient's dossier, filled
///   by Detection after each analysis, editable by the doctor;
/// - User-Service: the patients list.
///
/// [revision] changes after every write so the screens showing a dossier reload.
class MedicalService {
  MedicalService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  static final MedicalService instance = MedicalService();

  /// The model runs on CPU; its first prediction can take a while.
  static const Duration analysisTimeout = Duration(seconds: 90);

  final ApiClient _api;
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<List<FollowUpPatient>> getPatients() async {
    final json = await _api.get('/api/users/by-role/PATIENT_PROFILE');
    return (json as List).whereType<Map<String, dynamic>>().map(FollowUpPatient.fromJson).toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  /// `null` when the patient has no dossier yet (no MRI analysis: HTTP 404).
  Future<MedicalDossier?> getDossier(String patientId) async {
    try {
      return MedicalDossier.fromJson(await _api.get('/api/dossiers/patient/$patientId') as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Step 3 of the NeuroScan wizard: sends the MRI to the AI model. The result is
  /// also added to the patient's dossier by the Detection service.
  Future<MriAnalysis> analyseMri({
    required String patientId,
    required List<int> bytes,
    required String filename,
  }) async {
    final json = await _api.upload(
      '/api/detection/analyser',
      field: 'image',
      bytes: bytes,
      filename: filename,
      query: {'patientId': patientId},
      timeout: analysisTimeout,
    );
    revision.value++;
    return MriAnalysis.fromJson(json as Map<String, dynamic>);
  }

  /// Doctor's edit of an analysis of a dossier ([analysisId] = dossier-side id).
  Future<MedicalDossier> updateAnalysis(
    int analysisId, {
    required String description,
    String? doctorAdvice,
    String? clinicalNotes,
  }) async {
    final json = await _api.put(
      '/api/dossiers/analyse/update-description',
      body: {
        'analyseId': analysisId,
        'descriptionRisque': description,
        'conseilMedecin': doctorAdvice,
        'notesCliniques': clinicalNotes,
      },
    );
    revision.value++;
    return MedicalDossier.fromJson(json as Map<String, dynamic>);
  }

  Future<MedicalDossier> deleteAnalysis(int analysisId) async {
    final json = await _api.delete('/api/dossiers/analyse/$analysisId');
    revision.value++;
    return MedicalDossier.fromJson(json as Map<String, dynamic>);
  }

  /// Stored MRI image of an analysis.
  static String imageUrl(String fileName) =>
      ApiConfig.mediaUrl('/api/detection/image/${Uri.encodeComponent(fileName)}')!;
}
