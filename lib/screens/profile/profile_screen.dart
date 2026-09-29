import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/initials_avatar.dart';

/// Web `/profile/edit`. [user] pre-fills the form once the profile API is wired.
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

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.pop();
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
                          items: UserRole.values,
                          itemLabel: (r) => r.label,
                          onChanged: (r) => setState(() => _role = r),
                          validator: (r) => r == null ? 'Role is required.' : null,
                        ),
                        AppTextField(
                          label: 'Numéro de téléphone',
                          controller: _phone,
                          hint: 'Ex: 06 12 34 56 78',
                          keyboardType: TextInputType.phone,
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
                            Expanded(child: FilledButton(onPressed: _save, child: const Text('Save'))),
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
