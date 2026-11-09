import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/state_views.dart';

/// Web `/auth/signin`.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Web `SignInComponent.onSubmit`; the router then opens Home.
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthProvider.instance.signIn(_email.text, _password.text, remember: _rememberMe);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Google / Facebook need the native SDKs and their OAuth app ids.
  void _socialSignIn(String provider) =>
      showAppSnackBar(context, 'La connexion $provider n’est pas encore disponible sur mobile.');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      title: 'Sign In',
      subtitle: 'Welcome back! Please login to your account.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
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
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              PasswordField(
                label: 'Password',
                controller: _password,
                hint: 'Enter your password',
                validator: Validators.password,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    borderRadius: AppRadius.smAll,
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false)),
                        Text('Remember Me', style: text.bodyMedium),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const ButtonSpinner() : const Text('SIGN IN'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text('OR', style: text.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.googleText,
                  side: const BorderSide(color: AppColors.border),
                ),
                onPressed: () => _socialSignIn('Google'),
                icon: const Icon(Icons.g_mobiledata_rounded, size: AppSizes.iconLg),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.facebook),
                onPressed: () => _socialSignIn('Facebook'),
                icon: const Icon(Icons.facebook_rounded),
                label: const Text('Sign in with Facebook'),
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthFooterLink(
                text: "Don't have an account?",
                action: 'Sign Up',
                onTap: () => context.push(AppRoutes.signUp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
