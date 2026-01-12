// clear_mistakes_screen.dart
// ------------------------------------------------------
// Solo mode but simplified — only for clearing mistakes
// Loads 5 questions from local mistake tracker JSON
// Tracks resolvedCount and returns it to AITrackerScreen
// ------------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../services/mistake_tracker_service.dart';
import '../../models/incorrect_answer_model.dart';
import '../../widgets/glow_button_red.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:formularacing/widgets/rive_viewer.dart';



class ClearMistakesScreen extends StatefulWidget {
  final String? subject;
  final String? chapterName;
  const ClearMistakesScreen({super.key,required this.subject, this.chapterName});

  @override
  State<ClearMistakesScreen> createState() => _ClearMistakesScreenState();
}

class _ClearMistakesScreenState extends State<ClearMistakesScreen> with SingleTickerProviderStateMixin {
  //final int totalQuestions = 5;

  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int resolvedCount = 0;
  List<String> shuffledOptions = [];
  String? selectedOption;
  List<IncorrectAnswer> wrongAnswers = [];
  final AudioPlayer audioPlayer = AudioPlayer();

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    MistakeTrackerService.printAllMistakes();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);



    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && selectedOption == null) {
        checkAnswer('');
      }
    });
    _progressController.addListener(() {
      setState(() {}); // ✅ this is what was missing
    });
    loadMistakes();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> loadMistakes() async {
    List<Map<String, dynamic>> all = await MistakeTrackerService.loadMistakesFromLocal();
    //print('Loaded ${all.length} mistakes');
    if (widget.subject != null) {
      all = all.where((m) {
        // Get subject from tags, or root, or default to 'Physics'
        String s = (m['tags']?['subject'] ?? m['subject'] ?? 'Physics').toString();
        return s == widget.subject;
      }).toList();
    }
    all.shuffle();
    setState(() {
      questions = all.take(10).toList();
      currentIndex = 0;       // add this
      selectedOption = null;  // add this
      shuffledOptions = [];   // add this
        });

        _progressController.reset();
        _progressController.forward();

  }

  Future<void> checkAnswer(String selected) async {
    final question = questions[currentIndex];
    final correct = question['answer'];

    if (selected == correct) {
      resolvedCount++;
      await MistakeTrackerService.removeMistake(question['question']);
      //await MistakeTrackerService.trackCorrect(
       // userId: 'test_user',
        //questionData: question,
      //);
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
        shuffledOptions = [];
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.pop(context, resolvedCount);
    }
  }

  Color getOptionColor(String option) {
    if (selectedOption == null) return Colors.grey[900]!;
    if (option == questions[currentIndex]['answer']) return const Color(0xCC4CAF50);
    if (option == selectedOption) return const Color(0x99F44336);
    return Colors.grey[900]!;
  }

  // Add this new function
  Color getBorderColor(String option) {
    if (selectedOption == null) {
      // Default border color
      return Colors.grey.shade700;
    }
    if (option == questions[currentIndex]['answer']) {
      // Correct answer border color
      return Colors.greenAccent;
    }
    if (option == selectedOption) {
      // Selected incorrect answer border color
      return Colors.redAccent;
    }
    // Border color for other non-selected options
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
   // final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;


    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentIndex];
    final List<String> mathChapters = ['Definite Integrals', 'Indefinite Integrals'];
// Extract chapter from the tags map of the current question
    final String currentChapter = (question['tags']?['chapter'] ?? '').toString();
    final bool useMathTex = mathChapters.contains(currentChapter.trim());


    final List<dynamic> options = question['options'];
    if (shuffledOptions.isEmpty) {
      shuffledOptions = List<String>.from(options);
      shuffledOptions.shuffle();
    }

    return PopScope( // Added PopScope
        canPop: false, // Prevent default pop behavior
        onPopInvoked: (didPop) async {
      if (didPop) {
        return;
      }
      _progressController.stop(); // Pause timer

      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Color(0xFFFF6F61), width: 1.2), // Red/light red border
          ),
          backgroundColor: Color(0xFF000000), // Semi-transparent black
          title: Text(
            'Exit Clear Mistakes ?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xD9FFFFFF), fontSize: screenWidth*0.042), // Red title
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black, // Black background
                foregroundColor: Colors.white, // White text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Color(0xFFFF6F61), width: 1.2), // Red/light red border
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child:  Text(
                'Cancel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: screenWidth*0.04,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black, // Black background
                foregroundColor: Colors.white, // White text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Color(0xD9FF6F61), width: 1.2), // Red/light red border
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Exit',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xD9FFFFFF),fontSize: screenWidth*0.04, fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      );

      if (shouldExit ?? false) {
        // If the user confirms exit, pop the screen with resolvedCount
        Navigator.pop(context, resolvedCount);
      } else {
        _progressController.forward(); // Resume timer if user cancels
      }
    },

    child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:  Text('Clear Mistakes', style: TextStyle(color: Color(0xD9FFFFFF), fontSize: screenWidth*0.043)),
        //iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(

              children: List.generate(questions.length, (index) {
                double value;
                if (index < currentIndex) value = 1;
                else if (index == currentIndex) value = _progressAnimation.value;
                else value = 0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey.shade800,
                      color: Color(0xFFFF6F61),
                      minHeight: 6,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              'Q${currentIndex + 1} of ${questions.length}',
              style: TextStyle(color: Color(0xD9FFFFFF), fontSize: screenWidth*0.044),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.005),

            // Html(
            //   data: question['question'],
            //   style: {
            //     "body": Style(
            //       fontSize: FontSize(screenWidth * 0.04),
            //       fontWeight: FontWeight.normal,
            //       color: Color(0xD9FFFFFF),
            //       fontFamily: GoogleFonts.poppins().fontFamily,
            //     ),
            //   },
            // ),

            // --- Question Block (Conditional) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: useMathTex
                  ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Math.tex(
                  question['question'] ?? '',
                  textStyle: TextStyle(
                    fontSize: screenWidth * 0.048,
                    color: const Color(0xD9FFFFFF),
                  ),
                ),
              )
                  : Html(
                data: question['question'],
                style: {
                  "body": Style(
                    fontSize: FontSize(screenWidth * 0.04),
                    fontWeight: FontWeight.normal,
                    color: const Color(0xD9FFFFFF),
                    fontFamily: GoogleFonts.poppins().fontFamily,
                    //margin: Margins.zero,
                  ),
                },
              ),
            ),

            // if (question['image'] != null && question['image'].toString().isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 0),
            //     child:Center(
            //     child: SizedBox(
            //     width: screenWidth * 0.6,
            //     height: (screenWidth * 0.6) / 1.5,
            //       child: Image.asset(
            //       question['image'],
            //       fit: BoxFit.contain,
            //       errorBuilder: (context, error, stackTrace) {
            //         return const Text(
            //           'Image not found',
            //           style: TextStyle(color: Colors.redAccent),
            //         );
            //       },
            //     ),),),
            //   )


            // if (question['image'] != null && question['image'].toString().isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 0),
            //     child: Center(
            //       child: SizedBox(
            //         width: screenWidth * 0.6,
            //         height: (screenWidth * 0.6) / 1.5, // Maintain the same aspect ratio
            //         child: SvgPicture.asset(
            //           question['image'], // This path now points to a .svg file
            //           fit: BoxFit.contain,
            //         ),
            //       ),
            //     ),
            //   )
            // lib/screens/clear_mistakes_screen.dart

