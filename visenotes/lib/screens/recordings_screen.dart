import 'package:flutter/material.dart';
import '../services/recording_service.dart';
import '../models/recording.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  late RecordingService _recordingService;
  late AudioPlayer _audioPlayer;
  String _searchQuery = '';
  String? _feedbackMessage;
  Color _feedbackColor = const Color(0xFF9859FF);

  // State tracking for playback
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;

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
          _currentPosition = Duration.zero;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _currentDuration = duration ?? Duration.zero;
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
            // Feedback banner
            if (_feedbackMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    key: ValueKey(_feedbackMessage),
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _feedbackColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                          onTap: () => isCurrentlyPlaying
                              ? _pauseAudio()
                              : _playAudio(audio),
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
                                        ).withAlpha(77),
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
                                // Action buttons
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        InkWell(
                                          onTap: () => _downloadAudio(audio),
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.download,
                                              color: Color(0xFF9859FF),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (audio.cleanedAudio != null &&
                                                audio.cleanedAudio!.isNotEmpty) {
                                              OpenFile.open(audio.cleanedAudio!);
                                            } else {
                                              _showInlineFeedback(
                                                'No cleaned audio file found',
                                                color: Colors.redAccent,
                                              );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.open_in_new,
                                              color: Color(0xFF9859FF),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (audio.cleanedAudio != null &&
                                                audio.cleanedAudio!.isNotEmpty) {
                                              Share.shareXFiles([
                                                XFile(audio.cleanedAudio!),
                                              ]);
                                              _showInlineFeedback(
                                                'Sharing audio',
                                              );
                                            } else {
                                              _showInlineFeedback(
                                                'No cleaned audio file found',
                                                color: Colors.redAccent,
                                              );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.share,
                                              color: Color(0xFF9859FF),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            _recordingService.removeCleanedAudio(audio.id);
                                            if (_currentlyPlayingId == audio.id) {
                                              _audioPlayer.stop();
                                              setState(() {
                                                _currentlyPlayingId = null;
                                                _isPlaying = false;
                                                _currentPosition = Duration.zero;
                                              });
                                            }
                                            setState(() {});
                                            _showInlineFeedback(
                                              'Audio deleted',
                                              color: Colors.redAccent,
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
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
            if (_currentlyPlayingId != null)
              _buildPlaybackFooter(filteredAudios),
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

  Future<void> _seekAudio(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showInlineFeedback('Unable to seek audio: $e', color: Colors.redAccent);
    }
  }

  Future<void> _seekRelative(Duration offset) async {
    final maxDuration = _currentDuration;
    final targetPosition = _currentPosition + offset;
    final clampedPosition = targetPosition < Duration.zero
        ? Duration.zero
        : targetPosition > maxDuration
        ? maxDuration
        : targetPosition;

    await _seekAudio(clampedPosition);
  }

  Future<void> _playAudio(Recording audio) async {
    if (audio.cleanedAudio == null || audio.cleanedAudio!.isEmpty) {
      _showInlineFeedback(
        'No cleaned audio available for this recording',
        color: Colors.redAccent,
      );
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

      _showInlineFeedback('Playing: ${audio.title}', color: Colors.greenAccent);
    } catch (e) {
      _showInlineFeedback('Error playing audio: $e', color: Colors.redAccent);
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
      _showInlineFeedback('Error pausing audio: $e', color: Colors.redAccent);
    }
  }

  Widget _buildPlaybackFooter(List<Recording> audios) {
    final currentAudio = audios.firstWhere(
      (audio) => audio.id == _currentlyPlayingId,
      orElse: () => audios.first,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9859FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Now playing',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentAudio.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Slider(
            min: 0,
            max: _currentDuration.inMilliseconds.toDouble().clamp(
              1,
              double.infinity,
            ),
            value: _currentPosition.inMilliseconds
                .clamp(0, _currentDuration.inMilliseconds)
                .toDouble(),
            activeColor: const Color(0xFF9859FF),
            inactiveColor: Colors.grey[300],
            onChanged: (value) {
              _seekAudio(Duration(milliseconds: value.toInt()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                _formatDuration(_currentDuration),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => _playPrevious(audios),
                icon: const Icon(Icons.skip_previous, color: Color(0xFF9859FF)),
              ),
              IconButton(
                onPressed: () => _seekRelative(const Duration(seconds: -10)),
                icon: const Icon(Icons.replay_10, color: Color(0xFF9859FF)),
              ),
              IconButton(
                onPressed: () =>
                    _isPlaying ? _pauseAudio() : _playAudio(currentAudio),
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: const Color(0xFF9859FF),
                  size: 36,
                ),
              ),
              IconButton(
                onPressed: () => _seekRelative(const Duration(seconds: 10)),
                icon: const Icon(Icons.forward_10, color: Color(0xFF9859FF)),
              ),
              IconButton(
                onPressed: () => _playNext(audios),
                icon: const Icon(Icons.skip_next, color: Color(0xFF9859FF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _playNext(List<Recording> audios) async {
    final currentIndex = audios.indexWhere(
      (audio) => audio.id == _currentlyPlayingId,
    );
    if (currentIndex >= 0 && currentIndex < audios.length - 1) {
      await _playAudio(audios[currentIndex + 1]);
    }
  }

  Future<void> _playPrevious(List<Recording> audios) async {
    final currentIndex = audios.indexWhere(
      (audio) => audio.id == _currentlyPlayingId,
    );
    if (currentIndex > 0) {
      await _playAudio(audios[currentIndex - 1]);
    }
  }

  Future<void> _downloadAudio(Recording audio) async {
    if (audio.cleanedAudio == null || audio.cleanedAudio!.isEmpty) {
      _showInlineFeedback(
        'No cleaned audio available',
        color: Colors.redAccent,
      );
      return;
    }

    try {
      _showInlineFeedback('Downloading...', color: Colors.greenAccent);

      final success = await _recordingService.downloadCleanedAudio(audio);

      if (success) {
        _showInlineFeedback(
          'Audio downloaded successfully',
          color: Colors.greenAccent,
        );
      } else {
        _showInlineFeedback('Download cancelled', color: Colors.grey);
      }
    } catch (e) {
      _showInlineFeedback(
        'Error downloading audio: $e',
        color: Colors.redAccent,
      );
    }
  }

  void _showInlineFeedback(
    String message, {
    Color color = const Color(0xFF9859FF),
  }) {
    setState(() {
      _feedbackMessage = message;
      _feedbackColor = color;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }
}
