// lib/screens/formula_display_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../quiz_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Data model remains the same
class Formula {
  final String id;
  final Map<String, dynamic> data;
  bool isPinned;

  Formula({required this.id, required this.data, this.isPinned = false});
}

class FormulaDisplayScreen extends StatefulWidget {
  final String chapterName;

  const FormulaDisplayScreen({super.key, required this.chapterName});

  @override
  State<FormulaDisplayScreen> createState() => _FormulaDisplayScreenState();
}

class _FormulaDisplayScreenState extends State<FormulaDisplayScreen> {
  List<Formula> _allFormulas = [];
  List<Formula> _sortedFormulas = [];
  bool _isLoading = true;
  late final String _prefsKey;

  @override
  void initState() {
    super.initState();
    _prefsKey =
    'pinned_formulas_${widget.chapterName.toLowerCase().replaceAll(" ", "_")}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFormulas();
    });
  }

  void _sortFormulas() {
    final pinned = _allFormulas.where((f) => f.isPinned).toList();
    final unpinned = _allFormulas.where((f) => !f.isPinned).toList();
    _sortedFormulas = [...pinned, ...unpinned];
  }

  Future<void> _loadFormulas() async {
    final quizProvider =
    Provider.of<QuizDataProvider>(context, listen: false);
    final chapterFile =
    widget.chapterName.toLowerCase().replaceAll(" ", "_");
    final prefs = await SharedPreferences.getInstance();
    final pinnedIds = prefs.getStringList(_prefsKey) ?? [];

    if (quizProvider.allQuizData.containsKey(chapterFile)) {
      final List<dynamic> questions = quizProvider.allQuizData[chapterFile];

      _allFormulas = questions.map((q) {
        final id = q['id']?.toString() ?? UniqueKey().toString();
        return Formula(
          id: id,
          data: q,
          isPinned: pinnedIds.contains(id),
        );
      }).toList();

      setState(() {
        _sortFormulas();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePin(Formula formula) async {
    setState(() {
      formula.isPinned = !formula.isPinned;
      _sortFormulas();
    });

    final prefs = await SharedPreferences.getInstance();
    final List<String> pinnedIds =
    _allFormulas.where((f) => f.isPinned).map((f) => f.id).toList();
    await prefs.setStringList(_prefsKey, pinnedIds);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.chapterName,
          style: TextStyle(
            fontSize: screenWidth * 0.042,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sortedFormulas.isEmpty
          ? const Center(
        child: Text(
          'No formulas found for this chapter.',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _sortedFormulas.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final formula = _sortedFormulas[index];
          return _buildFormulaCard(
            formula,
            index,
            key: ValueKey(formula.id),
          );
        },
      ),
    );
  }

  Widget _buildFormulaCard(
      Formula formula,
      int index, {
        Key? key,
      }) {
    final questionData = formula.data;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.cyan.shade900,
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (questionData['image'] != null &&
                    questionData['image'].toString().isNotEmpty)
                  // Padding(
                  //   padding:
                  //   EdgeInsets.only(bottom: screenWidth * 0.02),
                  //   child: Center(
                  //     child: SizedBox(
                  //       width: screenWidth * 0.6,
                  //       height: (screenWidth * 0.6) / 1.5,
                  //       child: Opacity(
                  //         opacity: 0.85, // Value between 0.0 (transparent) and 1.0 (opaque)
                  //         child: SvgPicture.asset(
                  //           questionData['image'],
                  //           fit: BoxFit.contain,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  Padding(
                    padding:
                    EdgeInsets.only(bottom: screenWidth * 0.02),
                    child: Center(
                      child: SizedBox(
                        width: screenWidth * 0.6,
                        height: (screenWidth * 0.6) / 1.5,
                        child: Image.asset( // <-- Changed from SvgPicture.asset
                          questionData['image'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                Html(
                  data:
                  '${index + 1}. ${questionData['question'] ?? 'N/A'}',
                  style: {
                    "body": Style(
                      fontSize: FontSize(screenWidth * 0.037),
                      color: const Color(0xE6DCDCDC),
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      margin: Margins.zero,
                    ),
                  },
                ),
                SizedBox(height: screenWidth * 0.016),
                Center( // Wrap with a Center widget
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: screenWidth * 0.02,
                      bottom: screenWidth * 0.02,
                      // The left padding is no longer needed if you want true centering
                      // left: screenWidth * 0.05,
                    ),
                    child: Math.tex(
                      '${questionData['answer'] ?? 'N/A'}',
                      textStyle: TextStyle(
                        fontSize: screenWidth * 0.048,
                        color: const Color(0xCCA5FB8F),
                      ),
                    ),
                  ),
                ),
                if (questionData['tip'] != null &&
                    questionData['tip'].toString().isNotEmpty) ...[
                  SizedBox(height: screenWidth * 0.05),
                  Text(
                    'Tip:',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFF8A46F),
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    questionData['tip'].toString(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFF8A46F),
                      fontSize: screenWidth * 0.039,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: Icon(
                formula.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                color: formula.isPinned
                    ? Colors.cyan.shade600
                    : Colors.grey,
                size: 20,
              ),
              onPressed: () => _togglePin(formula),
            ),
          ),
        ],
      ),
    );
  }
}
