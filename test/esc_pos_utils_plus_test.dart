import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

const String _sampleText = "Hello world, my name is John, I'm an engineer";

void main() {
  test('is capabilities.isEmpty is completed', () {
    expect(printCapabilities.isEmpty, true);
  });
  test('is capabilities.isNotEmpty is completed', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await CapabilityProfile.ensureProfileLoaded();
    CapabilityProfile.load();
    print("capabilities.length ${printCapabilities.length}");
    expect(printCapabilities.isNotEmpty, true);
  });

  group('word wrap', () {
    late CapabilityProfile profile;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      profile = await CapabilityProfile.load();
    });

    test('text() wraps at word boundaries when the line is too long', () {
      // mm58 has 32 characters per line, so the sample text must wrap.
      final generator = Generator(PaperSize.mm58, profile);
      final bytes = generator.text(_sampleText);
      final decoded = latin1.decode(bytes);

      expect(decoded.contains('Hello world, my name is John,'), isTrue);
      expect(decoded.contains("I'm an engineer"), isTrue);
      // Words should remain intact.
      expect(decoded.contains('John'), isTrue);
      expect(decoded.contains('engineer'), isTrue);
    });

    test('text() does not wrap when the text fits on one line', () {
      // mm80 has 48 characters per line, so the sample text fits without wrapping.
      final generator = Generator(PaperSize.mm80, profile);
      final bytes = generator.text(_sampleText);
      final decoded = latin1.decode(bytes);

      expect(decoded.contains(_sampleText), isTrue);
    });

    test('text() with wordWrap=false does not wrap', () {
      final generator = Generator(PaperSize.mm58, profile);
      final bytes = generator.text(_sampleText, wordWrap: false);
      final decoded = latin1.decode(bytes);

      // The original text is sent as a single line.
      expect(decoded.contains(_sampleText), isTrue);
    });

    test('row() wraps at word boundaries in a narrow column', () {
      // A width-6 column on mm80 has roughly 24 characters per line.
      final generator = Generator(PaperSize.mm80, profile);
      final bytes = generator.row([
        PosColumn(
          text: _sampleText,
          width: 6,
        ),
      ]);
      final decoded = latin1.decode(bytes);

      expect(decoded.contains('Hello world, my name is'), isTrue);
      expect(decoded.contains("John, I'm an engineer"), isTrue);
      // Words should remain intact.
      expect(decoded.contains('John'), isTrue);
      expect(decoded.contains('engineer'), isTrue);
    });

    test('row() with wordWrap=false falls back to character-level splitting', () {
      final generator = Generator(PaperSize.mm80, profile);
      final bytes = generator.row(
        [
          PosColumn(
            text: 'Hello world, my name is John',
            width: 2,
          ),
        ],
        wordWrap: false,
      );
      final decoded = latin1.decode(bytes);

      // With character-level splitting, "world" is broken into "wo" and "rld".
      expect(decoded.contains('world'), isFalse);
      expect(decoded.contains('wo'), isTrue);
      expect(decoded.contains('rld'), isTrue);
    });

    test('row() with wordWrap=true keeps words intact in a narrow column', () {
      final generator = Generator(PaperSize.mm80, profile);
      final bytes = generator.row(
        [
          PosColumn(
            text: 'Hello world, my name is John',
            width: 2,
          ),
        ],
      );
      final decoded = latin1.decode(bytes);

      expect(decoded.contains('Hello'), isTrue);
      expect(decoded.contains('world'), isTrue);
      expect(decoded.contains('John'), isTrue);
    });
  });
}
