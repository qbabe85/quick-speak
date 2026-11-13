import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const QuickSpeekApp());
}

class QuickSpeekApp extends StatelessWidget {
  const QuickSpeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Speek',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEF6C00)),
      ),
      home: const WordScreen(),
    );
  }
}

class ReadingWord {
  const ReadingWord({
    required this.word,
    required this.syllables,
    required this.imageFile,
  });

  final String word;
  final List<String> syllables;
  final String imageFile;

  String get assetPath => 'assets/images/$imageFile';
}

const List<ReadingWord> readingWords = [
  ReadingWord(word: 'baba', syllables: ['ba', 'ba'], imageFile: 'baba.png'),
  ReadingWord(word: 'buty', syllables: ['bu', 'ty'], imageFile: 'buty.png'),
  ReadingWord(word: 'lampa', syllables: ['lam', 'pa'], imageFile: 'lampa.png'),
  ReadingWord(word: 'auto', syllables: ['au', 'to'], imageFile: 'auto.png'),
  ReadingWord(word: 'jajo', syllables: ['ja', 'jo'], imageFile: 'jajo.png'),
  ReadingWord(word: 'lody', syllables: ['lo', 'dy'], imageFile: 'lody.png'),
  ReadingWord(word: 'koza', syllables: ['ko', 'za'], imageFile: 'koza.png'),
  ReadingWord(word: 'sowa', syllables: ['so', 'wa'], imageFile: 'sowa.png'),
  ReadingWord(word: 'kotek', syllables: ['ko', 'tek'], imageFile: 'kotek.png'),
  ReadingWord(word: 'woda', syllables: ['wo', 'da'], imageFile: 'woda.png'),
  ReadingWord(word: 'mleko', syllables: ['mle', 'ko'], imageFile: 'mleko.png'),
  ReadingWord(word: 'oko', syllables: ['o', 'ko'], imageFile: 'oko.png'),
  ReadingWord(word: 'ręka', syllables: ['rę', 'ka'], imageFile: 'reka.png'),
  ReadingWord(word: 'noga', syllables: ['no', 'ga'], imageFile: 'noga.png'),
  ReadingWord(word: 'balon', syllables: ['ba', 'lon'], imageFile: 'balon.png'),
  ReadingWord(word: 'rower', syllables: ['ro', 'wer'], imageFile: 'rower.png'),
  ReadingWord(word: 'sanki', syllables: ['san', 'ki'], imageFile: 'sanki.png'),
  ReadingWord(word: 'kupa', syllables: ['ku', 'pa'], imageFile: 'kupa.png'),
  ReadingWord(word: 'kawa', syllables: ['ka', 'wa'], imageFile: 'kawa.png'),
  ReadingWord(word: 'pepa', syllables: ['pe', 'pa'], imageFile: 'pepa.png'),
  ReadingWord(word: 'spanie', syllables: ['spa', 'nie'], imageFile: 'spanie.png'),
  ReadingWord(word: 'krowa', syllables: ['kro', 'wa'], imageFile: 'krowa.png'),
  ReadingWord(word: 'kaczka', syllables: ['kacz', 'ka'], imageFile: 'kaczka.png'),
  ReadingWord(word: 'lama', syllables: ['la', 'ma'], imageFile: 'lama.png'),
];

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  static const Duration _syllablePause = Duration(milliseconds: 400);
  static const String _voiceName = 'pl-PL-Standard-F';

  final FlutterTts _tts = FlutterTts();
  final Random _random = Random();

  late int _currentIndex;
  late final Future<void> _speechReady;
  bool _speechError = false;
  int _speechGeneration = 0;
  int? _activeSyllableIndex;

  ReadingWord get _currentWord => readingWords[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = _random.nextInt(readingWords.length);
    _speechReady = _configureSpeech();
    final generation = _speechGeneration;
    unawaited(
      _speechReady.then((_) {
        if (!mounted || generation != _speechGeneration) return;
        unawaited(_speakCurrentWord());
      }),
    );
  }

  Future<void> _configureSpeech() async {
    try {
      await _tts.setLanguage('pl-PL');
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.35);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.setVoice({'name': _voiceName, 'locale': 'pl-PL'});
    } on Exception {
      if (!mounted) return;
      setState(() => _speechError = true);
    }
  }

  Future<void> _speakCurrentWord() async {
    final generation = ++_speechGeneration;
    final word = _currentWord;
    await _speechReady;
    if (!mounted || generation != _speechGeneration) return;

    try {
      await _tts.stop();
      if (generation != _speechGeneration) return;

      if (word.syllables.length > 1) {
        for (var i = 0; i < word.syllables.length; i++) {
          if (generation != _speechGeneration) return;
          setState(() => _activeSyllableIndex = i);
          await _tts.speak(word.syllables[i]);
          if (generation != _speechGeneration) return;
          setState(() => _activeSyllableIndex = null);
          await Future<void>.delayed(_syllablePause);
        }

        if (generation != _speechGeneration) return;
        await _tts.speak(word.word);
      } else {
        setState(() => _activeSyllableIndex = 0);
        await _tts.speak(word.word);
        if (generation != _speechGeneration) return;
        setState(() => _activeSyllableIndex = null);
      }
    } on Exception {
      if (!mounted || generation != _speechGeneration) return;
      setState(() => _speechError = true);
    }
  }

  void _showNextWord() {
    if (readingWords.length < 2) return;

    var nextIndex = _random.nextInt(readingWords.length - 1);
    if (nextIndex >= _currentIndex) {
      nextIndex++;
    }

    setState(() {
      _currentIndex = nextIndex;
      _activeSyllableIndex = null;
    });

    unawaited(_speakCurrentWord());
  }

  @override
  void dispose() {
    _speechGeneration++;
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showNextWord,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F6), Color(0xFFFFD6E7), Color(0xFFF7C8E0)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  const _Header(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _WordImage(word: _currentWord),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SyllableCard(
                    word: _currentWord,
                    activeSyllableIndex: _activeSyllableIndex,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _speechError
                        ? 'Nie udało się włączyć mowy. Sprawdź głos w ustawieniach telefonu.'
                        : 'Dotknij ekranu, aby zobaczyć kolejne słowo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.record_voice_over_rounded,
          color: Color(0xFFEF6C00),
          size: 34,
        ),
        const SizedBox(width: 10),
        Text(
          'Quick Speek',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.brown.shade800,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'czytamy razem',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _WordImage extends StatelessWidget {
  const _WordImage({required this.word});

  final ReadingWord word;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        word.assetPath,
        key: ValueKey(word.assetPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _ImagePlaceholder(fileName: word.imageFile),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 96, color: Colors.brown.shade300),
          const SizedBox(height: 12),
          Text(
            'Miejsce na obrazek',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fileName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.brown.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyllableCard extends StatelessWidget {
  const _SyllableCard({required this.word, this.activeSyllableIndex});

  final ReadingWord word;
  final int? activeSyllableIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < word.syllables.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: i == activeSyllableIndex
                      ? const Color(0xFFC8E6C9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: 76,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: i == activeSyllableIndex
                        ? const Color(0xFF1B5E20)
                        : Colors.brown.shade800,
                  ),
                  child: Text(word.syllables[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
