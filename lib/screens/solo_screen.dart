// lib/screens/solo_screen.dart
// ----------------------------------------------------
// Solo Play screen of the Formula Race App.
// 10-segment progress bar (WhatsApp style)
// Each segment → 7s → auto move if no click
// Sounds + polished buttons → unchanged
// Best practice: totalQuestions constant → easy to change
// ----------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../models/incorrect_answer_model.dart';
import '../../screens/result_screen.dart';
import '../../widgets/formula_option_button.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../services/mistake_tracker_service.dart'; // ADD THIS IMPORT
import '../widgets/glow_button_cyan.dart';
import '../widgets/glow_button_answer.dart';
// ............. Chunk 1 SOLO SCREEN WIDGET .............
const Map<String, String> chapterToClass = {
  "Units and Dimensions": "11",
  "Kinematics": "11",
  "Laws of Motion": "11",
  "Work Power Energy": "11",
  "Center of Mass": "11",
  "Rotation": "11",
  "Gravitation": "11",
  "Mechanical Properties of Solids": "11",
  "Mechanical Properties of Fluids": "11",
  "Thermodynamics": "11",
  "Kinetic Theory": "11",
  "Oscillations": "11",
  "Waves": "11",
  "Electrostatics": "12",
  "Current Electricity": "12",
  "Magnetism": "12",
  "Electromagnetic Induction": "12",
  "Alternating Current": "12",
  "Electromagnetic Waves": "12",
  "Ray Optics": "12",
  "Wave Optics": "12",
  "Dual Nature of Matter": "12",
  "Atoms": "12",
  "Nuclei": "12",
  "Semiconductors": "12",
};

class SoloScreen extends StatefulWidget {
  final String mode; // 'chapter', 'full11', 'full12', 'fullBoth', 'mistake'
  final String? chapter;

  const SoloScreen({Key? key, required this.mode, this.chapter}) : super(key: key);

  

  @override
  State<SoloScreen> createState() => _SoloScreenState();
}

class _SoloScreenState extends State<SoloScreen> with SingleTickerProviderStateMixin {

  // ............. Chunk 2 STATE VARIABLES .............
  final int totalQuestions = 10;  // ← change this to set number of questions and progress bars
  int get totalBars => widget.mode == 'mistake' ? 5 : totalQuestions;
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int score = 0;
  int resolvedCount = 0;
  bool answered = false;

  List<String> shuffledOptions = [];
  String? selectedOption;
  bool showResult = false;
  List<IncorrectAnswer> wrongAnswers = [];
  final AudioPlayer audioPlayer = AudioPlayer();

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;


  Future<List<Map<String, dynamic>>> loadFormulasFromAssets(List<String> paths) async {
    List<Map<String, dynamic>> all = [];
    for (String path in paths) {
      String content = await rootBundle.loadString(path);
      List<dynamic> data = jsonDecode(content);
      all.addAll(data.cast<Map<String, dynamic>>());
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> loadMistakeFormulas() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/mistake_tracker.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadUsedFormulas(String mode) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/used_formulas_$mode.json');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUsedFormulas(String mode, List<Map<String, dynamic>> used) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/used_formulas_$mode.json');
    await file.writeAsString(jsonEncode(used));
  }

