import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Inline selector for interview role, designed to live inside
/// the "INTERVIEW SETUP" section card.
///
/// Displays label on top and a full-width dropdown button below.
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
    return Padding(
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.work_outline,
                color: VoiceMockColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'Job Role',
                style: VoiceMockTypography.body.copyWith(
                  color: VoiceMockColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showRolePicker(context),
              borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: VoiceMockSpacing.md,
                  vertical: VoiceMockSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: VoiceMockColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(VoiceMockRadius.md),
                  border: Border.all(color: VoiceMockColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedRole.displayName,
                        style: VoiceMockTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: VoiceMockColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRolePicker(BuildContext context) async {
    await showModalBottomSheet<InterviewRole>(
      context: context,
      backgroundColor: VoiceMockColors.surface,
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
                  color: VoiceMockColors.surfaceBorder,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: VoiceMockSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VoiceMockRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(VoiceMockSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? VoiceMockColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              border: isSelected
                  ? Border.all(color: VoiceMockColors.primary, width: 2)
                  : Border.all(color: VoiceMockColors.surfaceBorder),
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
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
      ),
    );
  }
}
