import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/clinical_scoring.dart';
import '../../core/utils/formatters.dart';
import '../../models/medical.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/charts.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/common/upload_area.dart';
import '../../widgets/medical/medical_widgets.dart';

/// Web `detection/mri-analysis.component` ("NeuroScan AI"): 3-step wizard
/// (patient file, clinical questionnaire, MRI) and the analysis report.
class DetectionTab extends StatefulWidget {
  const DetectionTab({super.key});

  @override
  State<DetectionTab> createState() => _DetectionTabState();
}

class _DetectionTabState extends State<DetectionTab> {
  static const List<(String, IconData)> _steps = [
    ('Dossier patient', Icons.badge_outlined),
    ('Questionnaire', Icons.checklist_rounded),
    ('Imagerie IRM', Icons.psychology_outlined),
  ];

  static const Map<String, IconData> _itemIcons = {
    'memoire': Icons.psychology_outlined,
    'confusion': Icons.sync_problem_rounded,
    'langage': Icons.speaker_notes_off_outlined,
    'comportement': Icons.mood_bad_outlined,
    'depression': Icons.sentiment_dissatisfied_outlined,
    'autonomie': Icons.accessible_rounded,
    'familiaux': Icons.family_restroom_rounded,
    'avc': Icons.bolt_rounded,
    'hta': Icons.monitor_heart_outlined,
    'diabete': Icons.water_drop_outlined,
    'depression2': Icons.cloud_outlined,
    'tc': Icons.personal_injury_outlined,
  };

  final _name = TextEditingController();
  final _patientId = TextEditingController();
  final _age = TextEditingController();
  String? _gender;

  final Set<String> _symptoms = {};
  final Set<String> _antecedents = {};
  String? _duration;

  int _step = 0;
  final _scroll = ScrollController();

  /// Changes step and brings the stepper back into view.
  void _goTo(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.animateTo(0, duration: AppDurations.normal, curve: Curves.easeOut);
  }

  // Selected MRI file and AI result, filled by the picker / detection API.
  String? _imageName;
  MriAnalysis? _analysis;

  int? get _ageValue => int.tryParse(_age.text);
  int get _ageRisk => ClinicalScoring.ageRisk(_ageValue);
  int? get _aiRisk => _analysis == null ? null : ClinicalScoring.stageRisk(_analysis!.prediction);
  int get _globalRisk => ClinicalScoring.globalRisk(ageRisk: _ageRisk, aiRisk: _aiRisk);
  double get _qScore =>
      ClinicalScoring.questionnaireScore(symptoms: _symptoms, antecedents: _antecedents, duration: _duration);

  Set<int> get _completed => {
        if (_name.text.trim().isNotEmpty && (_ageValue ?? 0) > 0) 0,
        if (_qScore > 0) 1,
        if (_analysis != null) 2,
      };

  @override
  void dispose() {
    _scroll.dispose();
    _name.dispose();
    _patientId.dispose();
    _age.dispose();
    super.dispose();
  }

  void _runAnalysis() {}

  void _exportPdf() {}

