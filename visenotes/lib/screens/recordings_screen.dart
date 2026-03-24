import 'package:flutter/material.dart';
import '../services/recording_service.dart';
import '../models/recording.dart';
import 'package:just_audio/just_audio.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  late RecordingService _recordingService;
  late AudioPlayer _audioPlayer;
  String _searchQuery = '';

  // State tracking for playback
  String? _currentlyPlayingId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _recordingService = RecordingService();
    _audioPlayer = AudioPlayer();

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      setState(() {
        _isPlaying = playerState.playing;
      });

      // Reset when audio finishes
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _currentlyPlayingId = null;
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAudios = _recordingService.cleanedAudios
        .where(
          (rec) =>
              rec.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              rec.category.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF9859FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                'Cleaned Audio',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search Cleaned Audio',
                  hintStyle: const TextStyle(color: Color(0xFF9859FF)),
                  prefixIcon: const Icon(Icons.mic, color: Color(0xFF9859FF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFF9859FF),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFF9859FF),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFCCCCFF),
                ),
              ),
            ),
            // Cleaned audio list
            Expanded(
              child: filteredAudios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cleaned audio files',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredAudios.length,
                      itemBuilder: (context, index) {
                        final audio = filteredAudios[index];
                        final isCurrentlyPlaying =
                            _currentlyPlayingId == audio.id && _isPlaying;

                        return GestureDetector(
                          onTap: () {
                            // Handle play or download cleaned audio
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCurrentlyPlaying
                                    ? const Color(0xFF9859FF)
                                    : const Color(0xFF9859FF),
                                width: isCurrentlyPlaying ? 3 : 2,
                              ),
                              boxShadow: isCurrentlyPlaying
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF9859FF,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                // Play/Pause button
                                InkWell(
                                  onTap: () => isCurrentlyPlaying
                                      ? _pauseAudio()
                                      : _playAudio(audio),
                                  borderRadius: BorderRadius.circular(25),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9859FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCurrentlyPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Audio info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        audio.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFCCCCFF),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              audio.category,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF9859FF),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _formatDate(audio.date),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Download button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => _downloadAudio(audio),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.download,
                                          color: const Color(0xFF9859FF),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatDuration(audio.duration),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return 'March ${date.day}, ${date.year}';
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _playAudio(Recording audio) async {
    if (audio.cleanedAudio == null || audio.cleanedAudio!.isEmpty) {
      _showSnackBar('No cleaned audio available for this recording');
      return;
    }

    try {
      // Stop previous audio if any
      if (_currentlyPlayingId != null && _currentlyPlayingId != audio.id) {
        await _audioPlayer.stop();
      }

      // Load and play the new audio
      setState(() {
        _currentlyPlayingId = audio.id;
      });

      await _audioPlayer.setFilePath(audio.cleanedAudio!);
      await _audioPlayer.play();

      _showSnackBar('Playing: ${audio.title}');
    } catch (e) {
      _showSnackBar('Error playing audio: $e');
      setState(() {
        _currentlyPlayingId = null;
        _isPlaying = false;
      });
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _showSnackBar('Error pausing audio: $e');
    }
  }

  Future<void> _downloadAudio(Recording audio) async {
    if (audio.cleanedAudio == null || audio.cleanedAudio!.isEmpty) {
      _showSnackBar('No cleaned audio available');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading...'),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await _recordingService.downloadCleanedAudio(audio);

      if (success) {
        _showSnackBar('Audio downloaded successfully');
      } else {
        _showSnackBar('Download cancelled');
      }
    } catch (e) {
      _showSnackBar('Error downloading audio: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
