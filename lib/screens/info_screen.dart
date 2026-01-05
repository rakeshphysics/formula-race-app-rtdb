import 'package:flutter/gestures.dart'; // Needed for clickable text
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Needed to open the link

class InfoScreen extends StatelessWidget {
  final String title;

  const InfoScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  // Function to get content for non-clickable pages (like How to Play)
  String _getContentForTitle(String title) {
    switch (title) {
      case 'How to Play':
        return """
1. Play Solo 👤
• Challenge yourself with 10 questions that get harder as you go.
• Track Progress: Watch chapter colors change from Red (Needs work) to Green (Mastered).

2. Play with Friend ⚔️
• Battle Mode: Challenge a friend to a physics duel.
• Real-time: See who scores higher and answers faster.

3. Revise Formulas 📜
• Quick Access: Find all important formulas in one place.
• Pin Favorites: Tap the pin icon 📌 to move difficult formulas to the top.

4. My Mistakes ❌
• Learn: Every wrong answer is saved automatically.
• Review: Re-attempt these questions to fix your weak spots.

5. Panda AI 🐼
• Smart Advice: Tap the Panda for motivation and tips.
• Analysis: Get post-game feedback on your strong and weak chapters.

6. Profile & Stats 📊
• Earn Bamboos for every correct answer.
• Check your overall accuracy to see where you stand.
""";
      default:
        return 'No information available.';
    }
  }

  // Helper to launch the URL
  Future<void> _launchYoutube() async {
    final Uri url = Uri.parse('https://www.youtube.com/@physicswithrakesh');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'rakeshmanusani@gmail.com',
      query: 'subject=Feedback for Formula Racing App', // Optional: Pre-fill subject
    );

    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseStyle = GoogleFonts.poppins(
      color: const Color(0xA6FFFFFF),
      fontSize: screenWidth * 0.04,
      height: 1.5,
    );

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
          child: title == 'About Me'
              ? _buildAboutMeContent(baseStyle) // <--- Special clickable content
              : Text(
            _getContentForTitle(title), // <--- Standard text content
            style: baseStyle,
          ),
        ),
      ),
    );
  }

  // Special widget just for "About Me" to handle the link
  // Special widget just for "About Me" to handle the link
  Widget _buildAboutMeContent(TextStyle baseStyle) {
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(
            text: "Hello dear students! 👋\n\n"
                "I am Rakesh, a Physics teacher with over 10 years of experience guiding students for JEE Advanced.\n\n"
                "I built this app to make formula revision and quick practice fun and accessible.\n\n"
                "It is designed to help you keep important formulas at your fingertips and test your recall speed anytime, anywhere.\n\n"
                "You can also learn more on my YouTube channel:\n",
          ),
          TextSpan(
            text: "https://www.youtube.com/@physicswithrakesh\n\n",
            style: baseStyle.copyWith(
              color: const Color(0xCC8AFFFF),
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.normal,
            ),
            recognizer: TapGestureRecognizer()..onTap = _launchYoutube,
          ),
          const TextSpan(
            text: "You can contact me at:\n",
          ),
          TextSpan(
            text: "rakeshmanusani@gmail.com\n\n",
            style: baseStyle.copyWith(
              color: const Color(0xCC8AFFFF),
              decoration: TextDecoration.underline, // Added underline to indicate clickability
              fontWeight: FontWeight.normal,
            ),
            // ✅ ADDED: Tap recognizer for email
            recognizer: TapGestureRecognizer()..onTap = _launchEmail,
          ),
          const TextSpan(
            text: "Hope you enjoy using it ! Love you all ! ❤️",
          ),
        ],
      ),
    );
  }
}
