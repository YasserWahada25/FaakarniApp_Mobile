import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/common/form_fields.dart';

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

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _password, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.go(AppRoutes.signIn);
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
              items: UserRole.values,
              itemLabel: (r) => r.label,
              onChanged: (r) => setState(() => _role = r ?? _role),
            ),
            AppTextField(
              label: 'Phone Number',
              controller: _phone,
              hint: 'Ex: 12345678',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              validator: Validators.phone,
            ),
            AppTextField(
              label: 'Address',
              controller: _address,
              hint: 'Your address',
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.required(v, 'Address is required.'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: _submit, child: const Text('SIGN UP')),
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
