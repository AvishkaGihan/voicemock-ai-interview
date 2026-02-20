import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Bottom sheet picker for selecting interview role.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    required this.selectedRole,
    required this.onRoleSelected,
    super.key,
  });

  final InterviewRole selectedRole;
  final ValueChanged<InterviewRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return _SelectorCard(
      label: 'Target Role',
      value: selectedRole.displayName,
      onTap: () => _showRolePicker(context),
    );
  }

  Future<void> _showRolePicker(BuildContext context) async {
    await showModalBottomSheet<InterviewRole>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VoiceMockRadius.xl),
        ),
      ),
      builder: (context) => _RoleBottomSheet(
        selectedRole: selectedRole,
        onRoleSelected: (role) {
          Navigator.pop(context);
          onRoleSelected(role);
        },
      ),
    );
  }
}

class _RoleBottomSheet extends StatelessWidget {
  const _RoleBottomSheet({
    required this.selectedRole,
    required this.onRoleSelected,
  });

  final InterviewRole selectedRole;
  final ValueChanged<InterviewRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VoiceMockSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VoiceMockColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: VoiceMockSpacing.lg),
            Text(
              'Select Target Role',
              style: VoiceMockTypography.h3,
            ),
            const SizedBox(height: VoiceMockSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: InterviewRole.values
                      .map(
                        (role) => _RoleOption(
                          role: role,
                          isSelected: role == selectedRole,
                          onTap: () => onRoleSelected(role),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final InterviewRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VoiceMockSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? VoiceMockColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(VoiceMockRadius.md),
            border: isSelected
                ? Border.all(color: VoiceMockColors.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  role.displayName,
                  style: VoiceMockTypography.body.copyWith(
                    color: isSelected
                        ? VoiceMockColors.primary
                        : VoiceMockColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: VoiceMockColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VoiceMockColors.surface,
        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
        border: const Border(
          left: BorderSide(color: VoiceMockColors.primary, width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: VoiceMockColors.accentGlow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VoiceMockRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(VoiceMockSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: VoiceMockTypography.label,
                      ),
                      const SizedBox(height: VoiceMockSpacing.xs),
                      Text(
                        value,
                        style: VoiceMockTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: VoiceMockColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
