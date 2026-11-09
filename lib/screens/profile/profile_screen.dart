import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/initials_avatar.dart';
import '../../widgets/common/state_views.dart';

/// Web `/profile/edit`. [user] (the signed-in user) pre-fills the form.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.user});

  final AppUser? user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.user?.nom);
  late final _prenom = TextEditingController(text: widget.user?.prenom);
  late final _email = TextEditingController(text: widget.user?.email);
  late final _phone = TextEditingController(text: widget.user?.numTel);
  late final _address = TextEditingController(text: widget.user?.adresse);
  late UserRole? _role = widget.user?.role;
  bool _busy = false;
  String? _error;

  /// Admins keep their role (not offered to other users).
  late final List<UserRole> _roles = [...UserRole.selectable, if (widget.user?.role == UserRole.admin) UserRole.admin];

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Web `EditProfileComponent.save` (`PUT /api/users/{id}`).
  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthProvider.instance.updateProfile(UpdateUserRequest(
        nom: _nom.text.trim(),
        prenom: _prenom.text.trim(),
        email: _email.text.trim(),
        role: _role,
        numTel: _phone.text.trim(),
        adresse: _address.text.trim(),
      ));
      if (!mounted) return;
      showAppSnackBar(context, 'Profil mis à jour.');
      context.canPop() ? context.pop() : context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(title: const Text('Edit profile')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.authBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: AppDecorations.authBox,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: InitialsAvatar(initials: widget.user?.initials, size: AppSizes.avatarXl),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Edit profile', style: text.headlineLarge, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Update your information below.',
                          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (_error != null) ...[
                          FeedbackBanner(message: _error!, onClose: () => setState(() => _error = null)),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppTextField(label: 'Nom', controller: _nom, hint: 'Votre nom', validator: (v) => Validators.name(v, label: 'Nom')),
                        AppTextField(
                          label: 'Prénom',
                          controller: _prenom,
                          hint: 'Votre prénom',
                          validator: (v) => Validators.name(v, label: 'Prénom'),
                        ),
                        AppTextField(
                          label: 'Email',
                          controller: _email,
                          hint: 'votre@email.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        AppDropdownField<UserRole>(
                          label: 'Rôle',
                          value: _role,
                          hint: 'Sélectionnez un rôle',
                          items: _roles,
                          itemLabel: (r) => r.label,
                          onChanged: (r) => setState(() => _role = r),
                          validator: (r) => r == null ? 'Role is required.' : null,
                        ),
                        AppTextField(
                          label: 'Numéro de téléphone',
                          controller: _phone,
                          hint: 'Ex: 12345678',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                          validator: (v) => (v ?? '').trim().isEmpty ? null : Validators.phone(v),
                        ),
                        AppTextField(
                          label: 'Adresse',
                          controller: _address,
                          hint: 'Votre adresse',
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: FilledButton(
                                onPressed: _busy ? null : _save,
                                child: _busy ? const ButtonSpinner() : const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
