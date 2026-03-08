import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fallback URL will be used if .env is not present.
  }
  runApp(const BrainBounceApp());
}

class BrainBounceApp extends StatelessWidget {
  const BrainBounceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainBounce',
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

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  static String get baseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'https://funlearn-7w7z.onrender.com';
  final http.Client _client;

  Future<List<String>> fetchTopics() async {
    final Uri uri = Uri.parse('$baseUrl/topics');
    final http.Response response = await _client.get(uri).timeout(
      const Duration(seconds: 20),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GET $uri failed (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> rawTopics = jsonBody['topics'] as List<dynamic>;
    return rawTopics.map((topic) => topic.toString()).toList();
  }

  Future<QuestionResponse> fetchQuestion(String topic) async {
    final Uri uri = Uri.parse('$baseUrl/quiz/question')
        .replace(queryParameters: <String, String>{'topic': topic});

    final http.Response response = await _client.get(uri).timeout(
      const Duration(seconds: 20),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GET $uri failed (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    return QuestionResponse.fromJson(jsonBody);
  }

  Future<HintResponse> fetchHint({
    required int itemId,
    required int hintIndex,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/quiz/hint').replace(
      queryParameters: <String, String>{
        'item_id': itemId.toString(),
        'hint_index': hintIndex.toString(),
      },
    );

    final http.Response response = await _client.get(uri).timeout(
      const Duration(seconds: 20),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GET $uri failed (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    return HintResponse.fromJson(jsonBody);
  }

  Future<SubmitResponse> submitGuess({
    required int itemId,
    required String guess,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/quiz/submit');
    final http.Response response = await _client
        .post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'item_id': itemId, 'guess': guess}),
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'POST $uri failed (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    return SubmitResponse.fromJson(jsonBody);
  }

  Future<List<String>> searchAnswers({
    required String query,
    String? topic,
    int limit = 10,
  }) async {
    final Map<String, String> params = <String, String>{
      'query': query,
      'limit': '$limit',
    };
    if (topic != null && topic.isNotEmpty) {
      params['topic'] = topic;
    }

    final Uri uri = Uri.parse('$baseUrl/answers/search').replace(
      queryParameters: params,
    );
    final http.Response response = await _client.get(uri).timeout(
      const Duration(seconds: 20),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'GET $uri failed (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> options = jsonBody['options'] as List<dynamic>;
    return options.map((dynamic value) => value.toString()).toList();
  }
}

class QuestionResponse {
  const QuestionResponse({
    required this.itemId,
    required this.topic,
    required this.clueCount,
  });

  final int itemId;
  final String topic;
  final int clueCount;

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      itemId: json['item_id'] as int,
      topic: json['topic'] as String,
      clueCount: json['clue_count'] as int,
    );
  }
}

class HintResponse {
  const HintResponse({
    required this.hint,
    required this.hintIndex,
    required this.totalHints,
  });

  final String hint;
  final int hintIndex;
  final int totalHints;

  factory HintResponse.fromJson(Map<String, dynamic> json) {
    return HintResponse(
      hint: json['hint'] as String,
      hintIndex: json['hint_index'] as int,
      totalHints: json['total_hints'] as int,
    );
  }
}

class SubmitResponse {
  const SubmitResponse({
    required this.correct,
    required this.answer,
    required this.funFact,
  });

  final bool correct;
  final String answer;
  final String funFact;

  factory SubmitResponse.fromJson(Map<String, dynamic> json) {
    return SubmitResponse(
      correct: json['correct'] as bool,
      answer: json['answer'] as String,
      funFact: json['fun_fact'] as String? ?? '',
    );
  }
}

class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final ApiClient _apiClient = ApiClient();

  List<String> _topics = <String>[];
  String? _selectedTopic;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final List<String> topics = await _apiClient.fetchTopics();
      if (!mounted) {
        return;
      }
      setState(() {
        _topics = topics;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'API error on ${ApiClient.baseUrl}: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFE3FFF8), Color(0xFFF8FCFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'BrainBounce',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F3D3A),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your topic.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF375A57),
                      ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Color(0xFF8A2907)),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _topics.map((String topic) {
                                  final bool selected = _selectedTopic == topic;
                                  return ChoiceChip(
                                    label: Text(topic),
                                    selected: selected,
                                    selectedColor: colors.primaryContainer,
                                    side: BorderSide(
                                      color: selected
                                          ? colors.primary
                                          : colors.outline.withValues(alpha: 0.5),
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
                    onPressed: _selectedTopic == null || _isLoading || _error != null
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => QuizScreen(
                                  topic: _selectedTopic!,
                                  apiClient: _apiClient,
                                ),
                              ),
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _selectedTopic = null;
                            });
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
    required this.apiClient,
  });

  final String topic;
  final ApiClient apiClient;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _maxHints = 5;

  final TextEditingController _answerController = TextEditingController();
  Timer? _searchDebounce;

  int? _itemId;
  int _hintIndex = 0;
  int _totalHints = 0;
  bool _loading = true;
  String _feedback = 'Enter your guess first. Hints unlock when wrong.';
  List<String> _suggestions = <String>[];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _startRound() async {
    setState(() {
      _loading = true;
      _hintIndex = 0;
      _feedback = 'Enter your guess first. Hints unlock when wrong.';
      _answerController.clear();
      _suggestions = <String>[];
    });

    try {
      final QuestionResponse question =
          await widget.apiClient.fetchQuestion(widget.topic);
      if (!mounted) {
        return;
      }
      setState(() {
        _itemId = question.itemId;
        _totalHints = question.clueCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _feedback = 'Failed to load quiz question from API.';
      });
    }
  }

  Future<void> _submitGuess() async {
    final int? itemId = _itemId;
    if (_loading || itemId == null) {
      return;
    }

    final String guess = _answerController.text.trim();
    if (guess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type your guess before submitting.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _suggestions = <String>[];
    });

    try {
      final SubmitResponse response = await widget.apiClient.submitGuess(
        itemId: itemId,
        guess: guess,
      );

      if (!mounted) {
        return;
      }

      if (response.correct) {
        setState(() {
          _loading = false;
        });
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Correct!'),
              content: Text(
                response.funFact.isEmpty
                    ? 'Nice guess. Quiz will restart with a new challenge.'
                    : 'Nice guess.\n\nFun Fact: ${response.funFact}',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Restart Quiz'),
                ),
              ],
            );
          },
        );
        await _startRound();
        return;
      }

