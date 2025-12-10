// lib/screens/formula_display_screen.dart
// UPDATED with the UI from AITrackerScreen

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- ADD THIS IMPORT
import 'package:provider/provider.dart';
import '../quiz_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoading = true;
  late final String _prefsKey;

  @override
  void initState() {
    super.initState();
    // Make the key unique for each chapter, e.g., "pinned_formulas_kinematics"
    _prefsKey = 'pinned_formulas_${widget.chapterName.toLowerCase().replaceAll(" ", "_")}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFormulas();
    });
  }

  Future<void> _loadFormulas() async {
    final quizProvider = Provider.of<QuizDataProvider>(context, listen: false);
    final chapterFile = widget.chapterName.toLowerCase().replaceAll(" ", "_");

    // Load the list of pinned IDs from local storage first
    final prefs = await SharedPreferences.getInstance();
    final pinnedIds = prefs.getStringList(_prefsKey) ?? [];

    if (quizProvider.allQuizData.containsKey(chapterFile)) {
      final List<dynamic> questions = quizProvider.allQuizData[chapterFile];
      setState(() {
        _allFormulas = questions.map((q) {
          final id = q['id']?.toString() ?? UniqueKey().toString();
          return Formula(
            id: id,
            data: q,
            // Set isPinned to true if the formula's ID is in our saved list
            isPinned: pinnedIds.contains(id),
          );
        }).toList();
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
    });

    final prefs = await SharedPreferences.getInstance();
    // Get the current list of all pinned formula IDs
    final List<String> pinnedIds = _allFormulas
        .where((f) => f.isPinned)
        .map((f) => f.id)
        .toList();

    // Save the updated list back to local storage
    await prefs.setStringList(_prefsKey, pinnedIds);
  }

  @override
  Widget build(BuildContext context) {
    final pinnedFormulas = _allFormulas.where((f) => f.isPinned).toList();
    final unpinnedFormulas = _allFormulas.where((f) => !f.isPinned).toList();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.chapterName, style:  TextStyle(fontSize:screenWidth*0.042, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allFormulas.isEmpty
          ? const Center(
        child: Text(
          'No formulas found for this chapter.',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _allFormulas.length,
        itemBuilder: (context, index) {
          final Formula formula = index < pinnedFormulas.length
              ? pinnedFormulas[index]
              : unpinnedFormulas[index - pinnedFormulas.length];

          return _buildFormulaCard(formula, index);
        },
      ),
    );
  }

  // --- THIS IS THE UPDATED WIDGET ---
  // In lib/screens/formula_display_screen.dart

// --- THIS IS THE CORRECTED WIDGET ---
// In lib/screens/formula_display_screen.dart

// --- THIS IS THE FINAL CORRECTED WIDGET ---
  Widget _buildFormulaCard(Formula formula, int index) {
    final questionData = formula.data;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
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
              // --- Question Image (if available) ---
              if (questionData['image'] != null && questionData['image'].toString().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                  child: Center(
                    // --- START: APPLIED THE SIZING FROM SOLO SCREEN ---
                    child: SizedBox(
                      width: screenWidth * 0.6,
                      height: (screenWidth * 0.6) / 1.5, // Calculated height
                      child: Image.asset(
                        questionData['image'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          'Image not found',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    // --- END: APPLIED THE SIZING ---
                  ),
                ),

              // --- Question Text ---
              // FINAL CORRECTION: Use the 'question' key, which is the original source key.
              Html(
                data: '${index + 1}. ${questionData['question'] ?? 'N/A'}',
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

              // --- Answer ---
              // In lib/screens/formula_display_screen.dart, inside _buildFormulaCard...

              // --- Answer ---
              Padding(
                // Use EdgeInsets.only to specify padding for each side
                padding: EdgeInsets.only(
                  top: screenWidth * 0.02,
                  bottom: screenWidth * 0.02,
                  left: screenWidth * 0.05, // Added left padding
                ),
                child: Math.tex(
                  // Removed the manual spaces from here
                  '${questionData['answer'] ?? 'N/A'}',
                  textStyle: TextStyle(fontSize: screenWidth * 0.048, color: const Color(
                      0xCCA5FB8F)),
                ),
              ),

              // --- Tip ---
              if (questionData['tip'] != null && questionData['tip'].toString().isNotEmpty) ...[
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
          ),),
          // --- Pin Icon Button ---
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: Icon(
                formula.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: formula.isPinned ? Colors.cyan.shade600 : Colors.grey,
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