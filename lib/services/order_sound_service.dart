import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import 'order_sound_stub.dart'
    if (dart.library.js_interop) 'order_sound_web.dart';

class OrderSoundService {
  static String? _cachedChimeDataUri;

  /// Plays a pleasant 4-note ascending order confirmation chime on both Web and Mobile
  static Future<void> playOrderPlacedSound() async {
    try {
      // 1. Tactile + native system sound feedback
      await HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.alert);
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}

    try {
      // 2. Synthesize & play polyphonic 4-note ascending chime WAV (C5 -> E5 -> G5 -> C6)
      _cachedChimeDataUri ??= _buildSuccessChimeDataUri();
      playWebAudioDataUri(_cachedChimeDataUri!);
    } catch (_) {}

    // 3. Secondary rhythmic tap for native devices where only SystemSound is active
    Future.delayed(const Duration(milliseconds: 140), () async {
      try {
        await HapticFeedback.mediumImpact();
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    });
  }

  static void _writeUint16LE(Uint8List buf, int offset, int value) {
    buf[offset] = value & 0xFF;
    buf[offset + 1] = (value >> 8) & 0xFF;
  }

  static void _writeInt16LE(Uint8List buf, int offset, int value) {
    final int unsigned = value < 0 ? (0x10000 + value) : value;
    buf[offset] = unsigned & 0xFF;
    buf[offset + 1] = (unsigned >> 8) & 0xFF;
  }

  static void _writeUint32LE(Uint8List buf, int offset, int value) {
    buf[offset] = value & 0xFF;
    buf[offset + 1] = (value >> 8) & 0xFF;
    buf[offset + 2] = (value >> 16) & 0xFF;
    buf[offset + 3] = (value >> 24) & 0xFF;
  }

  static String _buildSuccessChimeDataUri() {
    const int sampleRate = 22050;
    const double totalDurationSec = 0.72;
    final int numSamples = (sampleRate * totalDurationSec).round();

    // 4-note cheerful ascending chime (C5, E5, G5, C6)
    const List<double> freqs = [523.25, 659.25, 783.99, 1046.50];
    const List<double> starts = [0.0, 0.11, 0.22, 0.34];
    const List<double> durations = [0.22, 0.22, 0.24, 0.38];

    final int dataSize = numSamples * 2;
    final int fileSize = 36 + dataSize;
    final Uint8List wavBytes = Uint8List(44 + dataSize);

    // "RIFF"
    wavBytes[0] = 0x52;
    wavBytes[1] = 0x49;
    wavBytes[2] = 0x46;
    wavBytes[3] = 0x46;
    _writeUint32LE(wavBytes, 4, fileSize);
    // "WAVE"
    wavBytes[8] = 0x57;
    wavBytes[9] = 0x41;
    wavBytes[10] = 0x56;
    wavBytes[11] = 0x45;
    // "fmt "
    wavBytes[12] = 0x66;
    wavBytes[13] = 0x6D;
    wavBytes[14] = 0x74;
    wavBytes[15] = 0x20;
    _writeUint32LE(wavBytes, 16, 16); // PCM chunk size
    _writeUint16LE(wavBytes, 20, 1); // AudioFormat = 1 (PCM)
    _writeUint16LE(wavBytes, 22, 1); // NumChannels = 1 (Mono)
    _writeUint32LE(wavBytes, 24, sampleRate);
    _writeUint32LE(wavBytes, 28, sampleRate * 2); // ByteRate
    _writeUint16LE(wavBytes, 32, 2); // BlockAlign
    _writeUint16LE(wavBytes, 34, 16); // BitsPerSample
    // "data"
    wavBytes[36] = 0x64;
    wavBytes[37] = 0x61;
    wavBytes[38] = 0x74;
    wavBytes[39] = 0x61;
    _writeUint32LE(wavBytes, 40, dataSize);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sampleValue = 0.0;

      for (int n = 0; n < freqs.length; n++) {
        final double dt = t - starts[n];
        if (dt >= 0 && dt <= durations[n]) {
          final double attack = (dt / 0.012).clamp(0.0, 1.0);
          final double decay = exp(-dt * 6.5);
          final double env = attack * decay;

          final double fundamental = sin(2.0 * pi * freqs[n] * dt);
          final double overtone = 0.28 * sin(2.0 * pi * (freqs[n] * 2.0) * dt);
          sampleValue += (fundamental + overtone) * env * 0.42;
        }
      }

      final int clamped =
          (sampleValue.clamp(-1.0, 1.0) * 32767.0).round().clamp(-32768, 32767);
      _writeInt16LE(wavBytes, 44 + (i * 2), clamped);
    }

    final String base64Wav = base64Encode(wavBytes);
    return 'data:audio/wav;base64,$base64Wav';
  }
}
