import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Large circular button for push-to-talk recording.
///
/// Implements hold-to-talk interaction pattern with visual feedback,
/// recording timer, and accessibility support.
class HoldToTalkButton extends StatefulWidget {
  const HoldToTalkButton({
    required this.isEnabled,
    required this.isRecording,
    required this.onPressStart,
    required this.onPressEnd,
    super.key,
    this.recordingDuration,
  });

  final bool isEnabled;
  final bool isRecording;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final Duration? recordingDuration;

  @override
  State<HoldToTalkButton> createState() => _HoldToTalkButtonState();
}

class _HoldToTalkButtonState extends State<HoldToTalkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(HoldToTalkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording ||
        widget.isEnabled != oldWidget.isEnabled) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.isRecording) {
      unawaited(_controller.repeat());
    } else if (widget.isEnabled) {
      // Gentle breathe when idle
      unawaited(
        _controller.repeat(
          reverse: true,
          period: const Duration(seconds: 2),
        ),
      );
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: _getAccessibilityLabel(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing Ring
          if (widget.isEnabled)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Different animation for recording vs idle
                if (widget.isRecording) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VoiceMockColors.primary.withValues(
                          alpha: _opacityAnimation.value,
                        ),
                      ),
                    ),
                  );
                } else {
                  // Gentle idle pulse (just slight scale, no fade out)
                  // We recycle the controller but map it differently here
                  // if needed, or just use a simple scale breathe.
                  // The logic in _updateAnimationState sets
                  // repeat(reverse: true).
                  // So _controller goes 0..1..0.
                  // Let's map 0..1 to scale 1.0..1.05
                  final scale = 1.0 + (_controller.value * 0.05);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VoiceMockColors.accentGlow,
                      ),
                    ),
                  );
                }
              },
            ),

          // Main Button
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
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getBackgroundColor(context),
                border: widget.isRecording
                    ? Border.all(
                        color: VoiceMockColors.primary,
                        width: 4,
                      )
                    : null,
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: VoiceMockColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 48,
                    color: _getIconColor(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getIconColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.isRecording &&
                      widget.recordingDuration != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(widget.recordingDuration!),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VoiceMockColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel() {
    if (widget.isRecording) return 'Release to send';
    if (!widget.isEnabled) return 'Waiting...';
    return 'Hold to talk';
  }

  String _getAccessibilityLabel() {
    if (widget.isRecording) return 'Recording. Release to send.';
    if (!widget.isEnabled) return 'Disabled while coach is speaking.';
    return 'Hold to record answer';
  }

  Color _getBackgroundColor(BuildContext context) {
    if (widget.isRecording) {
      return VoiceMockColors.primary.withValues(alpha: 0.2); // 51/255 ~= 0.2
    }
    if (!widget.isEnabled) {
      return const Color(0xFFE2E8F0); // Light grey/outline variant
    }
    return VoiceMockColors.surface; // White surface for contrast with pulse
  }

  Color _getIconColor(BuildContext context) {
    if (widget.isRecording) return VoiceMockColors.primary;
    if (!widget.isEnabled) return VoiceMockColors.textMuted;
    return VoiceMockColors.primary;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
