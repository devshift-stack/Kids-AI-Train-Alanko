import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/safe_videos.dart';
import '../../services/parental_control_service.dart';
import '../../services/user_profile_service.dart';
import 'task_gate_screen.dart';

class VideoRewardScreen extends ConsumerStatefulWidget {
  final String? videoId;

  const VideoRewardScreen({super.key, this.videoId});

  @override
  ConsumerState<VideoRewardScreen> createState() => _VideoRewardScreenState();
}

class _VideoRewardScreenState extends ConsumerState<VideoRewardScreen> {
  late YoutubePlayerController _controller;
  Timer? _watchTimer;
  int _secondsWatched = 0;
  bool _isPaused = false;
  late List<Map<String, String>> _videos;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _initializePlayer();
    _startWatchSession();
  }

  void _loadVideos() {
    final profile = ref.read(activeProfileProvider);
    final languageCode = profile?.languageCode ?? 'de';
    _videos = SafeVideos.getByLanguage(languageCode);
    if (_videos.isEmpty) {
      _videos = SafeVideos.german; // Fallback
    }
  }

  void _initializePlayer() {
    final videoId = widget.videoId ?? _videos.first['id']!;
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _startWatchSession() {
    final parentalService = ref.read(parentalControlServiceProvider);
    parentalService.startWatchSession();
  }

  void _onPlayerStateChange() {
    if (_controller.value.isPlaying && !_isPaused) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsWatched++;
      });

      final parentalService = ref.read(parentalControlServiceProvider);
      parentalService.updateWatchTime(_secondsWatched);

      // Check if should pause for tasks
      if (parentalService.shouldPauseForTasks()) {
        _pauseForTasks();
      }
    });
  }

  void _stopTimer() {
    _watchTimer?.cancel();
  }

  void _pauseForTasks() {
    _controller.pause();
    _stopTimer();
    setState(() {
      _isPaused = true;
    });

    // Navigate to task gate
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskGateScreen(
          onTasksCompleted: _onTasksCompleted,
        ),
      ),
    );
  }

  void _onTasksCompleted() {
    setState(() {
      _isPaused = false;
      _secondsWatched = 0;
    });

    final parentalService = ref.read(parentalControlServiceProvider);
    parentalService.startWatchSession(); // Reset session

    _controller.play();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentalService = ref.watch(parentalControlServiceProvider);
    final settings = parentalService.settings;
    final remainingSeconds = (settings.videoMinutesAllowed * 60) - _secondsWatched;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Videos'),
        actions: [
          // Time indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: remainingSeconds <= 60 ? Colors.red : AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _formatTime(remainingSeconds.clamp(0, settings.videoMinutesAllowed * 60)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // YouTube Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppTheme.primaryColor,
            progressColors: ProgressBarColors(
              playedColor: AppTheme.primaryColor,
              handleColor: AppTheme.primaryColor,
            ),
            onReady: () {
              debugPrint('YouTube Player is ready.');
            },
          ),

          // Video info and controls
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: Column(
                children: [
                  // Progress info
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoCard(
                          icon: Icons.play_circle_outline,
                          label: 'Geschaut',
                          value: _formatTime(_secondsWatched),
                        ),
                        _InfoCard(
                          icon: Icons.hourglass_empty,
                          label: 'Übrig',
                          value: _formatTime(remainingSeconds.clamp(0, 9999)),
                        ),
                        _InfoCard(
                          icon: Icons.task_alt,
                          label: 'Aufgaben',
                          value: '${settings.tasksRequired}',
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Video list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        final isPlaying = _controller.metadata.videoId == video['id'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isPlaying ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
                          child: ListTile(
                            leading: Container(
                              width: 80,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  YoutubePlayer.getThumbnail(videoId: video['id']!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.video_library),
                                ),
                              ),
                            ),
                            title: Text(
                              video['title']!,
                              style: TextStyle(
                                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                color: isPlaying ? AppTheme.primaryColor : null,
                              ),
                            ),
                            trailing: isPlaying
                                ? const Icon(Icons.play_arrow, color: AppTheme.primaryColor)
                                : null,
                            onTap: () {
                              _controller.load(video['id']!);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
