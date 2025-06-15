// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// App Spacing Constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Consistent Page Header
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppPageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient.scale(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// Consistent Card Container
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity((elevation ?? 4) * 0.02),
            blurRadius: (elevation ?? 4) * 2,
            offset: Offset(0, (elevation ?? 4) / 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Consistent Button
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final AppButtonStyle style;
  final EdgeInsets? padding;
  final double? width;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.padding,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(text),
            ],
          );

    Widget button;
    switch (style) {
      case AppButtonStyle.primary:
        button = ElevatedButton(
          onPressed: (isEnabled && !isLoading) ? onPressed : null,
          child: buttonChild,
        );
        break;
      case AppButtonStyle.secondary:
        button = OutlinedButton(
          onPressed: (isEnabled && !isLoading) ? onPressed : null,
          child: buttonChild,
        );
        break;
      case AppButtonStyle.text:
        button = TextButton(
          onPressed: (isEnabled && !isLoading) ? onPressed : null,
          child: buttonChild,
        );
        break;
    }

    return SizedBox(
      width: width,
      child: button,
    );
  }
}

enum AppButtonStyle { primary, secondary, text }

// Consistent Input Field
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool isPassword;
  final bool isRequired;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const AppTextField({
    Key? key,
    required this.label,
    this.hint,
    required this.controller,
    this.prefixIcon,
    this.isPassword = false,
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(
                widget.prefixIcon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscurePassword,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textMuted,
                    ),
                    onPressed: widget.enabled
                        ? () => setState(() => _obscurePassword = !_obscurePassword)
                        : null,
                  )
                : null,
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}

// Status Badge
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final IconData? icon;

  const StatusBadge({
    Key? key,
    required this.text,
    required this.type,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case StatusType.success:
        color = AppColors.success;
        break;
      case StatusType.warning:
        color = AppColors.warning;
        break;
      case StatusType.error:
        color = AppColors.error;
        break;
      case StatusType.info:
        color = AppColors.info;
        break;
      case StatusType.neutral:
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusType { success, warning, error, info, neutral }

// Empty State Widget
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

// Loading Widget
class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Safe Page Wrapper to prevent overflow
class SafePageWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool hasScrollView;

  const SafePageWrapper({
    Key? key,
    required this.child,
    this.padding,
    this.hasScrollView = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (hasScrollView) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return SafeArea(child: content);
  }
}

// App Bar with consistent styling
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}