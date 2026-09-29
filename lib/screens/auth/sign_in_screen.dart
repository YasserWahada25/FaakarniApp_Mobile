import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/validators.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/common/form_fields.dart';

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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // Validation is bypassed while the auth API is not wired (see AppConstants.skipAuth).
    if (!AppConstants.skipAuth && !_formKey.currentState!.validate()) return;
    context.go(AppRoutes.home);
  }

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
              FilledButton(onPressed: _submit, child: const Text('SIGN IN')),
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
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.g_mobiledata_rounded, size: AppSizes.iconLg),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.facebook),
                onPressed: () => context.go(AppRoutes.home),
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