      final int nextHint = _hintIndex + 1;
      if (nextHint <= _maxHints && nextHint <= _totalHints) {
        final HintResponse hint = await widget.apiClient.fetchHint(
          itemId: itemId,
          hintIndex: nextHint,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _hintIndex = hint.hintIndex;
          _feedback = 'Wrong guess. Hint ${hint.hintIndex}/$_maxHints: ${hint.hint}';
          _loading = false;
          _answerController.clear();
        });
      } else {
        setState(() {
          _loading = false;
        });
      }

      if (_hintIndex >= _maxHints) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You used 5 hints. Answer was: ${response.answer}'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API request failed. Check backend server.')),
      );
    }
  }

  void _onGuessChanged(String value) {
    _searchDebounce?.cancel();

    final String query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = <String>[];
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final List<String> results = await widget.apiClient.searchAnswers(
          query: query,
          topic: widget.topic,
          limit: 8,
        );
        if (!mounted || _answerController.text.trim() != query) {
          return;
        }
        setState(() {
          _suggestions = results;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _suggestions = <String>[];
        });
      }
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
            colors: <Color>[Color(0xFFF8FCFF), Color(0xFFE8FFF5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _loading && _itemId == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Guess the hidden answer',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your answer is validated by API dataset.',
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
                          boxShadow: const <BoxShadow>[
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
                        enabled: !_loading,
                        decoration: InputDecoration(
                          labelText: 'Your guess',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: _onGuessChanged,
                        onSubmitted: (_) => _submitGuess(),
                      ),
                      if (_suggestions.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x26000000)),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = _suggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(option),
                                onTap: () {
                                  _answerController.text = option;
                                  _answerController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(offset: option.length),
                                  );
                                  setState(() {
                                    _suggestions = <String>[];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _loading ? null : _submitGuess,
                          child: Text(_loading ? 'Please wait...' : 'Submit Guess'),
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
