import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  ReadingWord(
    word: 'spanie',
    syllables: ['spa', 'nie'],
    imageFile: 'spanie.png',
  ),
  ReadingWord(word: 'krowa', syllables: ['kro', 'wa'], imageFile: 'krowa.png'),
  ReadingWord(
    word: 'kaczka',
    syllables: ['kacz', 'ka'],
    imageFile: 'kaczka.png',
  ),
  ReadingWord(word: 'lama', syllables: ['la', 'ma'], imageFile: 'lama.png'),
];

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  static const Duration _syllablePause = Duration(milliseconds: 400);
  static const int _listenSeconds = 5;
  static const Duration _listenDuration = Duration(seconds: _listenSeconds);
  static const String _voiceName = 'pl-PL-Standard-F';
  static const List<Color> _pinkGradient = [
    Color(0xFFFFF0F6),
    Color(0xFFFFD6E7),
    Color(0xFFF7C8E0),
  ];
  static const List<Color> _greenGradient = [
    Color(0xFFE8F5E9),
    Color(0xFFC8E6C9),
    Color(0xFFA5D6A7),
  ];

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  final Random _random = Random();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late int _currentIndex;
  late final Future<void> _speechReady;
  bool _speechError = false;
  bool _voiceReady = false;
  int _speechGeneration = 0;
  int? _activeSyllableIndex;

  Future<bool>? _recognitionInit;
  int _listenGeneration = 0;
  bool _isListening = false;
  bool _sessionActive = false;
  bool _wordCorrect = false;
  String? _recognitionError;
  String _committedText = '';
  Timer? _countdownTimer;
  int _secondsLeft = 0;

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
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.35);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _ensurePolishVoice();
    } on Exception {
      if (!mounted) return;
      setState(() => _speechError = true);
    }
  }

  Future<bool> _applyPolishVoice() async {
    try {
      final language = await _tts.setLanguage('pl-PL');
      final voice = await _tts.setVoice({
        'name': _voiceName,
        'locale': 'pl-PL',
      });
      return (language == 1 || language == true) &&
          (voice == 1 || voice == true);
    } on Exception {
      return false;
    }
  }

  Future<void> _ensurePolishVoice() async {
    if (_voiceReady) return;
    for (var attempt = 0; attempt < 20; attempt++) {
      if (await _applyPolishVoice()) {
        _voiceReady = true;
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _speakCurrentWord() async {
    final generation = ++_speechGeneration;
    final word = _currentWord;
    await _speechReady;
    if (!mounted || generation != _speechGeneration) return;
    if (!_voiceReady) {
      _voiceReady = await _applyPolishVoice();
      if (!mounted || generation != _speechGeneration) return;
    }

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

    _listenGeneration++;
    unawaited(_speech.stop());
    _stopCountdown();

    setState(() {
      _currentIndex = nextIndex;
      _activeSyllableIndex = null;
      _isListening = false;
      _wordCorrect = false;
      _recognitionError = null;
    });

    unawaited(_speakCurrentWord());
  }

  void _repeatWord() {
    _listenGeneration++;
    unawaited(_speech.stop());
    _stopCountdown();

    setState(() {
      _activeSyllableIndex = null;
      _isListening = false;
      _recognitionError = null;
    });

    unawaited(_speakCurrentWord());
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    final generation = ++_listenGeneration;
    _speechGeneration++;
    await _tts.stop();
    if (!mounted || generation != _listenGeneration) return;

    setState(() {
      _isListening = true;
      _wordCorrect = false;
      _recognitionError = null;
      _activeSyllableIndex = null;
    });
    _sessionActive = true;
    _committedText = '';
    _startCountdown();

    try {
      _recognitionInit ??= _speech.initialize(
        onStatus: _onRecognitionStatus,
        onError: _onRecognitionError,
      );
      final available = await _recognitionInit!;
      if (!mounted || generation != _listenGeneration) return;
      if (!available) {
        _recognitionInit = null;
        _stopCountdown();
        setState(() {
          _isListening = false;
          _recognitionError =
              'Rozpoznawanie mowy jest niedostępne na tym telefonie.';
        });
        return;
      }

      await _beginListen(generation);
    } on Exception {
      if (!mounted || generation != _listenGeneration) return;
      _stopCountdown();
      setState(() {
        _isListening = false;
        _recognitionError = 'Nie udało się uruchomić nagrywania.';
      });
    }
  }

  Future<void> _beginListen(int generation) async {
    if (!mounted || generation != _listenGeneration) return;
    try {
      await _speech.listen(
        onResult: (result) => _onRecognitionResult(result, generation),
        listenOptions: SpeechListenOptions(
          localeId: 'pl_PL',
          listenFor: _listenDuration,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } on Exception {
      return;
    }
  }

  void _onRecognitionResult(SpeechRecognitionResult result, int generation) {
    if (!mounted || generation != _listenGeneration) return;

    final utterance = result.recognizedWords;
    final combined = _committedText.isEmpty
        ? utterance
        : '$_committedText $utterance';
    if (result.finalResult) {
      _committedText = combined;
    }

    if (!_matchesWord(_normalize(combined))) return;

    _stopCountdown();
    unawaited(_speech.stop());
    setState(() {
      _wordCorrect = true;
      _isListening = false;
    });
  }

  bool _matchesWord(String heard) {
    if (heard.isEmpty) return false;
    final target = _normalize(_currentWord.word);
    if (target.isEmpty) return false;
    if (heard.contains(target)) return true;

    var searchFrom = 0;
    for (final syllable in _currentWord.syllables) {
      final part = _normalize(syllable);
      if (part.isEmpty) continue;
      final index = heard.indexOf(part, searchFrom);
      if (index < 0) return false;
      searchFrom = index + part.length;
    }
    return true;
  }

  void _onRecognitionStatus(String status) {
    if (!mounted) return;
    if (status != 'done' && status != 'notListening') return;

    if (_wordCorrect) {
      _stopCountdown();
      if (_isListening) {
        setState(() => _isListening = false);
      }
      return;
    }
    if (!_sessionActive) return;

    final generation = _listenGeneration;
    if (_secondsLeft > 0) {
      unawaited(_beginListen(generation));
    } else {
      _finishSession();
    }
  }

  void _onRecognitionError(SpeechRecognitionError error) {
    if (!mounted || _wordCorrect) return;
    const noMatchErrors = {'error_no_match', 'error_speech_timeout'};
    final noMatch = noMatchErrors.contains(error.errorMsg);

    if (noMatch) {
      if (!_sessionActive) return;
      final generation = _listenGeneration;
      if (_secondsLeft > 0) {
        unawaited(_beginListen(generation));
      } else {
        _finishSession();
      }
      return;
    }

    _stopCountdown();
    setState(() {
      _isListening = false;
      _recognitionError = 'Spróbuj ponownie.';
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = _listenSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        _finishSession();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _finishSession() {
    _stopCountdown();
    _listenGeneration++;
    unawaited(_speech.stop());
    if (!mounted) return;
    setState(() {
      _isListening = false;
      if (!_wordCorrect && _recognitionError == null) {
        _recognitionError = 'Spróbuj ponownie';
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _secondsLeft = 0;
    _sessionActive = false;
    _committedText = '';
  }

  void _selectWord(ReadingWord word) {
    Navigator.of(context).pop();
    final index = readingWords.indexOf(word);
    if (index < 0) return;

    _listenGeneration++;
    unawaited(_speech.stop());
    _stopCountdown();

    setState(() {
      _currentIndex = index;
      _activeSyllableIndex = null;
      _isListening = false;
      _wordCorrect = false;
      _recognitionError = null;
    });

    unawaited(_speakCurrentWord());
  }

  Widget _buildDrawer() {
    final sortedWords = [...readingWords]
      ..sort((a, b) => _normalize(a.word).compareTo(_normalize(b.word)));

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFEF6C00),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wybierz słowo',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: sortedWords.length,
                itemBuilder: (context, i) {
                  final word = sortedWords[i];
                  final selected = word == _currentWord;
                  return ListTile(
                    title: Text(
                      word.word,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    subtitle: Text(
                      word.syllables.join('-'),
                      style: TextStyle(color: Colors.brown.shade400),
                    ),
                    selected: selected,
                    selectedTileColor: const Color(
                      0xFFC8E6C9,
                    ).withValues(alpha: 0.6),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF1B5E20),
                          )
                        : null,
                    onTap: () => _selectWord(word),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalize(String value) {
    const from = 'ąćęłńóśźż';
    const to = 'acelnoszz';
    final buffer = StringBuffer();
    for (final char in value.toLowerCase().split('')) {
      final index = from.indexOf(char);
      if (index >= 0) {
        buffer.write(to[index]);
      } else {
        final code = char.codeUnitAt(0);
        if (code >= 97 && code <= 122) {
          buffer.write(char);
        }
      }
    }
    return buffer.toString();
  }

  String get _statusText {
    if (_wordCorrect) return 'Brawo! Przeczytałeś poprawnie!';
    if (_isListening) {
      return 'Słucham... powiedz: ${_currentWord.word} ($_secondsLeft s)';
    }
    if (_recognitionError != null) return _recognitionError!;
    if (_speechError) {
      return 'Nie udało się włączyć mowy. Sprawdź głos w ustawieniach telefonu.';
    }
    return 'Dotknij ekranu, aby zobaczyć kolejne słowo';
  }

  @override
  void dispose() {
    _speechGeneration++;
    _listenGeneration++;
    _countdownTimer?.cancel();
    _tts.stop();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showNextWord,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _wordCorrect ? _greenGradient : _pinkGradient,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  _Header(
                    isListening: _isListening,
                    onListen: _startListening,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
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
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      onPressed: _repeatWord,
                      icon: const Icon(Icons.volume_up_rounded),
                      iconSize: 40,
                      color: const Color(0xFFEF6C00),
                      tooltip: 'Powtórz słowo',
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(
                        minWidth: 72,
                        minHeight: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SyllableCard(
                    word: _currentWord,
                    activeSyllableIndex: _activeSyllableIndex,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _wordCorrect
                          ? const Color(0xFF1B5E20)
                          : Colors.brown.shade700,
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
  const _Header({
    required this.isListening,
    required this.onListen,
    required this.onMenu,
  });

  final bool isListening;
  final VoidCallback onListen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onMenu,
          icon: const Icon(Icons.menu_rounded),
          color: Colors.brown.shade800,
          tooltip: 'Wybierz słowo',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
        const Spacer(),
        Material(
          color: isListening
              ? const Color(0xFFC8E6C9)
              : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onListen,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    size: 24,
                    color: Colors.brown.shade600,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'czytamy razem',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ],
              ),
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
