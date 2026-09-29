import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../models/meeting.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/common/upload_area.dart';

/// Web `reports/reports-dashboard.component`: meeting transcription and
/// automatic summary reports.
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final _title = TextEditingController();
  final _language = TextEditingController(text: 'fr');
  final _transcript = TextEditingController();

  // Filled by the meeting-insights API.
  final List<MeetingReport> _reports = [];
  final List<MeetingTranscription> _transcriptions = [];
  MeetingReport? _selectedReport;

  @override
  void dispose() {
    _title.dispose();
    _language.dispose();
    _transcript.dispose();
    super.dispose();
  }

  void _runTranscription() {}

  void _generateReport() {}

  void _refreshHistory() {}

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: AppSpacing.screen,
      children: [
        const PageIntro(
          title: 'Monitoring & Reports',
          subtitle: 'Transcrire une reunion et generer automatiquement un rapport de synthese.',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Meeting Insights', icon: Icons.mic_none_rounded, color: ModuleColors.alzheimerDeep),
              AppTextField(label: 'Titre reunion', controller: _title, hint: 'Ex: Reunion equipe soins'),
              AppTextField(label: 'Langue', controller: _language, hint: 'fr'),
              const LabeledField(
                label: 'Audio',
                child: UploadArea(
                  icon: Icons.audio_file_outlined,
                  title: 'Sélectionner un fichier audio',
                  subtitle: 'MP3, M4A, WAV',
                  height: AppSizes.uploadHeightMd,
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: ModuleColors.alzheimer),
                onPressed: _runTranscription,
                icon: const Icon(Icons.record_voice_over_outlined),
                label: const Text('Transcrire le discours'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('Generer le rapport'),
              ),
              TextButton.icon(
                onPressed: _refreshHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Rafraichir'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Rapports generes', icon: Icons.picture_as_pdf_outlined),
        if (_reports.isEmpty)
          const EmptyStateView(
            compact: true,
            icon: Icons.description_outlined,
            title: 'Aucun rapport généré',
            message: 'Les rapports de synthèse apparaîtront ici.',
          )
        else
          for (final r in _reports)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => setState(() => _selectedReport = r),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: AppColors.error, size: AppSizes.iconLg),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.meetingTitle, style: text.titleSmall),
                          Text(Formatters.medium(r.createdAt), style: text.bodySmall),
                        ],
                      ),
                    ),
                    const AppChip(label: 'Done', background: SessionColors.doneBg, foreground: SessionColors.doneFg),
                  ],
                ),
              ),
            ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Transcriptions', icon: Icons.subject_rounded),
        if (_transcriptions.isEmpty)
          const EmptyStateView(
            compact: true,
            icon: Icons.graphic_eq_rounded,
            title: 'Aucune transcription',
            message: 'Transcrivez un enregistrement pour le retrouver ici.',
          )
        else
          for (final t in _transcriptions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.filename),
              subtitle: Text('${Formatters.dateTime(t.createdAt)} • ${t.language}'),
              trailing: TextButton(
                onPressed: () => setState(() => _transcript.text = t.text),
                child: const Text('Voir transcript'),
              ),
            ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Texte transcrit', icon: Icons.notes_rounded),
        TextField(controller: _transcript, maxLines: 8, decoration: const InputDecoration(hintText: 'Transcription…')),
        if (_selectedReport != null) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Resume du discours', icon: Icons.auto_awesome_outlined),
          _ReportPreview(report: _selectedReport!),
        ],
      ],
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({required this.report});

  final MeetingReport report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget bullets(List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final i in items)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xxs),
                child: Text('• $i', style: text.bodyMedium),
              ),
          ],
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Summary: ', style: text.titleSmall),
            TextSpan(text: report.summary),
          ])),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Sentiment: ', style: text.titleSmall),
            TextSpan(text: '${report.sentimentLabel} (${report.sentimentScore})'),
          ])),
          const SizedBox(height: AppSpacing.sm),
          Text('Key points:', style: text.titleSmall),
          bullets(report.keyPoints),
          const SizedBox(height: AppSpacing.sm),
          Text('Action items:', style: text.titleSmall),
          bullets(report.actionItems),
        ],
      ),
    );
  }
}
