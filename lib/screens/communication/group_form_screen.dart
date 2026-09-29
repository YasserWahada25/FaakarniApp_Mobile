import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../models/communication.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/upload_area.dart';

/// Web groups "Créer un Nouveau Groupe" / "Modifier le Groupe" modals.
class GroupFormScreen extends StatefulWidget {
  const GroupFormScreen({super.key, this.group});

  /// `null` → creation, otherwise edition.
  final Group? group;

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.group?.name);
  late final _description = TextEditingController(text: widget.group?.description);
  late final _maxMembers = TextEditingController(text: widget.group?.maxMembers?.toString());
  late GroupType _type = widget.group?.groupType ?? GroupType.public;
  late bool _joinable = widget.group?.isJoinable ?? true;

  bool get _isEdit => widget.group != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _maxMembers.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const CloseButton(), title: Text(_isEdit ? 'Modifier le Groupe' : 'Créer un Nouveau Groupe')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AppTextField(
                label: 'Nom du groupe',
                required: true,
                controller: _name,
                hint: 'Ex: Groupe de soutien Paris',
                validator: (v) => Validators.required(v, 'Le nom est obligatoire.'),
              ),
              AppTextField(
                label: 'Description',
                required: true,
                controller: _description,
                hint: "Décrivez l'objectif et les activités du groupe...",
                maxLines: 4,
                validator: (v) => Validators.required(v, 'La description est obligatoire.'),
              ),
              const LabeledField(
                label: 'Image du groupe',
                child: UploadArea(title: 'Ajouter une image', subtitle: 'JPG, PNG, GIF (max 5MB)'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppDropdownField<GroupType>(
                      label: 'Type de groupe',
                      value: _type,
                      items: GroupType.values,
                      itemLabel: (t) => t.label,
                      onChanged: (t) => setState(() => _type = t ?? _type),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Limite de membres',
                      controller: _maxMembers,
                      hint: 'Illimité',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          v != null && v.isNotEmpty && (int.tryParse(v) ?? 0) < 1 ? 'Minimum 1 membre.' : null,
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _joinable,
                onChanged: (v) => setState(() => _joinable = v ?? _joinable),
                title: const Text('Autoriser les membres à rejoindre librement'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Annuler'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(_isEdit ? Icons.save_outlined : Icons.check_rounded),
                      label: Text(_isEdit ? 'Modifier' : 'Créer'),
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
