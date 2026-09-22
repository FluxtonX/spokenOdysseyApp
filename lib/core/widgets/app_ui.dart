import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/design_tokens.dart';

enum AppButtonVariant { primary, secondary, text }

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
    return Semantics(
      button: true,
      selected: selectedIndex == index,
      label: labels[index],
      child: InkWell(
        onTap: () => onChanged(index),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selectedIndex == index ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
          child: Text(
            labels[index],
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selectedIndex == index ? AppColors.textWhite : AppColors.primary,
                ),
          ),
        ),
      ),
    );
  }
}

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
      return const Center(child: CircularProgressIndicator());
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              AppButton(
                label: actionLabel!,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = variant == AppButtonVariant.primary
        ? AppColors.textWhite
        : AppColors.primary;
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final progress = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: progressColor,
            ),
          )
        : child;

    final button = switch (variant) {
      AppButtonVariant.primary =>
        icon == null
            ? ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                child: progress,
              )
            : ElevatedButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: Icon(icon),
                label: progress,
              ),
      AppButtonVariant.secondary =>
        icon == null
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                child: progress,
              )
            : OutlinedButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: Icon(icon),
                label: progress,
              ),
      AppButtonVariant.text =>
        icon == null
            ? TextButton(
                onPressed: isLoading ? null : onPressed,
                child: progress,
              )
            : TextButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: Icon(icon),
                label: progress,
              ),
    };

    return SizedBox(
      width: expand ? double.infinity : null,
      height: DesignTokens.controlHeight,
      child: button,
    );
  }
}

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
