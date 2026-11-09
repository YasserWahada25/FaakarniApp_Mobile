import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/state_views.dart';

/// Web `/auth/signup`.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  UserRole _role = UserRole.patient;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _password, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Web `SignUpComponent.onSubmit`: creates the account, then back to sign-in.
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(SignUpRequest(
        nom: _nom.text.trim(),
        prenom: _prenom.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
        numTel: _phone.text.trim(),
        adresse: _address.text.trim(),
      ));
      if (!mounted) return;
      showAppSnackBar(context, 'Compte créé. Connectez-vous avec votre email et votre mot de passe.');
      context.go(AppRoutes.signIn);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create Account',
      subtitle: 'Fill in the details below to create an account.',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              FeedbackBanner(message: _error!, onClose: () => setState(() => _error = null)),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: 'Name',
              controller: _nom,
              hint: 'Your Name',
              autofillHints: const [AutofillHints.familyName],
              validator: (v) => Validators.name(v),
            ),
            AppTextField(
              label: 'Last Name',
              controller: _prenom,
              hint: 'Your Last Name',
              autofillHints: const [AutofillHints.givenName],
              validator: (v) => Validators.name(v, label: 'Last name'),
            ),
            AppTextField(
              label: 'Email',
              controller: _email,
              hint: 'Example@email.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            PasswordField(
              label: 'Password',
              controller: _password,
              hint: 'Minimum 6 characters',
              validator: Validators.strongPassword,
            ),
            AppDropdownField<UserRole>(
              label: 'Role',
              value: _role,
              items: UserRole.selectable,
              itemLabel: (r) => r.label,
              onChanged: (r) => setState(() => _role = r ?? _role),
            ),
            AppTextField(
              label: 'Phone Number',
              controller: _phone,
              hint: 'Ex: 12345678',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              // Optional on the API (web: pattern only).
              validator: (v) => (v ?? '').trim().isEmpty ? null : Validators.phone(v),
            ),
            AppTextField(
              label: 'Address',
              controller: _address,
              hint: 'Your address',
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.required(v, 'Address is required.'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const ButtonSpinner() : const Text('SIGN UP'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthFooterLink(
              text: 'Already have an account?',
              action: 'Sign In',
              onTap: () => context.go(AppRoutes.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
