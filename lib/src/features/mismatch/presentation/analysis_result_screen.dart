import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:style_advisor/src/common_widgets/doughnut_chart.dart';

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
}
