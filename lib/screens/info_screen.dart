import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends StatelessWidget {
  final String title;

  // Notice 'content' is removed from here
  const InfoScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  // --- NEW: Function to get content based on title ---
  String _getContentForTitle(String title) {
    switch (title) {
      case 'How to Play':
        return 'This is where you will write the rules of the game. Explain how to challenge a friend, how the quiz works, and how to win.';
      case 'About':
        return 'This app was created by [Your Name].\n\nIt is a multiplayer quiz game designed for Formula Racing fans to test their knowledge against friends.';
      default:
        return 'No information available.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Get the correct content string using our new function
    final String content = _getContentForTitle(title);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFFA8A8A8),
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFA8A8A8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            content, // This now uses the content variable defined above
            style: GoogleFonts.poppins(
              color: Color(0xD9FFFFFF),
              fontSize: screenWidth * 0.04,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}