import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/state_views.dart';

/// Web `/auth/password-reset`: email + 6-digit code + new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Web `ResetPasswordComponent`: code + new password, then sign in again.
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await AuthService.instance.resetPassword(
        email: _email.text.trim(),
        code: _code.text.trim(),
        newPassword: _password.text,
      );
      if (!mounted) return;
      showAppSnackBar(context, message);
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
      title: 'Réinitialiser le mot de passe',
      subtitle: 'Entrez le code reçu par email et votre nouveau mot de passe.',
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
              label: 'Email',
              controller: _email,
              hint: 'Votre adresse email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validators.email(v) == null ? null : 'Email invalide.',
            ),
            AppTextField(
              label: 'Code de vérification',
              controller: _code,
              hint: 'Code à 6 chiffres',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppTypography.codeInput,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              validator: Validators.resetCode,
            ),
            PasswordField(
              label: 'Nouveau mot de passe',
              controller: _password,
              hint: 'Minimum 8 caractères',
              validator: (v) => Validators.minLength(v, 8, 'Le mot de passe doit contenir au moins 8 caractères.'),
            ),
            PasswordField(
              label: 'Confirmer le mot de passe',
              controller: _confirm,
              hint: 'Confirmez votre mot de passe',
              textInputAction: TextInputAction.done,
              validator: (v) => v != _password.text ? 'Les mots de passe ne correspondent pas.' : null,
              onSubmitted: (_) => _submit(),
            ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const ButtonSpinner() : const Text('RÉINITIALISER'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthFooterLink(text: 'Retour à la', action: 'connexion', onTap: () => context.go(AppRoutes.signIn)),
          ],
        ),
      ),
    );
  }
}
