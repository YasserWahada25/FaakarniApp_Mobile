import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/state_views.dart';

/// Web `/auth/forgot-password`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// Web `ForgotPasswordComponent`: the API emails a 6-digit code, entered on
  /// the reset page.
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      final message = await AuthService.instance.forgotPassword(email);
      if (!mounted) return;
      showAppSnackBar(context, message);
      context.push(AppRoutes.resetPassword, extra: email);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot Password',
      subtitle: "Enter your email address and we'll send you a code to reset your password.",
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
              label: 'Email Address',
              controller: _email,
              hint: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.email(v) == null ? null : 'Please enter a valid email address.',
            ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const ButtonSpinner() : const Text('SEND RESET CODE'),
            ),
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
