import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../models/communication.dart';
import '../../services/group_service.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/network_picture.dart';
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

  /// New cover picked from the gallery, uploaded when the form is submitted.
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  static const int _maxImageBytes = 5 * 1024 * 1024;

  bool get _isEdit => widget.group != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _maxMembers.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxImageBytes) {
        showAppSnackBar(context, "L'image dépasse 5 Mo.");
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (e) {
      if (mounted) showAppSnackBar(context, "Impossible d'ouvrir la galerie.");
    }
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final service = GroupService.instance;
    try {
      final me = await AuthSession.instance.ensureSignedIn() ? AuthSession.instance.userId : null;
      if (me == null) throw const ApiException('Connectez-vous pour créer ou modifier un groupe.');

      var cover = widget.group?.coverImageUrl;
      if (_imageBytes != null) cover = await service.uploadCover(_imageBytes!, _imageName ?? 'cover.jpg');

      final draft = GroupDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        groupType: _type,
        isJoinable: _joinable,
        maxMembers: int.tryParse(_maxMembers.text),
        coverImageUrl: cover,
      );
      if (_isEdit) {
        await service.update(widget.group!.id, draft);
      } else {
        await service.create(draft, creatorId: me);
      }
      if (!mounted) return;
      showAppSnackBar(context, _isEdit ? 'Groupe modifié.' : 'Groupe créé.');
      context.pop();
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _coverField() {
    final existing = widget.group?.coverUrl;
    if (_imageBytes == null && existing == null) {
      return UploadArea(
        title: 'Ajouter une image',
        subtitle: 'JPG, PNG, GIF (max 5MB)',
        onTap: _saving ? null : _pickImage,
      );
    }
    const height = 160.0;
    return Stack(
      children: [
        _imageBytes != null
            ? ClipRRect(
                borderRadius: AppRadius.mdAll,
                child: Image.memory(_imageBytes!, height: height, width: double.infinity, fit: BoxFit.cover),
              )
            : NetworkPicture(url: existing!, height: height, width: double.infinity, borderRadius: AppRadius.mdAll),
        Positioned(
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: FilledButton.tonalIcon(
            onPressed: _saving ? null : _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text("Changer l'image"),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(_isEdit ? 'Modifier le Groupe' : 'Créer un Nouveau Groupe'),
      ),
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
              LabeledField(label: 'Image du groupe', child: _coverField()),
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => context.pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_isEdit ? Icons.save_outlined : Icons.check_rounded),
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
