import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_routes.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/medical.dart';
import '../../services/medical_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/async_state_view.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';

/// Web `follow-up/follow-up.component` — view 1: patient list.
class FollowUpTab extends StatefulWidget {
  const FollowUpTab({super.key});

  @override
  State<FollowUpTab> createState() => _FollowUpTabState();
}

class _FollowUpTabState extends State<FollowUpTab> {
  List<FollowUpPatient> _patients = [];
  ViewStatus _status = ViewStatus.loading;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Patients of the platform (User-Service, role PATIENT_PROFILE).
  Future<void> _load() async {
    setState(() {
      _status = ViewStatus.loading;
      _error = null;
    });
    try {
      await AuthSession.instance.ensureSignedIn();
      final patients = await MedicalService.instance.getPatients();
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _status = ViewStatus.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = ViewStatus.error;
        _error = ApiException.describe(e);
      });
    }
  }

  List<FollowUpPatient> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _patients;
    return _patients.where((p) => '${p.fullName} ${p.email} ${p.condition}'.toLowerCase().contains(q)).toList();
  }

  /// Web `getPatientStageColor`: by condition.
  Color _colorOf(FollowUpPatient p) {
    final c = p.condition.toLowerCase();
    if (c.contains('alzheimer')) return MedColors.stageMild;
    if (c.contains('parkinson')) return MedColors.stageNon;
    return MedColors.stageVeryMild;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppSpacing.screen,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          PageIntro(
            title: 'Dossiers Médicaux Patients',
            subtitle: 'Sélectionnez un patient pour accéder à son dossier IRM complet',
            trailing: _patients.isEmpty
                ? null
                : Column(
                    children: [
                      Text('${_patients.length}', style: text.titleLarge?.copyWith(color: ModuleColors.medical)),
                      Text('Patients', style: text.labelSmall),
                    ],
                  ),
          ),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, rôle, email…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixText: _query.isEmpty ? null : '${filtered.length} résultat(s)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AsyncStateView(
            status: _status,
            isEmpty: filtered.isEmpty,
            errorMessage: _error,
            onRetry: _load,
            loading: const LoadingView(message: 'Chargement des patients…'),
            empty: EmptyStateView(
              icon: Icons.person_off_outlined,
              title: _query.isEmpty ? 'Aucun patient' : 'Aucun patient trouvé pour « $_query »',
            ),
            builder: (context) => Column(
              children: [
                for (final p in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      onTap: () => context.push(AppRoutes.patientDossier(p.id), extra: p),
                      child: Row(
                        children: [
                          InitialsAvatar(initials: p.initials, color: _colorOf(p)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.fullName, style: text.titleSmall),
                                Text(p.email, style: text.bodySmall, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: AppSpacing.xs),
                                AppChip(
                                  icon: Icons.sell_outlined,
                                  label: p.condition,
                                  background: _colorOf(p).withValues(alpha: 0.1),
                                  foreground: _colorOf(p),
                                  dense: true,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.folder_open_outlined, color: _colorOf(p)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
