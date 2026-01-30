import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:style_advisor/src/common_widgets/doughnut_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class AnalysisResultScreen extends StatelessWidget {
  final String? topImage;
  final String? bottomImage;
  final String? layerImage;
  final String? singlesImage; // For when we support singles later
  final String result;
  
  // Scores (0-100)
  final double totalScore;
  final double vibeScore;
  final double colorScore;
  
  final Map<String, dynamic>? suggestions;
  final String? inspirationUrl;

  const AnalysisResultScreen({
    super.key,
    this.topImage,
    this.bottomImage,
    this.layerImage,
    this.singlesImage,
    required this.result,
    this.totalScore = 85.0,
    this.vibeScore = 80.0,
    this.colorScore = 90.0,
    this.suggestions,
    this.inspirationUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Style Analysis', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [


            // Outfit Visuals (Horizontal Scroll matching MismatchScreen)
            SizedBox(
              height: 200, 
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                    if (singlesImage != null)
                      _buildImageCard(singlesImage!, context)
                    else ...[
                       if (topImage != null) 
                          _buildImageCard(topImage!, context),
                       if (layerImage != null)
                          _buildImageCard(layerImage!, context),
                       if (bottomImage != null)
                          _buildImageCard(bottomImage!, context),
                    ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Score Section with Doughnut Chart
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildScoreRow(),
            ),

            
            // Result Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.cyanAccent),
                      const SizedBox(width: 10),
                      Text(
                        "AI Verdict",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            if (suggestions != null && suggestions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSuggestions(context),
            ],

            if (inspirationUrl != null && inspirationUrl!.isNotEmpty) ...[
               const SizedBox(height: 24),
               _buildInspirationButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String url, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2.3; // Match MismatchScreen
    
    return Container(
      width: cardWidth,
      height: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
         color: const Color(0xFF1E1E1E),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildScoreRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
           _buildSingleChart(totalScore, "Slay Score", Colors.cyanAccent),
           _buildSingleChart(vibeScore, "Vibe Check", Colors.pinkAccent),
           _buildSingleChart(colorScore, "Color Match", Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildSingleChart(double score, String label, Color color) {
    return DoughnutChart(
      percentage: score / 100,
      score: score,
      size: 80, // Reduced size
      primaryColor: color,
      label: label,
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style, color: Colors.amberAccent),
              const SizedBox(width: 10),
              Text(
                "Style Up",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (suggestions != null)
          ...suggestions!.entries.map((entry) {
             IconData icon;
             String title = entry.key.replaceAll('_', ' ').capitalize();
             switch (entry.key) {
               case 'footwear': icon = Icons.do_not_step; break;
               case 'bag': icon = Icons.shopping_bag; break;
               case 'outerwear': icon = Icons.checkroom; break;
               case 'accessories': icon = Icons.watch; break;
               case 'makeup_hair': icon = Icons.face; break;
               default: icon = Icons.star;
             }
             
             return Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Icon(icon, color: Colors.white54, size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           title,
                           style: const TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.bold,
                             fontSize: 14,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           entry.value.toString(),
                           style: const TextStyle(
                             color: Colors.white70,
                             fontSize: 14,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
             );
          }).toList(),
        ],
      ),
    );
  }
 


  Widget _buildInspirationButton(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage("assets/icons/inspiration_bg.png"),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchPinterest,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    "See Inspiration", 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.grey.withOpacity(0.9), // Very light gray shadow
                          offset: Offset(0, 2),
                        ),
                      ],
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchPinterest() async {
      if (inspirationUrl == null) return;
      final uri = Uri.parse(inspirationUrl!);
      try {
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
             debugPrint("Could not launch $inspirationUrl");
          }
      } catch (e) {
          debugPrint("Error launching URL: $e");
      }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
