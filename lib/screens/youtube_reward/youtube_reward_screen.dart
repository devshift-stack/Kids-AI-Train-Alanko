import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../services/youtube_reward_service.dart';
import '../../services/alan_voice_service.dart';
import '../games/numbers/numbers_game_screen.dart';
import '../games/letters/letters_game_screen.dart';

class YouTubeRewardScreen extends ConsumerStatefulWidget {
  const YouTubeRewardScreen({super.key});

  @override
  ConsumerState<YouTubeRewardScreen> createState() => _YouTubeRewardScreenState();
}

class _YouTubeRewardScreenState extends ConsumerState<YouTubeRewardScreen> {
  YoutubePlayerController? _controller;
  int _selectedVideoIndex = 0;
  bool _showTaskOverlay = false;

  @override
  void initState() {
    super.initState();
    _initController();
    _welcomeMessage();
  }

  void _welcomeMessage() {
    final alan = ref.read(alanVoiceServiceProvider);
    alan.speak(
      'Super! Schau dir ein schönes Video an!',
      mood: AlanMood.happy,
    );
  }

  void _initController() {
    final service = ref.read(youtubeRewardServiceProvider);
    final videos = service.safeVideos;
    
    if (videos.isEmpty) return;
    
    _controller = YoutubePlayerController(
      initialVideoId: videos[_selectedVideoIndex]['id']!,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        enableCaption: false,
        forceHD: false,
        controlsVisibleAtStart: true,
      ),
    );
    
    _controller!.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller?.value.isPlaying ?? false) {
      ref.read(youtubeRewardServiceProvider).startWatching();
    } else {
      ref.read(youtubeRewardServiceProvider).pauseWatching();
    }
    
    // Prüfe ob Pause nötig
    final service = ref.read(youtubeRewardServiceProvider);
    if (!service.canWatch && !_showTaskOverlay) {
      _controller?.pause();
      setState(() => _showTaskOverlay = true);
      
      ref.read(alanVoiceServiceProvider).speak(
        'Zeit für eine kleine Aufgabe!',
        mood: AlanMood.encouraging,
      );
    }
  }

  void _selectVideo(int index) {
    final videos = ref.read(youtubeRewardServiceProvider).safeVideos;
    _controller?.load(videos[index]['id']!);
    setState(() => _selectedVideoIndex = index);
  }

  void _onTaskComplete() {
    ref.read(youtubeRewardServiceProvider).completeTask();
    
    final service = ref.read(youtubeRewardServiceProvider);
    if (service.canWatch) {
      setState(() => _showTaskOverlay = false);
      _controller?.play();
      
      ref.read(alanVoiceServiceProvider).speak(
        'Toll gemacht! Weiter schauen!',
        mood: AlanMood.excited,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    ref.read(youtubeRewardServiceProvider).pauseWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(youtubeRewardServiceProvider);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F4FD), Color(0xFFF8F9FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(service),
                  _buildVideoPlayer(),
                  _buildVideoList(service),
                ],
              ),
              if (_showTaskOverlay) _buildTaskOverlay(service),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(YouTubeRewardService service) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _buildStatusText(service),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildTimeIndicator(service),
        ],
      ),
    );
  }

  String _buildStatusText(YouTubeRewardService service) {
    if (service.remainingMinutes > 0) {
      return 'Noch ${service.remainingMinutes} Min heute';
    } else if (service.remainingMinutes == 0) {
      return 'Tageslimit erreicht';
    }
    return 'Viel Spaß!';
  }

  Widget _buildTimeIndicator(YouTubeRewardService service) {
    final progress = service.currentSessionMinutes / 
        (service.settings.watchMinutesAllowed > 0 ? service.settings.watchMinutesAllowed : 10);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? Colors.orange : AppTheme.primaryColor,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${service.minutesUntilPause} Min',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppTheme.primaryColor,
          progressColors: const ProgressBarColors(
            playedColor: AppTheme.primaryColor,
            handleColor: AppTheme.secondaryColor,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildVideoList(YouTubeRewardService service) {
    final videos = service.safeVideos;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sichere Videos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final isSelected = index == _selectedVideoIndex;
                  
                  return GestureDetector(
                    onTap: () => _selectVideo(index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              video['title']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskOverlay(YouTubeRewardService service) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏰',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Zeit für eine Aufgabe!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Erledige ${service.tasksNeeded} Aufgabe(n) um weiterzuschauen',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTaskButton(
                    'Zahlen',
                    Icons.looks_one,
                    const Color(0xFFFF9800),
                    () => _openTask('numbers'),
                  ),
                  _buildTaskButton(
                    'Buchstaben',
                    Icons.abc,
                    const Color(0xFF6C63FF),
                    () => _openTask('letters'),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
      ),
    );
  }

  Widget _buildTaskButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTask(String type) async {
    Widget screen;
    
    switch (type) {
      case 'numbers':
        screen = const NumbersGameScreen();
        break;
      case 'letters':
      default:
        screen = const LettersGameScreen();
        break;
    }
    
    // Öffne Spiel und warte auf Rückkehr
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    
    // Aufgabe als erledigt markieren
    _onTaskComplete();
  }
}
