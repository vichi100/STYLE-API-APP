import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glow_bottom_app_bar/glow_bottom_app_bar.dart';
import '../../../theme/theme_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can watch theme here if we need specific dynamic styling for the navbar
    final currentMode = ref.watch(themeModeControllerProvider);
    final theme = Theme.of(context);

    // Define distinct glow colors for each tab
    final glowColors = [
      Colors.cyanAccent,            // Kai
      Colors.amberAccent,           // Top Match
      Colors.deepOrangeAccent,      // Mismatch
      Colors.greenAccent,           // Wardrobe
    ];

    // Current active glow color
    final currentGlowColor = glowColors[navigationShell.currentIndex];

    // Using GlowBottomAppBar as requested
    // Note: The package usually provides a specific widget structure.
    // Based on standard usage patterns for such packages.
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GlowBottomAppBar(
        onChange: (index) => _onTap(context, index),
        initialIndex: navigationShell.currentIndex,
        glowColor: currentGlowColor.withOpacity(0.4),
        background: theme.colorScheme.surfaceContainer, // Dark background for the bar itself
        iconSize: 28,
        // The package expects a list of widgets for selected state
        selectedChildren: [
          _GlowingTab(
            glowColor: glowColors[0],
            child: Icon(Icons.chat_bubble, color: glowColors[0]),
          ),
          _GlowingTab(
            glowColor: glowColors[1],
            child: Icon(Icons.star, color: glowColors[1]),
          ),
          _GlowingTab(
            glowColor: glowColors[2],
            child: const _MismatchSocksIcon(isSelected: true),
          ),
          _GlowingTab(
            glowColor: glowColors[3],
            child: Icon(Icons.checkroom, color: glowColors[3]),
          ),
        ],
        // And a list for unselected state
        children: [
          Icon(Icons.chat_bubble_outline, color: glowColors[0].withOpacity(0.5)),
          Icon(Icons.star_outline, color: glowColors[1].withOpacity(0.5)),
          const _MismatchSocksIcon(isSelected: false),
          Icon(Icons.checkroom_outlined, color: glowColors[3].withOpacity(0.5)),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _MismatchSocksIcon extends StatelessWidget {
  final bool isSelected;
  
  const _MismatchSocksIcon({this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    // Use hardcoded vibrant colors for the socks to ensure they look mismatched
    // regardless of the active theme (which might be monochromatic purple).
    final color1 = isSelected 
        ? Colors.deepOrangeAccent 
        : Colors.deepOrangeAccent.withOpacity(0.5);
        
    final color2 = isSelected
        ? Colors.purpleAccent
        : Colors.purpleAccent.withOpacity(0.5);

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sock 1 (Left, tilted, Secondary Color)
          Positioned(
            left: 0,
            top: 2,
            child: Transform.rotate(
              angle: -0.2,
              child: FaIcon(
                FontAwesomeIcons.socks,
                size: 18,
                color: color2, 
              ),
            ),
          ),
          // Sock 2 (Right, tilted, Primary Color)
          Positioned(
            right: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.2,
              child: FaIcon(
                FontAwesomeIcons.socks,
                size: 18,
                color: color1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingTab extends StatelessWidget {
  final Widget child;
  final Color glowColor;

  const _GlowingTab({required this.child, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
           BoxShadow(
            color: glowColor.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}
