import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/design_tokens.dart';

enum AppButtonVariant { primary, secondary, text }

// ─────────────────────────────────────────────────────────────────────────────
// AppSegmentedControl — premium animated pill tabs
// ─────────────────────────────────────────────────────────────────────────────
class AppSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  final bool isExpanded;

  const AppSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) const SizedBox(width: 4),
            if (isExpanded)
              Expanded(child: _buildItem(context, index))
            else
              _buildItem(context, index),
          ],
        ],
      ),
    );

    if (!isExpanded) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
    }

    return Semantics(
      container: true,
      label: 'View selector',
      child: content,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final isSelected = selectedIndex == index;
    return Semantics(
      button: true,
      selected: isSelected,
      label: labels[index],
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected ? DesignTokens.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            labels[index],
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AsyncStateView — loading / error / empty state wrapper
// ─────────────────────────────────────────────────────────────────────────────
class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final VoidCallback? onEmptyAction;
  final String retryLabel;
  final String? emptyActionLabel;
  final Widget child;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.isEmpty,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.child,
    this.emptyIcon = Icons.inbox_outlined,
    this.onRetry,
    this.onEmptyAction,
    this.retryLabel = 'Retry',
    this.emptyActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (errorMessage != null) {
      return _StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load this content',
        message: errorMessage!,
        actionLabel: retryLabel,
        onAction: onRetry,
        isError: true,
      );
    }
    if (isEmpty) {
      return _StateMessage(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    }
    return child;
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            boxShadow: DesignTokens.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                AppButton(
                  label: actionLabel!,
                  expand: false,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppButton — gradient primary, outlined secondary, text variant
// ─────────────────────────────────────────────────────────────────────────────
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final IconData? icon;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
    this.icon,
    this.height,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.height ?? DesignTokens.controlHeight;
    final effectivePadding =
        widget.padding ?? const EdgeInsets.symmetric(horizontal: 24);

    final progressColor = widget.variant == AppButtonVariant.primary
        ? AppColors.textWhite
        : AppColors.primary;

    final childWidget = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: progressColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: 18,
                    color: widget.variant == AppButtonVariant.primary
                        ? Colors.white
                        : AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(widget.label),
            ],
          );

    if (widget.variant == AppButtonVariant.primary) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: widget.expand ? double.infinity : null,
            height: effectiveHeight,
            padding: effectivePadding,
            decoration: BoxDecoration(
              gradient: widget.onPressed != null
                  ? DesignTokens.primaryGradient
                  : null,
              color: widget.onPressed == null ? AppColors.disabled : null,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              boxShadow: widget.onPressed != null && !_pressed
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Align(
              alignment: Alignment.center,
              widthFactor: widget.expand ? null : 1.0,
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                child: childWidget,
              ),
            ),
          ),
        ),
      );
    }

    // Secondary / text variants — use existing Material buttons
    final button = switch (widget.variant) {
      AppButtonVariant.secondary => widget.icon == null
          ? OutlinedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              child: childWidget,
            )
          : OutlinedButton.icon(
              onPressed: widget.isLoading ? null : widget.onPressed,
              icon: Icon(widget.icon),
              label: childWidget,
            ),
      AppButtonVariant.text => widget.icon == null
          ? TextButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              child: childWidget,
            )
          : TextButton.icon(
              onPressed: widget.isLoading ? null : widget.onPressed,
              icon: Icon(widget.icon),
              label: childWidget,
            ),
      _ => const SizedBox(),
    };

    return SizedBox(
      width: widget.expand ? double.infinity : null,
      height: effectiveHeight,
      child: button,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextField — unchanged (styling handled by InputDecorationTheme)
// ─────────────────────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.autofillHints,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      autofillHints: autofillHints,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppIconButton — semantic icon button, unchanged API
// ─────────────────────────────────────────────────────────────────────────────
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(
          width: DesignTokens.iconButtonSize,
          height: DesignTokens.iconButtonSize,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppFeedback — snack bar helper, unchanged
// ─────────────────────────────────────────────────────────────────────────────
class AppFeedback {
  AppFeedback._();

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          action: action,
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FadeSlideIn — staggered list-entry animation wrapper
// ─────────────────────────────────────────────────────────────────────────────
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
