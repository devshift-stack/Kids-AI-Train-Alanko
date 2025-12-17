import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/app_rating_service.dart';

/// Dialog to prompt user for app rating
class RatingDialog extends StatelessWidget {
  final AppRatingService ratingService;
  final VoidCallback? onRated;
  final VoidCallback? onRemindLater;
  final VoidCallback? onDismiss;

  const RatingDialog({
    super.key,
    required this.ratingService,
    this.onRated,
    this.onRemindLater,
    this.onDismiss,
  });

  /// Show rating dialog
  static Future<void> show(
    BuildContext context, {
    required AppRatingService ratingService,
    VoidCallback? onRated,
    VoidCallback? onRemindLater,
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        ratingService: ratingService,
        onRated: onRated,
        onRemindLater: onRemindLater,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppTheme.alanGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Gefällt dir Alanko?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Wir würden uns über eine Bewertung im App Store freuen!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Rate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await ratingService.requestReview();
                await ratingService.markAsRated();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  onRated?.call();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Jetzt bewerten',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () async {
              await ratingService.remindLater();
              if (context.mounted) {
                Navigator.of(context).pop();
                onRemindLater?.call();
              }
            },
            child: Text(
              'Später erinnern',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),

          TextButton(
            onPressed: () async {
              await ratingService.markAsRated();
              if (context.mounted) {
                Navigator.of(context).pop();
                onDismiss?.call();
              }
            },
            child: Text(
              'Nicht mehr fragen',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
