import 'package:flutter/material.dart';

class StylizedCategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isWide;
  final bool hasGlow;
  final String? customIconPath;
  final String? imagePath;

  const StylizedCategoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isWide = false,
    this.hasGlow = false,
    this.imagePath,
    this.customIconPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isWide ? 160 : 100, 
        height: 65,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3), // Dark background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
             color: hasGlow ? color : color.withOpacity(0.5),
             width: hasGlow ? 2 : 1,
          ),
          boxShadow: hasGlow ? [
            BoxShadow(
              color: color.withOpacity(0.4), // Reduced from 0.6
              blurRadius: 12, // Reduced from 15
              spreadRadius: 1, // Reduced from 2
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19), 
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                ),
              if (imagePath != null)
                Container(color: Colors.black.withOpacity(0.4)), // Dim overlay for readability

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (customIconPath != null)
                    Image.asset(
                      customIconPath!,
                      width: 52, // Increased again from 44 to 52
                      height: 52,
                      // No tint, original colors
                    )
                  else if (imagePath == null)
                    Icon(icon, color: Colors.white, size: 24) // White icon request
                  else
                    Icon(icon, color: Colors.white, size: 24),
                  
                  // Label removed as per request
                  /*
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  */
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