  Future<void> loadQuestions() async {
    List<Map<String, dynamic>> formulas = [];

    if (widget.mode == 'mistake') {
      formulas = await loadMistakeFormulas();
      formulas.shuffle();

      if (formulas.length >= 5) {
        formulas = formulas.take(5).toList();
      } else if (formulas.isEmpty) {
        // Optional: handle no mistakes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No mistakes to clear.")),
        );
        Navigator.pop(context); // Go back to My Mistakes screen
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Only ${formulas.length} mistakes available.")),
        );
        // You may still use them
      }
    }
    else {

    List<String> paths = [];
    if (widget.mode == 'chapter' && widget.chapter != null) {
    final chapterClass = chapterToClass[widget.chapter] ?? '11';
    final chapterFile = widget.chapter!.toLowerCase().replaceAll(" ", "_");
    paths = ['assets/formulas/$chapterClass/$chapterFile.json'];
    } else if (widget.mode == 'full11') {
    paths = [
    'assets/formulas/11/units_and_dimensions.json',
    'assets/formulas/11/kinematics.json',
    'assets/formulas/11/laws_of_motion.json',
    'assets/formulas/11/work_power_energy.json',
    'assets/formulas/11/center_of_mass.json',
    'assets/formulas/11/rotational_motion.json',
    'assets/formulas/11/gravitation.json',
    'assets/formulas/11/mechanical_properties_of_solids.json',
    'assets/formulas/11/mechanical_properties_of_fluids.json',
    'assets/formulas/11/thermodynamics.json',
    'assets/formulas/11/kinetic_theory.json',
    'assets/formulas/11/oscillations.json',
    'assets/formulas/11/waves.json',
    ];
    } else if (widget.mode == 'full12') {
    paths = [
    'assets/formulas/12/electrostatics.json',
    'assets/formulas/12/current_electricity.json',
    'assets/formulas/12/magnetism.json',
    'assets/formulas/12/electromagnetic_induction.json',
    'assets/formulas/12/alternating_current.json',
    'assets/formulas/12/electromagnetic_waves.json',
    'assets/formulas/12/ray_optics.json',
    'assets/formulas/12/wave_optics.json',
    'assets/formulas/12/dual_nature_of_matter.json',
    'assets/formulas/12/atoms.json',
    'assets/formulas/12/nuclei.json',
    'assets/formulas/12/semiconductors.json',
    ];
    } else if (widget.mode == 'fullBoth') {
    paths = [
    // Class 11
    'assets/formulas/11/units_and_dimensions.json',
    'assets/formulas/11/kinematics.json',
    'assets/formulas/11/laws_of_motion.json',
    'assets/formulas/11/work_power_energy.json',
    'assets/formulas/11/center_of_mass.json',
    'assets/formulas/11/rotational_motion.json',
    'assets/formulas/11/gravitation.json',
    'assets/formulas/11/mechanical_properties_of_solids.json',
    'assets/formulas/11/mechanical_properties_of_fluids.json',
    'assets/formulas/11/thermodynamics.json',
    'assets/formulas/11/kinetic_theory.json',
    'assets/formulas/11/oscillations.json',
    'assets/formulas/11/waves.json',

    // Class 12
    'assets/formulas/12/electrostatics.json',
    'assets/formulas/12/current_electricity.json',
    'assets/formulas/12/magnetism.json',
    'assets/formulas/12/electromagnetic_induction.json',
    'assets/formulas/12/alternating_current.json',
    'assets/formulas/12/electromagnetic_waves.json',
    'assets/formulas/12/ray_optics.json',
    'assets/formulas/12/wave_optics.json',
    'assets/formulas/12/dual_nature_of_matter.json',
    'assets/formulas/12/atoms.json',
    'assets/formulas/12/nuclei.json',
    'assets/formulas/12/semiconductors.json',
    ];
    }


    final allFormulas = await loadFormulasFromAssets(paths);
      final used = await loadUsedFormulas(widget.mode);

      final usedQuestions = used.map((e) => e['question']).toSet();
      final remaining = allFormulas.where((f) => !usedQuestions.contains(f['question'])).toList();

      if (remaining.length < 10) {
        formulas = allFormulas..shuffle();
        await saveUsedFormulas(widget.mode, []);
      } else {
        remaining.shuffle();
        formulas = remaining.take(10).toList();
        final updatedUsed = [...used, ...formulas];
        await saveUsedFormulas(widget.mode, updatedUsed);
      }
    }

    setState(() {
      questions = formulas;
      currentIndex = 0;
      selectedOption = null;
    });
  }


  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7), // 7s per segment
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);


    loadQuestions();
    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && selectedOption == null && !answered) {
        // Auto move to next if user didn't click
        checkAnswer('');
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // ............. Chunk 3 LOAD QUESTIONS .............


  // ............. Chunk 4 CHECK ANSWER .............
  Future<void> checkAnswer(String selected) async {
    if (answered) return;
    answered = true;

    if (currentIndex >= questions.length) return;
    final question = questions[currentIndex];
    final String correctAnswer = question['answer'];
    //print('DEBUG → MistakeTracker: question="${question['question']}", formula="${question['answer']}", chapter="${question['tags']?['chapter'] ?? ''}"');

    if (selected == correctAnswer) {
      if (widget.mode == 'mistake') {

        // Remove this question from mistakes
        await IncorrectAnswerManager.removeIncorrectQuestion(question);

        resolvedCount++;
      } else {
        score++;
        // TRACK CORRECT
        MistakeTrackerService.trackCorrect(
          userId: 'test_user', // use real userId when ready
          questionData: questions[currentIndex],
        );
      }
    } else if (selected != '') {
      // User clicked wrong answer
      wrongAnswers.add(
        IncorrectAnswer(
          question: question['question'],
          userAnswer: selected,
          correctAnswer: correctAnswer,
        ),
      );

      // TRACK MISTAKE
      MistakeTrackerService.trackMistake(
        userId: 'test_user',
        questionData: questions[currentIndex],
      );
    } else {
      // User skipped → count as wrong
      wrongAnswers.add(
        IncorrectAnswer(
          question: question['question'],
          userAnswer: '(No Answer)',
          correctAnswer: correctAnswer,
        ),
      );

      // TRACK MISTAKE
      await MistakeTrackerService.trackMistake(
        userId: 'test_user',
        questionData: questions[currentIndex],
      );
    }

    if (currentIndex < totalBars - 1) {
      answered = false;
      setState(() {
        currentIndex++;
        selectedOption = null;
        shuffledOptions = [];
      });

      // Restart progress bar for next question
      _progressController.reset();
      _progressController.forward();
    } else {
      if (widget.mode == 'mistake') {
        if (!mounted) return;

        Navigator.of(context).pop(resolvedCount); // return value to My Mistakes screen


        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(
                incorrectAnswers: wrongAnswers,
                mode: widget.mode,
                responses: questions,
              ),
          settings: RouteSettings(arguments: totalQuestions),
        ),
      );
    }
  }
  // ............. Chunk 5 OPTION COLOR LOGIC .............
  Color getOptionColor(String option) {
    if (selectedOption == null) {
      return Colors.grey.shade800;
    } else {
      if (option == questions[currentIndex]['answer']) {
        return Colors.green;
      } else if (option == selectedOption) {
        return Colors.red;
      } else {
        return Colors.grey.shade800;
      }
    }
  }

  // ............. Chunk 6 PROGRESS BAR BUILDER .............
  Widget buildProgressBar() {
    return Row(
      children: List.generate(totalBars, (index) {
        double value;
        if (index < currentIndex) {
          value = 1;
        } else if (index == currentIndex) {
          value = _progressAnimation.value;
        } else {
          value = 0;
        }
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade800,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
        );
      }),
    );
  }

  // ............. Chunk 7 BUILD WIDGET TREE .............
  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    if (currentIndex >= questions.length) {
      return const Scaffold(body: Center(child: SizedBox()));
    }
    final question = questions[currentIndex];
    final List<dynamic> options = question['options'];
    if (shuffledOptions.isEmpty) {
      shuffledOptions = List<String>.from(options);
      shuffledOptions.shuffle();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.mode == 'mistake' ? 'Clear My Mistakes' : 'Solo Play',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return buildProgressBar();
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${currentIndex + 1} of $totalBars',

              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            // Keep the question text as normal Text() for proper rendering
            Text(
              question['question'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 24),
            ...shuffledOptions.expand((option) {
              Color glow = Colors.cyan;
              if (selectedOption != null) {
                if (option == questions[currentIndex]['answer']) {
                  glow = Colors.green;
                } else if (option == selectedOption) {
                  glow = Colors.red;
                }
              }

                return [
                  GlowButtonAnswer(
                    label: option,
                    onPressed: selectedOption == null
                        ? () {
                      setState(() {
                        selectedOption = option;
                      });
                      answered = true;
                      if (option == questions[currentIndex]['answer']) {
                        audioPlayer.play(AssetSource('sounds/correct.mp3'));
                      } else {
                        audioPlayer.play(AssetSource('sounds/wrong.mp3'));
                      }
                      Future.delayed(const Duration(milliseconds: 700), () {
                        checkAnswer(option);
                      });
                    }
                        : () {},
                    glowColor: glow,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ];
          }).toList(),
                      ],
                    ),
                  ),
                );
  }
}
