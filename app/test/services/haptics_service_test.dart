import 'package:alaif/services/haptics_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('slice fires a light impact', () {
    HapticsService().onSlice();
    expect(calls, hasLength(1));
    expect(calls.single.method, 'HapticFeedback.vibrate');
    expect(calls.single.arguments, 'HapticFeedbackType.lightImpact');
  });

  test('bomb and miss fire heavy impacts', () {
    final service = HapticsService();
    service.onBomb();
    service.onMiss();
    expect(calls, hasLength(2));
    expect(calls[0].arguments, 'HapticFeedbackType.heavyImpact');
    expect(calls[1].arguments, 'HapticFeedbackType.heavyImpact');
  });

  test('disabled service stays silent', () {
    final service = HapticsService()..enabled = false;
    service.onSlice();
    service.onBomb();
    service.onMiss();
    expect(calls, isEmpty);
  });
}
