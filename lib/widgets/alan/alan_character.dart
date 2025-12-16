import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/alan_voice_service.dart';
import '../../core/theme/app_theme.dart';

class AlanCharacter extends ConsumerWidget {
  final double size;
  final bool interactive;

  const AlanCharacter({
    super.key,
    this.size = 200,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(alanSpeechStateProvider);

    return GestureDetector(
      onTap: interactive ? () => _onTap(ref) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect when speaking
            if (speechState.value == AlanSpeechState.speaking)
              Container(
                width: size * 0.9,
                height: size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 800.ms,
                  ),

            // Main character body
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                gradient: AppTheme.alanGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
              ),
              child: Stack(
                children: [
                  // Face
                  Center(
                    child: _AlanFace(
                      size: size * 0.6,
                      state: speechState.value ?? AlanSpeechState.idle,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -5, duration: 2000.ms),
          ],
        ),
      ),
    );
  }

  void _onTap(WidgetRef ref) {
    final alanService = ref.read(alanVoiceServiceProvider);
    if (alanService.currentState == AlanSpeechState.speaking) {
      alanService.stop();
    } else {
      // Say something random
      final phrases = [
        'Ćao! Kako si?',
        'Hajde da učimo zajedno!',
        'Spreman si za avanturu?',
        'Ti si super!',
      ];
      final randomPhrase = phrases[DateTime.now().millisecond % phrases.length];
      alanService.speak(randomPhrase, mood: AlanMood.happy);
    }
  }
}

class _AlanFace extends StatelessWidget {
  final double size;
  final AlanSpeechState state;

  const _AlanFace({
    required this.size,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Eyes
          Positioned(
            top: size * 0.25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Eye(size: size * 0.15, blinking: state == AlanSpeechState.idle),
                SizedBox(width: size * 0.2),
                _Eye(size: size * 0.15, blinking: state == AlanSpeechState.idle),
              ],
            ),
          ),

          // Mouth
          Positioned(
            bottom: size * 0.2,
            child: _Mouth(
              size: size * 0.3,
              speaking: state == AlanSpeechState.speaking,
            ),
          ),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  final double size;
  final bool blinking;

  const _Eye({
    required this.size,
    required this.blinking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: const BoxDecoration(
            color: Color(0xFF2D3142),
            shape: BoxShape.circle,
          ),
        ),
      ),
    )
        .animate(
          onPlay: blinking ? (c) => c.repeat() : null,
          autoPlay: blinking,
        )
        .scaleY(
          begin: 1,
          end: 0.1,
          duration: 150.ms,
          curve: Curves.easeInOut,
        )
        .then(delay: 100.ms)
        .scaleY(
          begin: 0.1,
          end: 1,
          duration: 150.ms,
        )
        .then(delay: 3000.ms);
  }
}

class _Mouth extends StatelessWidget {
  final double size;
  final bool speaking;

  const _Mouth({
    required this.size,
    required this.speaking,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: speaking ? size * 0.6 : size * 0.3,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(speaking ? size * 0.3 : size * 0.15),
      ),
    ).animate(
      onPlay: speaking ? (c) => c.repeat(reverse: true) : null,
      autoPlay: speaking,
    ).scaleY(
      begin: 1,
      end: speaking ? 0.6 : 1,
      duration: 200.ms,
    );
  }
}
