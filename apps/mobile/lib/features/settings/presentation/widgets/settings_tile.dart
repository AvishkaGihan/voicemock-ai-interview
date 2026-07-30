import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Reusable settings row widget with a tinted circular icon.
///
/// Replaces inline [ListTile] usage in the settings page for consistency
/// with the app's design system.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.iconColor = VoiceMockColors.primary,
    this.iconBackgroundColor,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color? iconBackgroundColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VoiceMockSpacing.md,
            vertical: VoiceMockSpacing.md,
          ),
          child: Row(
            children: [
              // Tinted circular icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ??
                      iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: VoiceMockSpacing.md),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: VoiceMockTypography.body.copyWith(
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: VoiceMockTypography.small,
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing widget
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: VoiceMockColors.textMuted.withValues(alpha: 0.5),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
