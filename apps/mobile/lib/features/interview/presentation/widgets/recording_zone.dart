import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Immersive recording zone with animated visual feedback.
///
/// Provides the centered mic area with status text and pulsing rings.
/// Wraps gesture detection for hold-to-talk interaction.
class RecordingZone extends StatefulWidget {
  const RecordingZone({
    required this.isEnabled,
    required this.isRecording,
    required this.onPressStart,
    required this.onPressEnd,
    this.recordingDuration,
    super.key,
  });

  final bool isEnabled;
  final bool isRecording;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final Duration? recordingDuration;

  @override
  State<RecordingZone> createState() => _RecordingZoneState();
}

class _RecordingZoneState extends State<RecordingZone>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _breatheController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    // Pulsing ring animation for recording state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseScale = Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuart),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuart),
    );

    // Gentle breathe animation for idle state
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(RecordingZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording ||
        widget.isEnabled != oldWidget.isEnabled) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.isRecording) {
      _breatheController.stop();
      unawaited(_pulseController.repeat());
    } else if (widget.isEnabled) {
      _pulseController
        ..stop()
        ..reset();
      unawaited(
        _breatheController.repeat(reverse: true),
      );
    } else {
      _pulseController
        ..stop()
        ..reset();
      _breatheController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: _getAccessibilityLabel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status label
          if (widget.isRecording)
            Text(
              'Listening…',
              style: VoiceMockTypography.small.copyWith(
                color: VoiceMockColors.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (widget.isEnabled)
            Text(
              'Ready',
              style: VoiceMockTypography.small.copyWith(
                color: VoiceMockColors.textMuted,
              ),
            ),

          const SizedBox(height: VoiceMockSpacing.md),

          // Mic area with rings
          GestureDetector(
            onLongPressStart: widget.isEnabled
                ? (_) {
                    unawaited(HapticFeedback.lightImpact());
                    widget.onPressStart();
                  }
                : null,
            onLongPressEnd: widget.isEnabled
                ? (_) {
                    unawaited(HapticFeedback.mediumImpact());
                    widget.onPressEnd();
                  }
                : null,
            onLongPressCancel: widget.isEnabled ? widget.onPressEnd : null,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulsing ring (recording)
                  if (widget.isRecording)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: VoiceMockColors.primary.withValues(
                                alpha: _pulseOpacity.value,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Middle breathing ring (idle)
                  if (widget.isEnabled && !widget.isRecording)
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (context, _) {
                        final scale = 1.0 + (_breatheController.value * 0.06);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: VoiceMockColors.primary
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                        );
                      },
                    ),

                  // Static outer ring
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording
                          ? VoiceMockColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isRecording
                            ? VoiceMockColors.primary.withValues(alpha: 0.3)
                            : (widget.isEnabled
                                ? VoiceMockColors.surfaceBorder
                                : VoiceMockColors.surfaceBorder
                                    .withValues(alpha: 0.5)),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Main button circle
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getBackgroundColor(),
                      border: Border.all(
                        color: widget.isRecording
                            ? VoiceMockColors.primary
                            : (widget.isEnabled
                                ? VoiceMockColors.primary
                                    .withValues(alpha: 0.3)
                                : VoiceMockColors.surfaceBorder),
                        width: widget.isRecording ? 3 : 2,
                      ),
                      boxShadow: widget.isEnabled
                          ? [
                              BoxShadow(
                                color: VoiceMockColors.primary
                                    .withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 40,
                      color: _getIconColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: VoiceMockSpacing.md),

          // Timer / instruction
          if (widget.isRecording &&
              widget.recordingDuration != null) ...[
            Text(
              _formatDuration(widget.recordingDuration!),
              style: VoiceMockTypography.h3.copyWith(
                color: VoiceMockColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: VoiceMockSpacing.xs),
            Text(
              'Release to send',
              style: VoiceMockTypography.micro.copyWith(
                color: VoiceMockColors.textMuted,
              ),
            ),
          ] else if (widget.isEnabled)
            Text(
              'Hold to answer',
              style: VoiceMockTypography.small.copyWith(
                color: VoiceMockColors.textMuted,
              ),
            )
          else
            Text(
              'Waiting…',
              style: VoiceMockTypography.small.copyWith(
                color: VoiceMockColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isRecording) {
      return VoiceMockColors.primary.withValues(alpha: 0.12);
    }
    if (!widget.isEnabled) {
      return VoiceMockColors.surfaceElevated;
    }
    return VoiceMockColors.surfaceCard;
  }

  Color _getIconColor() {
    if (widget.isRecording) return VoiceMockColors.primary;
    if (!widget.isEnabled) return VoiceMockColors.textMuted;
    return VoiceMockColors.primary;
  }

  String _getAccessibilityLabel() {
    if (widget.isRecording) return 'Recording. Release to send.';
    if (!widget.isEnabled) return 'Disabled while coach is speaking.';
    return 'Hold to record answer';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
