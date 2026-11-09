import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/session.dart';
import '../../providers/sessions_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_map.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/state_views.dart';

/// Web `sessions/reservation-form.component` ("Nouvelle demande de seance").
class ReservationFormScreen extends StatefulWidget {
  const ReservationFormScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  SessionAudience _audience = SessionAudience.private;
  SessionMode _mode = SessionMode.inPerson;
  late DateTime _date = widget.initialDate ?? DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 11, minute: 0);
  bool _submitted = false;
  bool _submitting = false;
  bool _locating = false;
  String? _error;

  bool get _timeRangeValid => _end.hour * 60 + _end.minute > _start.hour * 60 + _start.minute;

  LatLng? get _pickedPoint {
    final lat = double.tryParse(_lat.text);
    final lon = double.tryParse(_lon.text);
    return lat == null || lon == null ? null : LatLng(lat, lon);
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _address, _lat, _lon]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  void _pickOnMap(LatLng point) => setState(() {
        _lat.text = point.latitude.toStringAsFixed(6);
        _lon.text = point.longitude.toStringAsFixed(6);
      });

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    String? error;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        error = 'La geolocalisation est desactivee sur cet appareil.';
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          error = "L'acces a votre position a ete refuse.";
        } else {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
          );
          if (mounted) _pickOnMap(LatLng(position.latitude, position.longitude));
        }
      }
    } catch (_) {
      error = "Impossible d'obtenir votre position actuelle.";
    }
    if (!mounted) return;
    setState(() {
      _locating = false;
      _error = error;
    });
  }

  DateTime _at(TimeOfDay time) => DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || !_timeRangeValid || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final inPerson = _mode == SessionMode.inPerson;
    try {
      await SessionsProvider.instance.createReservation(ReservationRequest(
        title: _title.text,
        description: _description.text,
        start: _at(_start),
        end: _at(_end),
        mode: _mode,
        audience: _audience,
        locationAddress: inPerson ? _address.text : null,
        latitude: inPerson ? double.tryParse(_lat.text) : null,
        longitude: inPerson ? double.tryParse(_lon.text) : null,
      ));
      if (!mounted) return;
      showAppSnackBar(context, 'Demande envoyée. Le docteur va la traiter.');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Nouvelle demande de seance'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                "Envoyez votre demande. Le docteur l'acceptera ou la refusera.",
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Titre de la seance',
                controller: _title,
                hint: 'Ex: Suivi memoire hebdomadaire',
                required: true,
                validator: (v) => Validators.required(v, 'Le titre est obligatoire.') ??
                    Validators.minLength(v, 3, 'Minimum 3 caracteres.'),
              ),
              AppDropdownField<SessionAudience>(
                label: 'Type de seance',
                value: _audience,
                items: SessionAudience.values,
                itemLabel: (a) => a == SessionAudience.private ? 'Privee (patient + docteur)' : 'Groupe',
                onChanged: (a) => setState(() => _audience = a ?? _audience),
              ),
              AppTextField(
                label: 'Description',
                controller: _description,
                hint: 'Precisez votre besoin ou contexte medical...',
                maxLines: 3,
                required: true,
                validator: (v) => Validators.required(v, 'La description est obligatoire.') ??
                    Validators.minLength(v, 10, 'Minimum 10 caracteres.'),
              ),
              LabeledField(
                label: 'Date',
                required: true,
                child: _PickerTile(icon: Icons.calendar_today_outlined, value: Formatters.fullDate(_date), onTap: _pickDate),
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledField(
                      label: 'Debut',
                      child: _PickerTile(
                        icon: Icons.schedule_rounded,
                        value: _start.format(context),
                        onTap: () => _pickTime(start: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: LabeledField(
                      label: 'Fin',
                      child: _PickerTile(
                        icon: Icons.schedule_rounded,
                        value: _end.format(context),
                        onTap: () => _pickTime(start: false),
                      ),
                    ),
                  ),
                ],
              ),
              if (_submitted && !_timeRangeValid) ...[
                const FeedbackBanner(message: "L'heure de fin doit etre apres l'heure de debut."),
                const SizedBox(height: AppSpacing.lg),
              ],
              LabeledField(
                label: 'Mode de seance',
                child: RadioGroup<SessionMode>(
                  groupValue: _mode,
                  onChanged: (m) => setState(() => _mode = m ?? _mode),
                  child: const Row(
                    children: [
                      Expanded(child: RadioListTile(value: SessionMode.inPerson, title: Text('Presentielle'))),
                      Expanded(child: RadioListTile(value: SessionMode.online, title: Text('En ligne'))),
                    ],
                  ),
                ),
              ),
              if (_mode == SessionMode.online)
                const FeedbackBanner(
                  kind: BannerKind.info,
                  message: 'Lien de reunion genere automatiquement lors de la creation de la reunion video.',
                )
              else
                _locationSection(text),
              const SizedBox(height: AppSpacing.lg),
              FeedbackBanner(
                kind: BannerKind.info,
                message: 'Visibilite appliquee automatiquement: Privee (vous, les participants invites et '
                    "l'administrateur)",
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FeedbackBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Annuler'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: ModuleColors.alzheimer),
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Envoi...' : 'Envoyer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationSection(TextTheme text) {
    final point = _pickedPoint;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Localisation presentielle', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
            label: Text(_locating ? 'Localisation...' : 'Utiliser ma position'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppMap(
            center: point ?? AppConstants.defaultMapCenter,
            height: AppSizes.mapHeight - 40,
            onTap: _pickOnMap,
            pins: [if (point != null) MapPin(point: point, color: ModuleColors.alzheimerDeep)],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Touchez la carte pour definir la localisation exacte de la seance.', style: text.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Adresse', controller: _address, hint: 'Ex: Centre Fakarni, salle 2'),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Latitude',
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: Validators.latitude,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: 'Longitude',
                  controller: _lon,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: Validators.longitude,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.value, required this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.smAll,
        side: BorderSide(color: AppColors.bgSecondary),
      ),
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