  void _reset() => setState(() {
        _name.clear();
        _patientId.clear();
        _age.clear();
        _gender = null;
        _symptoms.clear();
        _antecedents.clear();
        _duration = null;
        _imageName = null;
        _analysis = null;
        _step = 0;
      });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scroll,
      padding: AppSpacing.screen,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const _NeuroHeader(),
        const SizedBox(height: AppSpacing.lg),
        WizardStepper(
          steps: _steps,
          current: _step,
          completed: _completed,
          onStepTap: _goTo,
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppDurations.normal,
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              0 => _patientStep(),
              1 => _questionnaireStep(),
              _ => _mriStep(),
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_analysis == null) _summary() else _Report(
          analysis: _analysis!,
          patientName: _name.text,
          age: _ageValue,
          questionnaireScore: _qScore,
          ageRisk: _ageRisk,
          globalRisk: _globalRisk,
          onReset: _reset,
          onExport: _exportPdf,
        ),
      ],
    );
  }

  // ── Step 1 ────────────────────────────────────────────────────────────────
  Widget _patientStep() {
    final text = Theme.of(context).textTheme;
    final band = ClinicalScoring.globalBand(_globalRisk);
    return _StepPanel(
      icon: Icons.badge_outlined,
      title: 'Dossier patient',
      subtitle: 'Renseignez les informations du patient',
      children: [
        AppTextField(label: 'Nom complet', controller: _name, hint: 'Ex : Ahmed Fares', onChanged: (_) => setState(() {})),
        AppTextField(label: 'ID Patient', controller: _patientId, hint: 'Ex : 6849ab3f1c2d4e5f6789abcd'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDropdownField<String>(
                label: 'Genre',
                value: _gender,
                hint: '—',
                items: const ['F', 'M', 'A'],
                itemLabel: (g) => switch (g) { 'F' => 'Féminin', 'M' => 'Masculin', _ => 'Autre' },
                onChanged: (g) => setState(() => _gender = g),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Âge (ans)',
                controller: _age,
                hint: '72',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if ((_ageValue ?? 0) > 0)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(color: MedColors.neuroBg, borderRadius: AppRadius.lgAll),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Indice de risque global', style: text.titleSmall)),
                    const AppChip(label: 'IA × Âge', background: AppColors.white, foreground: MedColors.neuroDeep, dense: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ArcGauge(value: _globalRisk.toDouble(), color: band.globalColor),
                const SizedBox(height: AppSpacing.sm),
                _RiskBar(label: 'Risque épidémiologique (âge)', value: _ageRisk, color: MedColors.neuroPale),
                _RiskBar(
                  label: _aiRisk == null ? 'Risque IA (disponible après analyse IRM)' : 'Risque IA détecté',
                  value: _aiRisk,
                  color: _analysis?.prediction.riskColor ?? MedColors.grayLight,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(ClinicalScoring.globalMessage(band), style: text.bodySmall?.copyWith(color: MedColors.ink)),
              ],
            ),
          )
        else
          const FeedbackBanner(kind: BannerKind.info, message: "Saisissez l'âge pour calculer l'indice de risque global"),
        const SizedBox(height: AppSpacing.lg),
        _StepNav(onNext: () => _goTo(1), nextLabel: 'Suivant — Questionnaire'),
      ],
    );
  }

  // ── Step 2 ────────────────────────────────────────────────────────────────
  Widget _questionnaireStep() {
    final text = Theme.of(context).textTheme;
    final score = _qScore;
    final band = ClinicalScoring.questionnaireBand(score);
    Widget checks(List<ClinicalItem> items, Set<String> selected) => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              FilterChip(
                avatar: Icon(_itemIcons[item.key], size: AppSizes.iconSm),
                label: Text(item.label),
                selected: selected.contains(item.key),
                onSelected: (on) => setState(() => on ? selected.add(item.key) : selected.remove(item.key)),
              ),
          ],
        );
    return _StepPanel(
      icon: Icons.checklist_rounded,
      title: 'Questionnaire clinique',
      subtitle: 'Évaluez les symptômes et antécédents',
      children: [
        Text('1  Symptômes rapportés', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        checks(ClinicalQuestionnaire.symptoms, _symptoms),
        const SizedBox(height: AppSpacing.lg),
        Text('2  Antécédents médicaux', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        checks(ClinicalQuestionnaire.antecedents, _antecedents),
        const SizedBox(height: AppSpacing.lg),
        Text('3  Durée des symptômes', style: text.titleSmall),
        RadioGroup<String>(
          groupValue: _duration,
          onChanged: (v) => setState(() => _duration = v),
          child: Column(
            children: [
              for (final d in ClinicalQuestionnaire.durations)
                RadioListTile<String>(value: d.key, title: Text(d.label), dense: true, contentPadding: EdgeInsets.zero),
            ],
          ),
        ),
        if (score > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: band.questionnaireColor),
              color: band.questionnaireColor.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(score.toStringAsFixed(1), style: text.headlineMedium?.copyWith(color: band.questionnaireColor)),
                    Text('/10 · Score clinique', style: text.labelSmall),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ClinicalScoring.questionnaireLabel(band),
                        style: text.titleSmall?.copyWith(color: band.questionnaireColor),
                      ),
                      Text(ClinicalScoring.questionnaireMessage(band), style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _StepNav(
          onPrevious: () => _goTo(0),
          onNext: () => _goTo(2),
          nextLabel: 'Suivant — Imagerie IRM',
        ),
      ],
    );
  }

  // ── Step 3 ────────────────────────────────────────────────────────────────
  Widget _mriStep() {
    final text = Theme.of(context).textTheme;
    return _StepPanel(
      icon: Icons.psychology_outlined,
      title: 'Imagerie IRM',
      subtitle: 'Chargez et analysez le scan cérébral',
      children: [
        UploadArea(
          icon: Icons.upload_file_rounded,
          title: _imageName ?? 'Sélectionner une image IRM',
          subtitle: 'Formats acceptés : PNG, JPG, JPEG',
          height: AppSizes.uploadHeight,
        ),
        const SizedBox(height: AppSpacing.md),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: const BoxDecoration(color: MedColors.scanBg, borderRadius: AppRadius.lgAll),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology_alt_outlined, size: AppSizes.iconXl * 1.5, color: MedColors.scanLine),
                const SizedBox(height: AppSpacing.sm),
                Text('Aucune image IRM chargée', style: text.bodyMedium?.copyWith(color: MedColors.neuroPale)),
                Text('Formats acceptés : PNG, JPG, JPEG', style: text.bodySmall?.copyWith(color: MedColors.scanLine)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: MedColors.neuro),
          onPressed: _imageName == null ? null : _runAnalysis,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Analyser'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StepNav(onPrevious: () => _goTo(1)),
      ],
    );
  }

  /// Right-panel summary of the web wizard ("wz-summary").
  Widget _summary() {
    final text = Theme.of(context).textTheme;
    final (title, message) = switch (_step) {
      0 => ('Remplissez le dossier patient', 'Saisissez les informations du patient puis appuyez sur Suivant.'),
      1 => ('Complétez le questionnaire', "Évaluez les symptômes cliniques puis passez à l'étape suivante."),
      _ => ('Chargez une image IRM', 'Sélectionnez une IRM cérébrale pour continuer.'),
    };
    return AppCard(
      child: Column(
        children: [
          const StageTrack(),
          const SizedBox(height: AppSpacing.lg),
          const Icon(Icons.biotech_outlined, size: AppSizes.iconXl, color: MedColors.neuro),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          Text(message, style: text.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < _steps.length; i++)
            ListTile(
              dense: true,
              leading: Icon(
                _completed.contains(i) ? Icons.check_circle_rounded : _steps[i].$2,
                color: _completed.contains(i) ? MedColors.riskGreen : MedColors.neuro,
              ),
              title: Text(_steps[i].$1),
              trailing: switch (i) {
                0 when _name.text.isNotEmpty => Text(_name.text, style: text.bodySmall),
                1 when _qScore > 0 => Text('Score : ${_qScore.toStringAsFixed(1)}/10', style: text.bodySmall),
                _ => null,
              },
            ),
        ],
      ),
    );
  }
}

