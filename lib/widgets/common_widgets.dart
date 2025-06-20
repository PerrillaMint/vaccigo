// lib/widgets/common_widgets.dart - FIXED back button issue
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

// FIXED: Consistent Page Header with proper overflow handling
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.light.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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

// FIXED: Consistent Card Container with better responsive design
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final double? maxWidth;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: double.infinity,
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
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

    if (maxWidth != null) {
      return Center(child: cardContent);
    }
    
    return cardContent;
  }
}

// FIXED: Consistent Button with better responsive design
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final AppButtonStyle style;
  final EdgeInsets? padding;
  final double? width;
  final double? height;

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
    this.height,
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
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
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

    return Container(
      width: width,
      height: height,
      constraints: const BoxConstraints(
        minHeight: 48,
      ),
      child: button,
    );
  }
}

enum AppButtonStyle { primary, secondary, text }

// FIXED: Consistent Input Field with comprehensive overflow handling
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
  final int? maxLength;

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
    this.maxLength,
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
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: widget.maxLines > 1 ? 16 : 12,
            ),
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textAlignVertical: widget.maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// FIXED: Status Badge with responsive design
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final IconData? icon;
  final bool isCompact;

  const StatusBadge({
    Key? key,
    required this.text,
    required this.type,
    this.icon,
    this.isCompact = false,
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

    final padding = isCompact 
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    
    final fontSize = isCompact ? 10.0 : 12.0;
    final iconSize = isCompact ? 12.0 : 16.0;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 200,
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
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
              size: iconSize,
            ),
            SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusType { success, warning, error, info, neutral }

// FIXED: Empty State Widget with responsive design
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  final bool isCompact;

  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isCompact ? 48 : 64,
            color: AppColors.textMuted,
          ),
          SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
          Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            message,
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (action != null) ...[
            SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

// FIXED: Loading Widget with better centering
class AppLoading extends StatelessWidget {
  final String? message;
  final bool isCompact;

  const AppLoading({
    Key? key, 
    this.message,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isCompact ? 24 : 32,
            height: isCompact ? 24 : 32,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
            Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                message!,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// COMPLETELY FIXED: Safe Page Wrapper that avoids IntrinsicHeight+LayoutBuilder issues
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
    Widget content = child;

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    if (hasScrollView) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return SafeArea(child: content);
  }
}

// FIXED: Simple Column Wrapper for common layout patterns
class ColumnScrollWrapper extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const ColumnScrollWrapper({
    Key? key,
    required this.children,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        ),
      ),
    );
  }
}

// FIXED: App Bar with consistent styling and overflow handling - BACK BUTTON ISSUE RESOLVED
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double? elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: showBackButton, // FIXED: This prevents automatic back button
      actions: actions,
      elevation: elevation,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// FIXED: Responsive Grid Widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;
  final double? maxItemWidth;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.maxColumns,
    this.maxItemWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        
        if (maxItemWidth != null) {
          columns = (constraints.maxWidth / (maxItemWidth! + spacing)).floor();
        } else if (maxColumns != null) {
          columns = maxColumns!;
        }
        
        columns = columns.clamp(1, children.length);
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

// FIXED: Dismissible Card for lists
class DismissibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDismissed;
  final String dismissKey;
  final Color? dismissColor;
  final IconData? dismissIcon;

  const DismissibleCard({
    Key? key,
    required this.child,
    required this.dismissKey,
    this.onDismissed,
    this.dismissColor,
    this.dismissIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onDismissed == null) {
      return child;
    }

    return Dismissible(
      key: Key(dismissKey),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: dismissColor ?? AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          dismissIcon ?? Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) => onDismissed!(),
      child: child,
    );
  }
}

// FIXED: Expandable Section Widget
class ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool isExpanded;
  final IconData? icon;
  final ValueChanged<bool>? onExpansionChanged;

  const ExpandableSection({
    Key? key,
    required this.title,
    required this.child,
    this.isExpanded = false,
    this.icon,
    this.onExpansionChanged,
  }) : super(key: key);

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}