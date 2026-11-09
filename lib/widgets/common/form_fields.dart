import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Web form layout: label above the input (`.form-group label` + `input`).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.required = false, this.hint});

  final String label;
  final Widget child;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required) const TextSpan(text: ' *', style: AppTypography.requiredMark),
                if (hint != null)
                  TextSpan(text: '  $hint', style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Text input styled by the theme, with the label rendered above it.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.required = false,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
    this.autofillHints,
    this.textAlign = TextAlign.start,
    this.style,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final bool required;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      required: required,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
        maxLines: maxLines,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        enabled: enabled,
        autofillHints: autofillHints,
        textAlign: textAlign,
        style: style,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: AppSizes.iconMd),
        ),
      ),
    );
  }
}

/// Password input with a show/hide toggle (web reset-password `.password-toggle`).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: widget.label,
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: _obscure,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        autofillHints: const [AutofillHints.password],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Afficher' : 'Masquer',
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}

/// Dropdown with the label above it.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.hint,
    this.validator,
    this.required = false,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? hint;
  final FormFieldValidator<T>? validator;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      required: required,
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        validator: validator,
        hint: hint == null ? null : Text(hint!),
        borderRadius: AppRadius.mdAll,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryDark),
        items: [for (final item in items) DropdownMenuItem<T>(value: item, child: Text(itemLabel(item)))],
        onChanged: onChanged,
      ),
    );
  }
}

/// Spinner shown in place of a button label while its request runs.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
        dimension: AppSizes.iconMd,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
      );
}
