import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// ────────────────────────────────────────────────────────────
//  GZCard — Glass-morphism card base
// ────────────────────────────────────────────────────────────
class GZCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;
  final List<BoxShadow>? shadows;

  const GZCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.radius = AppConstants.radiusLG,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: gradient ?? AppColors.cardGradient,
          border: Border.all(
            color: borderColor ?? AppColors.cardBorder,
            width: 1,
          ),
          boxShadow: shadows ??
              [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppConstants.paddingLG),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZButton — Neon glow button
// ────────────────────────────────────────────────────────────
class GZButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? glowColor;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double height;

  const GZButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.glowColor,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final g = glowColor ?? c.withOpacity(0.3);

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [c, Color.alphaBlend(Colors.black26, c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                    color: g,
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZBadge — Status badge pill
// ────────────────────────────────────────────────────────────
class GZBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const GZBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZStatCard — Dashboard stat widget
// ────────────────────────────────────────────────────────────
class GZStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GZStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GZCard(
      onTap: onTap,
      borderColor: color.withOpacity(0.3),
      shadows: [
        BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (subtitle != null)
                Flexible(
                  child: GZBadge(label: subtitle!, color: color, fontSize: 9),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZTextField — Styled text input
// ────────────────────────────────────────────────────────────
class GZTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const GZTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffix,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZSectionHeader
// ────────────────────────────────────────────────────────────
class GZSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const GZSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZEmpty — Empty state widget
// ────────────────────────────────────────────────────────────
class GZEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  const GZEmpty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              GZButton(label: action!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZDivider
// ────────────────────────────────────────────────────────────
class GZDivider extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  const GZDivider({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: AppColors.cardBorder,
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZNeonText — Glowing text
// ────────────────────────────────────────────────────────────
class GZNeonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight weight;

  const GZNeonText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = AppColors.accent,
    this.weight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        shadows: [
          Shadow(color: color.withOpacity(0.8), blurRadius: 8),
          Shadow(color: color.withOpacity(0.4), blurRadius: 16),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  GZTimerDisplay — Animated timer for active rental
// ────────────────────────────────────────────────────────────
class GZTimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final Color color;

  const GZTimerDisplay({
    super.key,
    required this.elapsed,
    this.color = AppColors.accent,
  });

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _segment(_pad(h)),
        _colon(),
        _segment(_pad(m)),
        _colon(),
        _segment(_pad(s)),
      ],
    );
  }

  Widget _segment(String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        v,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: color,
          fontFamily: 'monospace',
          shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 8)],
        ),
      ),
    );
  }

  Widget _colon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(':',
          style: TextStyle(
              fontSize: 20, color: color, fontWeight: FontWeight.w800)),
    );
  }
}
