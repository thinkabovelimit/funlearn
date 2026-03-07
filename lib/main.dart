import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const TopicGuesserApp());
}

class TopicGuesserApp extends StatelessWidget {
  const TopicGuesserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topic Guesser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF157A6E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TopicSelectionScreen(),
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.answer,
    required this.hints,
  });

  final String answer;
  final List<String> hints;
}

class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final Map<String, List<QuizQuestion>> _questionBank =
      <String, List<QuizQuestion>>{
    'Science': const [
      QuizQuestion(
        answer: 'carbon dioxide',
        hints: <String>[
          'Plants use it during photosynthesis.',
          'It is a gas humans exhale.',
          'It has one carbon and two oxygen atoms.',
          'Its chemical formula is CO2.',
          'It is a major greenhouse gas.',
        ],
      ),
      QuizQuestion(
        answer: 'water',
        hints: <String>[
          'It is essential for life.',
          'It covers most of Earth.',
          'It is colorless and tasteless.',
          'Its formula is H2O.',
          'It boils at 100 C.',
        ],
      ),
      QuizQuestion(
        answer: 'gravity',
        hints: <String>[
          'It pulls objects toward Earth.',
          'It keeps planets in orbit.',
          'Newton studied it with an apple story.',
          'It is a fundamental force.',
          'Without it, we would float away.',
        ],
      ),
    ],
    'History': const [
      QuizQuestion(
        answer: 'george washington',
        hints: <String>[
          'He is on the one-dollar bill.',
          'He was a Founding Father.',
          'He led during the American Revolutionary War.',
          'He became the first U.S. President.',
          'His first name is George.',
        ],
      ),
      QuizQuestion(
        answer: '1945',
        hints: <String>[
          'World War II ended in the mid-1940s.',
          'It was the same year the UN was founded.',
          'It came right after 1944.',
          'It is before 1946.',
          'The year is 1945.',
        ],
      ),
      QuizQuestion(
        answer: 'china',
        hints: <String>[
          'The Great Wall is there.',
          'Its capital is Beijing.',
          'It is the world’s most populous country historically.',
          'It is in East Asia.',
          'The answer is China.',
        ],
      ),
    ],
    'Technology': const [
      QuizQuestion(
        answer: 'central processing unit',
        hints: <String>[
          'It is the brain of a computer.',
          'It executes instructions.',
          'It is often called a processor.',
          'Its abbreviation is CPU.',
          'It expands to Central Processing Unit.',
        ],
      ),
      QuizQuestion(
        answer: 'google',
        hints: <String>[
          'It is a major tech company.',
          'It owns YouTube.',
          'It develops Android.',
          'Its search engine is very popular.',
          'The answer is Google.',
        ],
      ),
      QuizQuestion(
        answer: 'dart',
        hints: <String>[
          'Flutter apps use this language.',
          'It was developed by Google.',
          'It is not Java or Kotlin.',
          'It has sound null safety.',
          'The answer is Dart.',
        ],
      ),
    ],
    'Sports': const [
      QuizQuestion(
        answer: '11',
        hints: <String>[
          'This is for one soccer team on the field.',
          'It is more than 10.',
          'It is less than 12.',
          'Goalkeeper included.',
          'The number is 11.',
        ],
      ),
      QuizQuestion(
        answer: 'love',
        hints: <String>[
          'This is tennis scoring term.',
          'It means zero points.',
          'It is a single word.',
          'It is also an emotion.',
          'The answer is love.',
        ],
      ),
      QuizQuestion(
        answer: 'badminton',
        hints: <String>[
          'It uses a shuttlecock.',
          'Played with a racket.',
          'Popular in indoor courts.',
          'It is not tennis.',
          'The answer is badminton.',
        ],
      ),
    ],
    'Movies': const [
      QuizQuestion(
        answer: 'director',
        hints: <String>[
          'This person leads the creative vision.',
          'Actors follow this person’s instructions.',
          'They guide scenes and shots.',
          'Not the producer.',
          'The answer is director.',
        ],
      ),
      QuizQuestion(
        answer: 'oscar',
        hints: <String>[
          'A major Hollywood award.',
          'Given by the Academy.',
          'It is a gold statue.',
          'Often called Academy Award.',
          'The answer is Oscar.',
        ],
      ),
      QuizQuestion(
        answer: 'trailer',
        hints: <String>[
          'It promotes an upcoming movie.',
          'Usually 1 to 3 minutes.',
          'Shown before film release.',
          'It is a preview video.',
          'The answer is trailer.',
        ],
      ),
    ],
  };

  String? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<String> topics = _questionBank.keys.toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3FFF8), Color(0xFFF8FCFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topic Guesser',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F3D3A),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select one topic and guess first. Wrong guesses unlock up to 5 hints.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF375A57),
                      ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: topics.map((topic) {
                        final bool selected = _selectedTopic == topic;
                        return ChoiceChip(
                          label: Text(topic),
                          selected: selected,
                          selectedColor: colors.primaryContainer,
                          side: BorderSide(
                            color: selected
                                ? colors.primary
                                : colors.outline.withOpacity(0.5),
                          ),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? colors.onPrimaryContainer
                                : const Color(0xFF254441),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedTopic = topic;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _selectedTopic == null
                        ? null
                        : () {
                            final String topic = _selectedTopic!;
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => QuizScreen(
                                  topic: topic,
                                  questions: _questionBank[topic] ?? const <QuizQuestion>[],
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text(
                      'Start Guessing',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.topic,
    required this.questions,
  });

  final String topic;
  final List<QuizQuestion> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _maxHints = 5;
  final TextEditingController _answerController = TextEditingController();
  final Random _random = Random();

  int _hintIndex = 0;
  String _feedback = 'Enter your guess first. Hints unlock when wrong.';
  late QuizQuestion _activeQuestion;

  @override
  void initState() {
    super.initState();
    _activeQuestion = widget.questions[_random.nextInt(widget.questions.length)];
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return text.toLowerCase().trim();
  }

  void _submitAnswer() {
    final String guess = _answerController.text.trim();
    if (guess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type your guess before submitting.')),
      );
      return;
    }

    final bool isCorrect = _normalize(guess) == _normalize(_activeQuestion.answer);

    if (isCorrect) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Correct!'),
          content: const Text('Nice guess. Quiz will restart with a new challenge.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _restartQuiz();
              },
              child: const Text('Restart Quiz'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      if (_hintIndex < _maxHints) {
        final String hint = _activeQuestion.hints[_hintIndex];
        _hintIndex++;
        _feedback = 'Wrong guess. Hint $_hintIndex/$_maxHints: $hint';
      }
    });

    if (_hintIndex >= _maxHints) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You used all 5 hints. Answer was: ${_activeQuestion.answer}',
            ),
          ),
        );
        Navigator.pop(context);
      });
    }

    _answerController.clear();
  }

  void _restartQuiz() {
    setState(() {
      _hintIndex = 0;
      _feedback = 'Enter your guess first. Hints unlock when wrong.';
      _activeQuestion = widget.questions[_random.nextInt(widget.questions.length)];
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topic} Reverse Quiz'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FCFF), Color(0xFFE8FFF5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guess the hidden answer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You get up to 5 hints after wrong guesses.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _hintIndex / _maxHints,
                  borderRadius: BorderRadius.circular(20),
                  minHeight: 10,
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    _feedback,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Your guess',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitAnswer(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _submitAnswer,
                    child: const Text('Submit Guess'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
