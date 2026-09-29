import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/common/form_fields.dart';

/// Web `/auth/forgot-password`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.push(AppRoutes.resetPassword, extra: _email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot Password',
      subtitle: "Enter your email address and we'll send you a link to reset your password.",
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email Address',
              controller: _email,
              hint: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.email(v) == null ? null : 'Please enter a valid email address.',
            ),
            FilledButton(onPressed: _submit, child: const Text('SEND RESET LINK')),
            const SizedBox(height: AppSpacing.lg),
            AuthFooterLink(
              text: 'Remember your password?',
              action: 'Sign In',
              onTap: () => context.go(AppRoutes.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
