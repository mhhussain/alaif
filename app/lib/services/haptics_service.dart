import 'package:flutter/services.dart';

/// Game-event haptics via Flutter's built-in [HapticFeedback] (no plugin).
/// Light tap on a slice; heavy thud on a bomb or a missed letter.
/// [enabled] is driven by the persisted settings.
class HapticsService {
  bool enabled = true;

  void onSlice() {
    if (enabled) HapticFeedback.lightImpact();
  }

  void onBomb() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  void onMiss() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
