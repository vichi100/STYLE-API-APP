import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnalysisResultScreen extends StatelessWidget {
  final String? topImage;
  final String? bottomImage;
  final String? layerImage;
  final String? singlesImage; // For when we support singles later
  final String result;

  const AnalysisResultScreen({
    super.key,
    this.topImage,
    this.bottomImage,
    this.layerImage,
    this.singlesImage,
    required this.result,
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
            // Outfit Visuals
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    if (singlesImage != null)
                      Expanded(child: _buildImage(singlesImage!))
                    else ...[
                      // Top Half (Layer + Top)
                      Expanded(
                        child: Column(
                          children: [
                            if (topImage != null) 
                              Expanded(child: _buildImage(topImage!)),
                            if (layerImage != null)
                              Expanded(child: _buildImage(layerImage!)),
                          ],
                        ),
                      ),
                      // Bottom Half
                       if (bottomImage != null)
                        Expanded(child: _buildImage(bottomImage!)),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
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

  Widget _buildImage(String url) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(12),
         image: DecorationImage(
            image: CachedNetworkImageProvider(url),
            fit: BoxFit.cover,
         ),
      ),
    );
  }
}