// ... (previous code remains the same)

            // if (question['image'] != null && question['image'].toString().isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 0),
            //     child: Center(
            //       child: SizedBox(
            //         width: screenWidth * 0.6,
            //         height: (screenWidth * 0.6) / 1.5,
            //         child: question['image'].endsWith('.svg')
            //             ? SvgPicture.asset(
            //           question['image'],
            //           fit: BoxFit.contain,
            //           placeholderBuilder: (context) => const SizedBox.shrink(),
            //         )
            //             : Image.asset(
            //           question['image'],
            //           fit: BoxFit.contain,
            //           errorBuilder: (context, error, stackTrace) {
            //             return const Text(
            //               'Image not found',
            //               style: TextStyle(color: Colors.redAccent),
            //             );
            //           },
            //         ),
            //       ),
            //     ),
            //   )

            if (question['image'] != null && question['image'] != "")
              Container(
                key: ValueKey(currentIndex),
                margin: const EdgeInsets.symmetric(vertical: 0),
                child: Center(
                  child: SizedBox(
                    // WIDTH LOGIC
                    width: question['image'].endsWith('.glb')
                        ? screenWidth * 0.65 // 3D models often need more width
                        : question['image'].endsWith('.riv')
                        ? screenWidth * 0.65
                        : screenWidth * 0.62,

                    // HEIGHT LOGIC
                    height: question['image'].endsWith('.glb')
                        ? screenWidth * 0.65 // Square aspect for 3D usually works best
                        : question['image'].endsWith('.riv')
                        ? (screenWidth * 0.65) / 1.5
                        : (screenWidth * 0.62) / 1.5,

                    child: question['image'].endsWith('.svg')
                        ? Opacity(
                      opacity: 0.85,
                      child: SvgPicture.asset(
                        question['image'],
                        fit: BoxFit.contain,
                      ),
                    )
                        : question['image'].endsWith('.glb')
                        ? ModelViewer(
                      key: ValueKey(question['image']),
                      src: question['image'],
                      backgroundColor: Colors.transparent,
                      alt: "A 3D model",
                      ar: false,
                      autoRotate: true,
                      disableZoom: false,
                      disablePan: true,
                      cameraControls: true,
                      interactionPrompt: InteractionPrompt.none,
                      shadowIntensity: 0,
                      autoPlay: true,
                    )
                        : question['image'].endsWith('.riv')
                        ? Opacity(
                      opacity: 0.8,
                      // Ensure you have this widget defined or use RiveAnimation.asset
                      child: FormulaRiveViewer(
                        key: ValueKey(question['image']),
                        src: question['image'],
                      ),
                    )
                        : Image.asset(
                      question['image'],
                      fit: BoxFit.contain,
                      key: ValueKey('img_$currentIndex'),
                    ),
                  ),
                ),
              )
            else
            // If no image, use SizedBox.shrink() to take no space
              const SizedBox.shrink(),

// ... (rest of the code remains the same)



            SizedBox(height: MediaQuery.of(context).size.height * 0.005),


    Expanded(
    /// adjust as needed
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
    child: Column(
    children: shuffledOptions.map((option) {
    return GestureDetector(
    onTap: selectedOption == null ? () {
    setState(() {
    selectedOption = option;
    });
    if (option == question['answer']) {
    audioPlayer.play(AssetSource('sounds/correct.mp3'));
    } else {
    audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    }
    Future.delayed(const Duration(milliseconds: 1500), () {
    checkAnswer(option);
    });
    } : null,
    child: Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(12),
    width: double.infinity,
    height: 64,
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(4),
    color: getOptionColor(option),
    border: Border.all(
    color: getBorderColor(option), // Warm coral
    width: 1,
    ),
    ),
    child: Center(
      child:SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
    child: Math.tex(
    option,
    textStyle:  TextStyle(color: Color(0xD9FFFFFF), fontSize: screenWidth * 0.045),
    ),
      ),
    ),
    ),
    );
    }).toList(),
    ),
    ),
    ),




          ],
        ),
      ),
      )
    ),
    );
  }
}
