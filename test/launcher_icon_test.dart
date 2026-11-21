import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Android chooses mipmap-night resources on supported launchers in dark mode;
/// API 26+ adaptive icons also pick drawable-night foreground and values-night
/// background without changing the launcher component at runtime.
void main() {
  test('store launcher assets have distinct, valid light and dark artwork', () {
    const root = 'android/app/src/main/res';
    const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final day = File('$root/mipmap-$density/ic_launcher.png');
      final night = File('$root/mipmap-night-$density/ic_launcher.png');
      expect(day.existsSync(), isTrue, reason: day.path);
      expect(night.existsSync(), isTrue, reason: night.path);
      final dayBytes = day.readAsBytesSync();
      final nightBytes = night.readAsBytesSync();
      expect(dayBytes.take(8).toList(), pngHeader);
      expect(nightBytes.take(8).toList(), pngHeader);
      expect(dayBytes, isNot(equals(nightBytes)),
          reason: 'Light and dark artwork must differ at $density');
    }

    final adaptive = File(
      '$root/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(adaptive, contains('@drawable/agent_launcher_foreground'));
    expect(adaptive, contains('@color/agent_launcher_background'));

    final dayForeground =
        File('$root/drawable-nodpi/agent_launcher_foreground.png');
    final nightForeground =
        File('$root/drawable-night-nodpi/agent_launcher_foreground.png');
    expect(dayForeground.existsSync(), isTrue);
    expect(nightForeground.existsSync(), isTrue);
    expect(dayForeground.readAsBytesSync(), isNot(equals(
      nightForeground.readAsBytesSync(),
    )));

    final dayColor =
        File('$root/values/launcher_colors.xml').readAsStringSync();
    final nightColor =
        File('$root/values-night/launcher_colors.xml').readAsStringSync();
    expect(dayColor, contains('agent_launcher_background'));
    expect(nightColor, contains('agent_launcher_background'));
    expect(dayColor, isNot(nightColor));

    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher"'));
  });
}