class _NeuroHeader extends StatelessWidget {
  const _NeuroHeader();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: AppSizes.avatarLg - 8,
          height: AppSizes.avatarLg - 8,
          decoration: const BoxDecoration(gradient: AppGradients.neuro, shape: BoxShape.circle),
          child: const Icon(Icons.waves_rounded, color: AppColors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'NeuroScan ', style: text.titleLarge?.copyWith(color: MedColors.ink)),
                  TextSpan(text: 'AI', style: text.titleLarge?.copyWith(color: MedColors.neuroPink)),
                ]),
              ),
              Text("Détection assistée par IA · Maladie d'Alzheimer · EfficientNetB3", style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({required this.icon, required this.title, required this.subtitle, required this.children});

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: MedColors.neuroBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: subtitle, icon: icon, color: MedColors.neuroDeep),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _StepNav extends StatelessWidget {
  const _StepNav({this.onPrevious, this.onNext, this.nextLabel});

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onPrevious != null)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Précédent'),
          ),
        const Spacer(),
        if (onNext != null)
          Flexible(
            flex: 3,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MedColors.neuro,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              iconAlignment: IconAlignment.end,
              label: Text(nextLabel ?? 'Suivant', overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    );
  }
}

class _RiskBar extends StatelessWidget {
  const _RiskBar({required this.label, required this.value, required this.color});

  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(label, style: text.bodySmall)),
          Expanded(flex: 4, child: ProgressTrack(value: (value ?? 0) / 100, color: color, trackColor: AppColors.white)),
          SizedBox(
            width: AppSizes.valueColumn,
            child: Text(value == null ? '—' : '$value%', textAlign: TextAlign.end, style: text.labelMedium),
          ),
        ],
      ),
    );
  }
}

