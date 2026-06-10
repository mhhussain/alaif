import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Settings (spec §4.6): switch rows for sound/music/haptics, a best-score
/// card, an offline footer, and a primary Done that returns to wherever
/// settings was opened from.
class SettingsOverlay extends StatefulWidget {
  const SettingsOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  bool _sound = true;
  bool _music = true;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sound = await widget.game.settings.soundEnabled();
    final music = await widget.game.settings.musicEnabled();
    final haptics = await widget.game.settings.hapticsEnabled();
    if (!mounted) return;
    setState(() {
      _sound = sound;
      _music = music;
      _haptics = haptics;
    });
  }

  Widget _row({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AlaifSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AlaifType.body),
                Text(subtitle, style: AlaifType.caption),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Container(
      color: AlaifColors.paper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlaifSpacing.screenPad,
            vertical: AlaifSpacing.xl,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Settings', style: AlaifType.heading),
                        const SizedBox(height: AlaifSpacing.md),
                        Container(
                          width: 64,
                          height: 2,
                          color: AlaifColors.seal,
                        ),
                        const SizedBox(height: AlaifSpacing.xl),
                        _row(
                          title: 'Sound effects',
                          subtitle: 'Slices, bombs, and combos',
                          value: _sound,
                          onChanged: (v) {
                            setState(() => _sound = v);
                            game.settings.setSoundEnabled(v);
                            game.audio.enabled = v;
                          },
                        ),
                        const Divider(),
                        _row(
                          title: 'Music',
                          subtitle: 'Background music',
                          value: _music,
                          onChanged: (v) {
                            setState(() => _music = v);
                            game.settings.setMusicEnabled(
                              v,
                            ); // stored; no music player yet
                          },
                        ),
                        const Divider(),
                        _row(
                          title: 'Haptics',
                          subtitle: 'Vibration on slice and miss',
                          value: _haptics,
                          onChanged: (v) {
                            setState(() => _haptics = v);
                            game.settings.setHapticsEnabled(v);
                            game.haptics.enabled = v;
                          },
                        ),
                        const SizedBox(height: AlaifSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(AlaifSpacing.lg),
                          decoration: BoxDecoration(
                            border: Border.all(color: AlaifColors.hairline),
                            borderRadius: BorderRadius.circular(AlaifRadii.sm),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Best score',
                                style: AlaifType.bodyMuted,
                              ),
                              const Spacer(),
                              FutureBuilder<int>(
                                future: game.highScores.read(),
                                builder: (context, snapshot) => Text(
                                  formatScore(snapshot.data ?? 0),
                                  style: AlaifType.scoreHud.copyWith(
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Alaif · v1.0 · made offline',
                          style: AlaifType.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AlaifSpacing.lg),
                        ElevatedButton(
                          onPressed: game.closeSettings,
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
