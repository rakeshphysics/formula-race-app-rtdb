// lib/screens/formula_display_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../quiz_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:formularacing/widgets/rive_viewer.dart';

// Data model remains the same
class Formula {
  final String id;
  final Map<String, dynamic> data;
  bool isPinned;
  bool isBookmarked;

  Formula({required this.id, required this.data, this.isPinned = false, this.isBookmarked = false});
}

class FormulaDisplayScreen extends StatefulWidget {
  final String chapterName;
  final String subject;

  const FormulaDisplayScreen({super.key, required this.chapterName, required this.subject});

  @override
  State<FormulaDisplayScreen> createState() => _FormulaDisplayScreenState();
}

class _FormulaDisplayScreenState extends State<FormulaDisplayScreen> {
  List<Formula> _allFormulas = [];
  List<Formula> _sortedFormulas = [];
  bool _isLoading = true;
  late final String _prefsPinKey; // Rename this from _prefsKey
  late final String _prefsBookmarkKey;
  final Set<int> _active3DIndices = {};
  final int _maxActive3DModels = 6;

  @override
  void initState() {
    super.initState();
    // Generate unique keys for pin and bookmark states per chapter
    final chapterKey = widget.chapterName.toLowerCase().replaceAll(" ", "_");
    _prefsPinKey = 'pinned_formulas_$chapterKey';
    _prefsBookmarkKey = 'bookmarked_formulas_$chapterKey'; // Add this line

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFormulas();
    });

  }




  void _activate3DModel(int index) {
    setState(() {
      if (_active3DIndices.contains(index)) return;
_active3DIndices.add(index);
      if (_active3DIndices.length > _maxActive3DModels) {
        _active3DIndices.remove(_active3DIndices.first);
      }
    });
  }