/// Analysis report (web right panel "RAPPORT D'ANALYSE IRM").
class _Report extends StatelessWidget {
  const _Report({
    required this.analysis,
    required this.patientName,
    required this.age,
    required this.questionnaireScore,
    required this.ageRisk,
    required this.globalRisk,
    required this.onReset,
    required this.onExport,
  });

  final MriAnalysis analysis;
  final String patientName;
  final int? age;
  final double questionnaireScore;
  final int ageRisk;
  final int globalRisk;
  final VoidCallback onReset;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stage = analysis.prediction;
    final band = ClinicalScoring.globalBand(globalRisk);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StageTrack(active: stage),
        const SizedBox(height: AppSpacing.lg),
        Text("RAPPORT D'ANALYSE IRM", style: text.labelMedium?.copyWith(color: MedColors.neuroDeep)),
        Text(
          '${patientName.isEmpty ? 'Anonyme' : patientName}${age == null ? '' : ' · $age ans'} · ${Formatters.dateTime(analysis.date)}',
          style: text.bodySmall,
        ),
        if (questionnaireScore > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Builder(builder: (context) {
            final qBand = ClinicalScoring.questionnaireBand(questionnaireScore);
            return FeedbackBanner(
              kind: BannerKind.info,
              message: 'Score clinique pré-analyse : ${questionnaireScore.toStringAsFixed(1)}/10 — '
                  '${ClinicalScoring.questionnaireLabel(qBand)}',
            );
          }),
        ],
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: stage.riskColor.withValues(alpha: 0.08),
          borderColor: stage.riskColor.withValues(alpha: 0.4),
          child: Row(
            children: [
              Icon(stage.icon, color: stage.riskColor, size: AppSizes.iconXl * 0.8),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diagnostic IA', style: text.labelSmall),
                    Text(stage.label, style: text.titleMedium?.copyWith(color: stage.riskColor)),
                    Text(stage.description, style: text.bodySmall),
                  ],
                ),
              ),
              Column(
                children: [
                  AppChip(label: analysis.riskLevel.label, background: stage.riskColor, foreground: AppColors.white, dense: true),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${analysis.confidence.toStringAsFixed(1)}%', style: text.labelMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Score de risque global — IA × Âge',
                icon: Icons.biotech_outlined,
                color: MedColors.neuroDeep,
                trailing: Text('$globalRisk/100', style: text.titleMedium?.copyWith(color: band.globalColor)),
              ),
              _RiskBar(label: 'Risque épidémiologique', value: ageRisk, color: MedColors.neuroSoft),
              _RiskBar(label: 'Risque IA détecté', value: ClinicalScoring.stageRisk(stage), color: stage.riskColor),
              Text(ClinicalScoring.globalMessage(band), style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Indice de confiance du modèle', style: text.titleSmall)),
                  Text('${analysis.confidence.toStringAsFixed(1)}%', style: text.titleSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ProgressTrack(value: analysis.confidence / 100, color: stage.riskColor, trackColor: MedColors.neuroBg),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Distribution des probabilités', icon: Icons.bar_chart_rounded, color: MedColors.neuroDeep),
              ProbabilityList(analysis: analysis),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const FeedbackBanner(
          kind: BannerKind.info,
          message: 'Ce rapport est produit à titre indicatif uniquement. Tout diagnostic doit être confirmé par un '
              'médecin spécialiste qualifié.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Nouvelle analyse'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: MedColors.neuro),
                onPressed: onExport,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
