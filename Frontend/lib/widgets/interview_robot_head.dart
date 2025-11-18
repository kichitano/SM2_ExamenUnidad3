import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// 3D animated robot head widget for interview screens
///
/// Displays the Head Chef Bot with 3 animation states:
/// - Static Pose (neutral)
/// - SK_HeadChefBot|AS_FP_EC_HeadChefBot_Intro_SK_HeadChefBot (talking/intro)
/// - SK_HeadChefBot|AS_FP_EC_HeadChefBot_Intro_SK_HeadChefBot (idle - Animation 2)
class InterviewRobotHead extends StatefulWidget {
  /// Whether to auto-play the speaking animation on load
  final bool autoPlaySpeaking;

  /// Duration to play the speaking animation before transitioning to idle
  final Duration speakingDuration;

  const InterviewRobotHead({
    super.key,
    this.autoPlaySpeaking = true,
    this.speakingDuration = const Duration(seconds: 5),
  });

  @override
  State<InterviewRobotHead> createState() => InterviewRobotHeadState();
}

class InterviewRobotHeadState extends State<InterviewRobotHead> {
  String _currentAnimation = 'Static Pose';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlaySpeaking) {
      _initializeSpeakingSequence();
    }
  }

  /// Initialize the speaking animation sequence
  void _initializeSpeakingSequence() {
    // Start with speaking animation after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        playSpeakingAnimation();
      }
    });
  }

  /// Public method to trigger the speaking/intro animation
  /// This can be called from parent widgets when TTS is playing
  /// [duration] optional custom duration, defaults to widget.speakingDuration
  void playSpeakingAnimation({Duration? duration}) {
    if (!mounted) return;

    setState(() {
      _currentAnimation = 'SK_HeadChefBot|AS_FP_EC_HeadChefBot_Intro_SK_HeadChefBot';
      _isInitialized = true;
    });

    // After speaking duration, transition to idle animation (Animation 2)
    final animationDuration = duration ?? widget.speakingDuration;
    Future.delayed(animationDuration, () {
      if (mounted) {
        _transitionToIdle();
      }
    });
  }

  /// Transition to idle animation (Animation 2)
  void _transitionToIdle() {
    if (!mounted) return;

    setState(() {
      // For now, keeping the same animation
      // In future versions, this could be a different animation if available
      _currentAnimation = 'SK_HeadChefBot|AS_FP_EC_HeadChefBot_Intro_SK_HeadChefBot';
    });
  }

  /// Reset to static pose
  void resetToStatic() {
    if (!mounted) return;

    setState(() {
      _currentAnimation = 'Static Pose';
      _isInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use all available space
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50.withOpacity(0.2),
                Colors.purple.shade50.withOpacity(0.2),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AbsorbPointer(
              // Block all touch interactions completely
              absorbing: true,
              child: ModelViewer(
                key: ValueKey(_currentAnimation),
                // src: 'assets/models/head_chef_bot_with_animations.glb',
                src: 'assets/models/talking_donkey.glb',
                // alt: 'Interview Robot Head',
                alt: 'Talking Donkey',
                ar: false,
                autoRotate: false,
                cameraControls: false,
                disablePan: true,
                disableTap: true,
                disableZoom: true,
                autoPlay: true,
                animationName: _currentAnimation,
                orientation: '0deg 0deg 180deg',
                // Zoom: higher % = smaller model, lower % = bigger model
                cameraOrbit: 'auto auto 82%',
                fieldOfView: '35deg', // Moderate field of view
              ),
            ),
          ),
        );
      },
    );
  }
}
