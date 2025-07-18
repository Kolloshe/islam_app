import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/reciter_model.dart';

class AudioPlayerWidget extends StatelessWidget {
  final Reciter? reciter;
  final int? surahNumber;
  final String? surahName;

  const AudioPlayerWidget({super.key, this.reciter, this.surahNumber, this.surahName});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.hasAudio) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current playing info
              Row(
                children: [
                  Icon(Icons.play_circle_outline, color: Theme.of(context).primaryColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audioProvider.currentReciter?.name ?? 'Unknown Reciter',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          surahName ?? 'Surah ${audioProvider.currentSurahNumber}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Speed control
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed),
                    onSelected: (speed) => audioProvider.setSpeed(speed),
                    itemBuilder:
                        (context) => [
                          for (double speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                            PopupMenuItem(
                              value: speed,
                              child: Row(
                                children: [
                                  if (audioProvider.playbackSpeed == speed)
                                    Icon(
                                      Icons.check,
                                      color: Theme.of(context).primaryColor,
                                      size: 16,
                                    ),
                                  const SizedBox(width: 8),
                                  Text('${speed}x'),
                                ],
                              ),
                            ),
                        ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      trackHeight: 3.0,
                    ),
                    child: Slider(
                      value: audioProvider.progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        audioProvider.seekToProgress(value);
                      },
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.grey[300],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          audioProvider.formattedPosition,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          audioProvider.formattedDuration,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Skip backward
                  IconButton(
                    onPressed: () => audioProvider.skipBackward(),
                    icon: const Icon(Icons.replay_10),
                    iconSize: 28,
                    color: Theme.of(context).primaryColor,
                  ),

                  // Play/Pause
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed:
                          audioProvider.canPlay ? () => audioProvider.togglePlayPause() : null,
                      icon: Icon(
                        audioProvider.isLoading
                            ? Icons.hourglass_empty
                            : audioProvider.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 32,
                    ),
                  ),

                  // Skip forward
                  IconButton(
                    onPressed: () => audioProvider.skipForward(),
                    icon: const Icon(Icons.forward_10),
                    iconSize: 28,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),

              // Error message
              if (audioProvider.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          audioProvider.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