// Helper to manually close a model
  void _deactivate3DModel(int index) {
    setState(() {
      _active3DIndices.remove(index);
    });
  }

  void _initializeActiveModels() {
    _active3DIndices.clear();
    int count = 0;

    // Loop through the sorted formulas to find the first few GLB files
    for (int i = 0; i < _sortedFormulas.length; i++) {
      final image = _sortedFormulas[i].data['image'];

      if (image != null && image.toString().endsWith('.glb')) {
        _active3DIndices.add(i);
        count++;

        // Stop once we reach our limit (6)
        if (count >= _maxActive3DModels) break;
      }
    }
  }

  void _sortFormulas() {
    final pinned = _allFormulas.where((f) => f.isPinned).toList();
    final unpinned = _allFormulas.where((f) => !f.isPinned).toList();
    _sortedFormulas = [...pinned, ...unpinned];
  }

  // In _FormulaDisplayScreenState class

  Future<void> _loadFormulas() async {
    final quizProvider =
    Provider.of<QuizDataProvider>(context, listen: false);
    final chapterFile =
    widget.chapterName.toLowerCase().replaceAll(" ", "_");
    final prefs = await SharedPreferences.getInstance();
    final pinnedIds = prefs.getStringList(_prefsPinKey) ?? [];
    final bookmarkedIds = prefs.getStringList(_prefsBookmarkKey) ?? []; // Add this line

    if (quizProvider.allQuizData.containsKey(chapterFile)) {
      final List<dynamic> questions = quizProvider.allQuizData[chapterFile];

      _allFormulas = questions.map((q) {
        final id = q['id']?.toString() ?? UniqueKey().toString();
        return Formula(
          id: id,
          data: q,
          isPinned: pinnedIds.contains(id),
          isBookmarked: bookmarkedIds.contains(id), // Add this line
        );
      }).toList();

      setState(() {
        _sortFormulas();
        _isLoading = false;
        _initializeActiveModels();
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
    await prefs.setStringList(_prefsPinKey, pinnedIds);
  }


  Future<void> _toggleBookmark(Formula formula) async {
    setState(() {
      formula.isBookmarked = !formula.isBookmarked;
      // No sorting is needed, just a state update
    });

    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarkedIds = _allFormulas
        .where((f) => f.isBookmarked)
        .map((f) => f.id)
        .toList();
    await prefs.setStringList(_prefsBookmarkKey, bookmarkedIds);
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '${widget.chapterName} Formulas',
          style: TextStyle(
            fontSize: screenWidth * 0.042,
            color: Color(0xD9FFFFFF)
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
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
        cacheExtent: MediaQuery.of(context).size.height * 2,
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

  // Widget _buildFormulaCard(
  //     Formula formula,
  //     int index, {
  //       Key? key,
  //     }) {
  //   final questionData = formula.data;
  //   final screenWidth = MediaQuery.of(context).size.width;
  //
  //   return Container(
  //     key: key,
  //     width: double.infinity,
  //     margin: const EdgeInsets.symmetric(vertical: 8),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.black,
  //       borderRadius: BorderRadius.circular(4),
  //       border: Border.all(
  //         color: Colors.cyan.shade900,
  //         width: 1.5,
  //       ),
  //     ),
  //     child: Stack(
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.only(right: 25.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               if (questionData['image'] != null &&
  //                   questionData['image'].toString().isNotEmpty)
  //                 // Padding(
  //                 //   padding:
  //                 //   EdgeInsets.only(bottom: screenWidth * 0.02),
  //                 //   child: Center(
  //                 //     child: SizedBox(
  //                 //       width: screenWidth * 0.6,
  //                 //       height: (screenWidth * 0.6) / 1.5,
  //                 //       child: Opacity(
  //                 //         opacity: 0.85, // Value between 0.0 (transparent) and 1.0 (opaque)
  //                 //         child: SvgPicture.asset(
  //                 //           questionData['image'],
  //                 //           fit: BoxFit.contain,
  //                 //         ),
  //                 //       ),
  //                 //     ),
  //                 //   ),
  //                 // ),
  //
  //                 // Padding(
  //                 //   padding:
  //                 //   EdgeInsets.only(bottom: screenWidth * 0.02),
  //                 //   child: Center(
  //                 //     child: SizedBox(
  //                 //       width: screenWidth * 0.6,
  //                 //       height: (screenWidth * 0.6) / 1.5,
  //                 //       child: Image.asset( // <-- Changed from SvgPicture.asset
  //                 //         questionData['image'],
  //                 //         fit: BoxFit.contain,
  //                 //       ),
  //                 //     ),
  //                 //   ),
  //                 // ),
  //
  //                 // Padding(
  //                 //   padding:
  //                 //   EdgeInsets.only(bottom: screenWidth * 0.02),
  //                 //   child: Center(
  //                 //     child: SizedBox(
  //                 //       width: screenWidth * 0.6,
  //                 //       height: (screenWidth * 0.6) / 1.5,
  //                 //       child: questionData['image'].endsWith('.svg')
  //                 //           ? Opacity(
  //                 //         opacity: 0.85, // Apply 85% opacity
  //                 //         child: SvgPicture.asset(
  //                 //           questionData['image'],
  //                 //           fit: BoxFit.contain,
  //                 //         ),
  //                 //       )
  //                 //           : Image.asset(
  //                 //         questionData['image'],
  //                 //         fit: BoxFit.contain,
  //                 //       ),
  //                 //     ),
  //                 //   ),
  //                 // ),
  //
  //
  //                 Padding(
  //                   padding: EdgeInsets.only(bottom: screenWidth * 0.02),
  //                   child: Center(
  //                     child: SizedBox(
  //                       width: screenWidth * 0.6,
  //                       height: (screenWidth * 0.6) / 1.5,
  //                       child: questionData['image'].endsWith('.svg')
  //                           ? Opacity(
  //                         opacity: 0.85,
  //                         child: SvgPicture.asset(
  //                           questionData['image'],
  //                           fit: BoxFit.contain,
  //                         ),
  //                       )
  //                           : questionData['image'].endsWith('.glb')
  //                           ? ModelViewer(
  //                         src: questionData['image'],
  //                         backgroundColor: Colors.transparent,
  //                         alt: "A 3D model",
  //                         ar: false, // Disable AR for list view stability
  //                         autoRotate: true,
  //                         disableZoom: false,
  //                         disablePan: true,// Prevents scroll conflicts
  //                         cameraControls: true,
  //                         interactionPrompt: InteractionPrompt.none,
  //                       )
  //                           : Image.asset(
  //                         questionData['image'],
  //                         fit: BoxFit.contain,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //
  //               Html(
  //                 data:
  //                 '${index + 1}. ${questionData['question'] ?? 'N/A'}',
  //                 style: {
  //                   "body": Style(
  //                     fontSize: FontSize(screenWidth * 0.037),
  //                     color: const Color(0xE6DCDCDC),
  //                     fontFamily: GoogleFonts.poppins().fontFamily,
  //                     margin: Margins.zero,
  //                   ),
  //                 },
  //               ),
  //               SizedBox(height: screenWidth * 0.016),
  //               Center( // Wrap with a Center widget
  //                 child: Padding(
  //                   padding: EdgeInsets.only(
  //                     top: screenWidth * 0.02,
  //                     bottom: screenWidth * 0.02,
  //                     // The left padding is no longer needed if you want true centering
  //                     // left: screenWidth * 0.05,
  //                   ),
  //                   child: Math.tex(
  //                     '${questionData['answer'] ?? 'N/A'}',
  //                     textStyle: TextStyle(
  //                       fontSize: screenWidth * 0.048,
  //                       color: const Color(0xCCA5FB8F),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               if (questionData['tip'] != null &&
  //                   questionData['tip'].toString().isNotEmpty) ...[
  //                 SizedBox(height: screenWidth * 0.05),
  //                 Text(
  //                   'Tip:',
  //                   style: GoogleFonts.poppins(
  //                     color: const Color(0xFFF8A46F),
  //                     fontSize: screenWidth * 0.045,
  //                     fontWeight: FontWeight.w600,
  //                     fontStyle: FontStyle.italic,
  //                   ),
  //                 ),
  //                 SizedBox(height: screenWidth * 0.01),
  //                 Text(
  //                   questionData['tip'].toString(),
  //                   style: GoogleFonts.poppins(
  //                     color: const Color(0xFFF8A46F),
  //                     fontSize: screenWidth * 0.039,
  //                     fontStyle: FontStyle.italic,
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //         Positioned(
  //           top: -8,
  //           right: -8,
  //           child: IconButton(
  //             icon: Icon(
  //               formula.isPinned
  //                   ? Icons.push_pin
  //                   : Icons.push_pin_outlined,
  //               color: formula.isPinned
  //                   ? Colors.cyan.shade600
  //                   : Colors.grey,
  //               size: 20,
  //             ),
  //             onPressed: () => _togglePin(formula),
  //           ),
  //         ),
  //
  //         Positioned(
  //           top: 28, // Position it below the pin icon
  //           right: -8,
  //           child: IconButton(
  //             icon: Icon(
  //               formula.isBookmarked
  //                   ? Icons.bookmark // Filled icon when bookmarked
  //                   : Icons.bookmark_border, // Outline icon when not
  //               color: formula.isBookmarked
  //                   ? Colors.amber.shade700 // Highlight color
  //                   : Colors.grey,
  //               size: 20,
  //             ),
  //             onPressed: () => _toggleBookmark(formula),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Color _getSubjectColor() {
    // Check if widget.subject is null just in case, though usually it isn't
    final subject = widget.subject ?? 'Physics';

  //   if (subject.contains('Chem')) {
  //     return Colors.green.shade700.withOpacity(0.7);
  //   } else if (subject.contains('Math')) {
  //     return Colors.blue.shade700.withOpacity(0.7);
  //   }
  //   // Default to Physics (Cyan)
  //   return Colors.cyan.shade700.withOpacity(0.7);
  // }

  if (subject.contains('Chem')) {
  return  Colors.green.shade700.withOpacity(0.6);
  } else if (subject.contains('Math')) {
    return Colors.blue.shade700.withOpacity(0.6);
  }
  // Default to Physics (Cyan)
    return Colors.cyan.shade700.withOpacity(0.6);
}

  // Widget _buildMediaTypeBadge(String? imagePath, Color themeColor) {
  //   if (imagePath == null || imagePath.isEmpty) return const SizedBox.shrink();
  //
  //   IconData icon;
  //   String label;
  //
  //
  //   if (imagePath.endsWith('.glb')) {
  //     // 3D Model Badge
  //     icon = Icons.threed_rotation;
  //     label = "";
  //    // color = Colors.grey.shade400;
  //   } else if (imagePath.endsWith('.riv')) {
  //     // Rive Animation Badge
  //     icon = Icons.touch_app;
  //     label = "";
  //     //color = Colors.grey.shade400;
  //   } else {
  //     // For SVG, PNG, JPG, etc., do NOT show a badge.
  //     return const SizedBox.shrink();
  //   }
  //
  //   return Container(
  //       padding: const EdgeInsets.all(4),
  //       decoration: BoxDecoration(
  //         color: Colors.black.withOpacity(0.7),
  //         borderRadius: BorderRadius.circular(50),
  //         // Use the themeColor for the border
  //         border: Border.all(color: Colors.grey.shade400, width: 1),
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(icon, color: Colors.grey[400], size: 16),
  //
  //           if (label.isNotEmpty) ...[
  //             const SizedBox(width: 4),
  //             Text(
  //               label,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.bold,
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //           ],
  //         ],
  //       ),
  //     );
  //
  // }



  Widget _buildFormulaCard(
      Formula formula,
      int index, {
        Key? key,
      }) {
    final questionData = formula.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final themeColor = _getSubjectColor();

    final List<String> mathChapters = ['Definite Integrals', 'Indefinite Integrals','Sequence and Series'];
    final List<String> mathSubjects = ['Maths', 'Physics'];

// 2. Check the condition (using trim() for safety)
    final bool useMathTex = mathSubjects.contains(widget.subject?.trim()) &&
        mathChapters.contains(widget.chapterName?.trim());

    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: themeColor,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --- A. IMAGE SECTION (Cleaned up: No Icons, Black Background kept) ---
          if (questionData['image'] != null &&
              questionData['image'].toString().isNotEmpty)
            Container(
              // FIX: Black background prevents "White Box" glitch
              color: Colors.black,
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LEFT SPACE (Black Container)
                  Expanded(child: Container(color: Colors.black)),

                  // 2. CENTER IMAGE (Black Container)
                  Container(
                    color: Colors.black,
                    width: questionData['image'].endsWith('.glb')
                        ? screenWidth * 0.6
                        : questionData['image'].endsWith('.riv')
                        ? screenWidth * 0.65
                        : screenWidth * 0.62,
                    height: questionData['image'].endsWith('.glb')
                        ? screenWidth * 0.6
                        : questionData['image'].endsWith('.riv')
                        ? (screenWidth * 0.65) / 1.5
                        : (screenWidth * 0.62) / 1.5,
                    child: questionData['image'].endsWith('.svg')
                        ? Opacity(
                      opacity: 0.85,
                      child: SvgPicture.asset(
                        questionData['image'],
                        fit: BoxFit.contain,
                      ),
                    )
                        : questionData['image'].endsWith('.glb')
                        ? Formula3DViewer(
                      src: questionData['image'],
                      themeColor: themeColor,
                      index: index,
                      isActive: _active3DIndices.contains(index),
                      onActivate: () => _activate3DModel(index),
                      onDeactivate: () => _deactivate3DModel(index),
                    )
                        : questionData['image'].endsWith('.riv')
                        ? Opacity(
                      opacity: 0.8,
                      child: FormulaRiveViewer(
                        src: questionData['image'],
                      ),
                    )
                        : Image.asset(
                      questionData['image'],
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 3. RIGHT SPACE (Empty now, but kept black for symmetry/safety)
                  Expanded(child: Container(color: Colors.black)),
                ],
              ),
            ),

          // --- B. TEXT CONTENT ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Question Text
                // Container(
                //   width: double.infinity,
                //   child: Html(
                //     data: '${index + 1}. ${questionData['question'] ?? 'N/A'}',
                //     style: {
                //       "body": Style(
                //         fontSize: FontSize(screenWidth * 0.037),
                //         color: const Color(0xE6DCDCDC),
                //         fontFamily: GoogleFonts.poppins().fontFamily,
                //         margin: Margins.zero,
                //         display: Display.block,
                //       ),
                //     },
                //   ),
                // ),

                // 1. Question Text
                Container(
                  width: double.infinity,
                  child: useMathTex
                      ? Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Math.tex(
                        '\\text{${index + 1}. } ${questionData['question'] ?? "N/A"}',
                        textStyle: TextStyle(
                          fontSize: screenWidth * 0.048,
                          color: const Color(0xE6DCDCDC),
                          //fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                    ),
                  )
                      : Html(
                    data: '${index + 1}. ${questionData['question'] ?? 'N/A'}',
                    style: {
                      "body": Style(
                        fontSize: FontSize(screenWidth * 0.037),
                        color: const Color(0xE6DCDCDC),
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        margin: Margins.zero,
                        display: Display.block,
                      ),
                    },
                  ),
                ),




                SizedBox(height: screenWidth * 0.01),

                // 2. ANSWER ROW (Pin - Answer - Bookmark)
                // 2. ANSWER ROW (Pin - Answer - Bookmark)
                // 2. ANSWER ROW (Answer Centered - Icons Grouped Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. LEFT SPACER (To balance the icons on the right, keeping answer centered)
                    // We use a SizedBox with the same width as the icons to force true centering
                    const SizedBox(width: 50),

                    // 2. CENTER: Answer (Takes up all remaining space)
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Math.tex(
                            '${questionData['answer'] ?? 'N/A'}',
                            textStyle: TextStyle(
                              fontSize: screenWidth * 0.048,
                              color: const Color(0xCCA5FB8F),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. RIGHT: Icons Grouped Together
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pin Icon
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.only(left:8), // Small padding between icons
                          icon: Icon(
                            formula.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            color: formula.isPinned ? themeColor.withOpacity(1.0) : Colors.grey[700],
                            size: 18,
                          ),
                          onPressed: () => _togglePin(formula),
                        ),

                        // Bookmark Icon
                        // IconButton(
                        //   constraints: const BoxConstraints(),
                        //   padding: const EdgeInsets.only(left: 4), // Small padding
                        //   icon: Icon(
                        //     formula.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        //     color: formula.isBookmarked ? Colors.amber.shade700 : Colors.grey,
                        //     size: 18,
                        //   ),
                        //   onPressed: () => _toggleBookmark(formula),
                        // ),
                      ],
                    ),
                  ],
                ),

                // 3. Tip
                if (questionData['tip'] != null &&
                    questionData['tip'].toString().isNotEmpty) ...[
                  SizedBox(height: screenWidth * 0.02),
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
        ],
      ),
    );
  }



}
class Formula3DViewer extends StatefulWidget {
  final String src;
  final int index;
  final Color themeColor;
  final bool isActive;            // Received from parent
  final VoidCallback onActivate;  // Callback to parent
  final VoidCallback onDeactivate;// Callback to parent

  const Formula3DViewer({
    Key? key,
    required this.src,
    required this.index,
    required this.themeColor,
    required this.isActive,       // Required
    required this.onActivate,     // Required
    required this.onDeactivate,   // Required
  }) : super(key: key);

  @override
  State<Formula3DViewer> createState() => _Formula3DViewerState();
}
class _Formula3DViewerState extends State<Formula3DViewer> with AutomaticKeepAliveClientMixin {
  // Keep alive if active so it doesn't reload when scrolling slightly off-screen
  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // STATE 1: ACTIVE 3D MODEL
    if (widget.isActive) {
      // We removed the Stack and the Close button.
      // Now it just returns the 3D viewer directly.
      return ModelViewer(
        key: ValueKey("${widget.src}_active"),
        src: widget.src,
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
      );
    }

    // STATE 2: PLACEHOLDER
    return GestureDetector(
      onTap: widget.onActivate, // Call parent to open
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.threed_rotation_outlined,
              color: widget.themeColor,
              size: 48,
            ),
            const SizedBox(height: 8), // Spacing
            Text(
              "Tap to view",
              style: TextStyle(
                color: widget.themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}