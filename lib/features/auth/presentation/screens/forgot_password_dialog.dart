import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

Future<void> showForgotPasswordDialog({
  required BuildContext context,
  required Future<void> Function(String email) onSendResetLink,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ForgotPasswordDialog(onSendResetLink: onSendResetLink),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  final Future<void> Function(String email) onSendResetLink;

  const _ForgotPasswordDialog({required this.onSendResetLink});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await widget.onSendResetLink(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _statusMessage = 'Password reset link sent! Check your inbox.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _statusMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const Text(AppStrings.resetPassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.resetPasswordInstructions,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: AppDimens.space16),
            AppTextField(
              controller: _emailController,
              hintText: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.validateEmail,
              enabled: !_isLoading && !_isSuccess,
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: AppDimens.space12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppColors.primaryContainer.withAlpha(120)
                      : AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  border: Border.all(
                    color: _isSuccess ? AppColors.primary : AppColors.error.withAlpha(100),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      size: 18,
                      color: _isSuccess ? AppColors.primaryLight : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSuccess
                              ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            _isSuccess ? 'Close' : AppStrings.cancel,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        if (!_isSuccess)
          AppButton(
            text: AppStrings.sendResetLink,
            onPressed: _submit,
            isLoading: _isLoading,
            variant: ButtonVariant.primary,
            width: 140,
            height: 42,
          ),
      ],
    );
  }
}
