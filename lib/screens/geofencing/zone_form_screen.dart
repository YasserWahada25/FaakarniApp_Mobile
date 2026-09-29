import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../models/geofencing.dart';
import '../../widgets/common/app_map.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/geofencing/geo_widgets.dart';

/// Web live-tracking "New Zone / Edit Zone" modal, as a full-screen form.
class ZoneFormScreen extends StatefulWidget {
  const ZoneFormScreen({super.key, this.zone});

  /// `null` → creation, otherwise edition.
  final SafeZone? zone;

  @override
  State<ZoneFormScreen> createState() => _ZoneFormScreenState();
}

class _ZoneFormScreenState extends State<ZoneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.zone?.nomZone);
  late final _lat = TextEditingController(text: widget.zone?.centreLat.toString());
  late final _lon = TextEditingController(text: widget.zone?.centreLon.toString());
  late double _radius = (widget.zone?.rayon ?? 500).toDouble();
  late ZoneType _type = widget.zone?.type ?? ZoneType.safe;
  late String? _patientId = widget.zone?.patientId;

  // Filled by the users API (patients linked to the caregiver).
  final List<MonitoredPatient> _patients = [];

  bool get _isEdit => widget.zone != null;

  LatLng? get _center {
    final lat = double.tryParse(_lat.text);
    final lon = double.tryParse(_lon.text);
    return lat == null || lon == null ? null : LatLng(lat, lon);
  }

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final center = _center;
    return Scaffold(
      appBar: AppBar(leading: const CloseButton(), title: Text(_isEdit ? 'Edit Zone' : 'New Zone')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AppTextField(
                label: 'Zone name',
                required: true,
                controller: _name,
                hint: "e.g. Ahmed's Home",
                maxLength: 50,
                validator: (v) => Validators.required(v, 'Zone name is required.'),
              ),
              AppDropdownField<String>(
                label: 'Patient',
                required: true,
                value: _patientId,
                hint: '— Select a patient —',
                items: [for (final p in _patients) p.id],
                itemLabel: (id) => _patients.firstWhere((p) => p.id == id).fullName,
                onChanged: (v) => setState(() => _patientId = v),
                validator: (v) => v == null ? 'Please select a patient.' : null,
              ),
              if (_patients.isEmpty) ...[
                const FeedbackBanner(kind: BannerKind.info, message: 'No patients found.'),
                const SizedBox(height: AppSpacing.lg),
              ],
              LabeledField(
                label: 'Pick from map',
                child: AppMap(
                  center: center ?? AppConstants.defaultMapCenter,
                  height: AppSizes.mapHeight - 40,
                  onTap: (p) => setState(() {
                    _lat.text = p.latitude.toStringAsFixed(6);
                    _lon.text = p.longitude.toStringAsFixed(6);
                  }),
                  zones: [if (center != null) MapZone(center: center, radiusMeters: _radius, color: _type.color)],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      required: true,
                      controller: _lat,
                      hint: '36.8065',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: Validators.latitude,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      required: true,
                      controller: _lon,
                      hint: '10.1815',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: Validators.longitude,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              LabeledField(
                label: 'Radius: ${_radius.round()}m',
                child: Column(
                  children: [
                    Slider(
                      value: _radius,
                      min: AppConstants.zoneRadiusMin.toDouble(),
                      max: AppConstants.zoneRadiusMax.toDouble(),
                      divisions: (AppConstants.zoneRadiusMax - AppConstants.zoneRadiusMin) ~/ 50,
                      label: '${_radius.round()}m',
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${AppConstants.zoneRadiusMin}m', style: text.bodySmall),
                        Text('${AppConstants.zoneRadiusMax}m', style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              AppDropdownField<ZoneType>(
                label: 'Zone type',
                required: true,
                value: _type,
                items: ZoneType.values,
                itemLabel: (t) => t.optionLabel,
                onChanged: (t) => setState(() => _type = t ?? _type),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: _type.background, borderRadius: AppRadius.mdAll),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: AppSizes.iconSm - 4, color: _type.color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${_type.code} — ', style: text.titleSmall?.copyWith(color: _type.color)),
                          TextSpan(text: _type.explanation),
                        ]),
                        style: text.bodySmall?.copyWith(color: AppColors.textMain),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Cancel'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: Icon(_isEdit ? Icons.save_outlined : Icons.check_rounded),
                      label: Text(_isEdit ? 'Update' : 'Create'),
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
}
