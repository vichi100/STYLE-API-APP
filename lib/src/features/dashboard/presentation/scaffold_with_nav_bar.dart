import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glow_bottom_app_bar/glow_bottom_app_bar.dart';
import '../../../theme/theme_provider.dart';
import '../../wardrobe/presentation/upload_provider.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) { // Changed signature: removed WidgetRef ref
    // Watch Upload State
    final isUploading = ref.watch(isUploadingProvider);
    final currentMode = ref.watch(themeModeControllerProvider);
    
    // Sync current tab to provider (ensure initial state is correct)
    // We can use a microtask or rely on initial provider value.
    // Provider defaults to 0, if initial index is different we might desync briefly.
    // But usually apps start at 0.
    
    // Define distinct glow colors for each tab
    final glowColors = [
      Colors.white,                 // Kai
      Colors.amberAccent,           // Top Match
      Colors.deepOrangeAccent,      // Mismatch
      Colors.greenAccent,           // Wardrobe
    ];

    final currentGlowColor = glowColors[widget.navigationShell.currentIndex];

    // Sync provider with actual shell index (handles initial load & back navigation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currentTabProvider) != widget.navigationShell.currentIndex) {
        ref.read(currentTabProvider.notifier).state = widget.navigationShell.currentIndex;
      }
    });

    return Scaffold(
      body: Stack(
        children: [
           widget.navigationShell,
           
           // Global Upload Indicator (Only on non-Wardrobe screens)
           if (isUploading && widget.navigationShell.currentIndex != 3) // 3 is Wardrobe
             Positioned(
               left: 0,
               right: 0,
               bottom: 0, // Sit right on top of the nav bar (which is outside this body stack usually, but Scaffold puts body above nav bar)
               child: AnimatedBuilder(
                 animation: _animationController,
                 builder: (context, child) {
                   return Container(
                     height: 2, // Slimmer line
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: const [
                           Colors.blue,
                           Colors.red,
                           Colors.yellow,
                           Colors.green,
                           Colors.blue,
                         ],
                         // Simple scrolling gradient effect logic
                         transform: GradientRotation(_animationController.value * 6.28), 
                       ),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.blue.withOpacity(0.5),
                           blurRadius: 10,
                           spreadRadius: 1,
                         )
                       ]
                     ),
                   );
                 },
               ),
             ),
        ],
      ),
      bottomNavigationBar: GlowBottomAppBar(
        onChange: (index) => _onTap(context, index), // Changed: removed ref
        initialIndex: widget.navigationShell.currentIndex,
        glowColor: currentGlowColor.withOpacity(0.4),
        background: Colors.black, 
        selectedChildren: [
          _GlowingTab(
            glowColor: glowColors[0],
            child: SizedBox(width: 60, height: 44, child: Center(child: Icon(Icons.chat_bubble, color: glowColors[0], size: 28))),
          ),
          _GlowingTab(
            glowColor: glowColors[1],
            child: SizedBox(width: 60, height: 44, child: Center(child: Icon(Icons.star, color: glowColors[1], size: 28))),
          ),
          _GlowingTab(
            glowColor: glowColors[2],
            child: const SizedBox(width: 60, height: 44, child: Center(child: _MismatchSocksIcon(isSelected: true))),
          ),
          _GlowingTab(
            glowColor: glowColors[3],
            child: SizedBox(width: 60, height: 44, child: Center(child: Icon(Icons.checkroom, color: glowColors[3], size: 28))),
          ),
        ],
        // And a list for unselected state
        children: [
          Container(width: 60, height: 44, color: Colors.transparent, child: Icon(Icons.chat_bubble_outline, color: glowColors[0].withOpacity(0.5), size: 28)),
          Container(width: 60, height: 44, color: Colors.transparent, child: Icon(Icons.star_outline, color: glowColors[1].withOpacity(0.5), size: 28)),
          Container(width: 60, height: 44, color: Colors.transparent, child: Center(child: _MismatchSocksIcon(isSelected: false))),
          Container(width: 60, height: 44, color: Colors.transparent, child: Icon(Icons.checkroom_outlined, color: glowColors[3].withOpacity(0.5), size: 28)),
        ],
      ),
    );
  }
}
class _MismatchSocksIcon extends StatelessWidget {
  final bool isSelected;
  
  const _MismatchSocksIcon({this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final color1 = isSelected 
        ? Colors.deepOrangeAccent 
        : Colors.deepOrangeAccent.withOpacity(0.5);
        
    final color2 = isSelected
        ? Colors.purpleAccent
        : Colors.purpleAccent.withOpacity(0.5);

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sock 1 (The "Left" Sock from the pair, colored color2)
          Positioned(
            left: 0,
            bottom: 2,
            child: Transform.rotate(
              angle: -0.2, // Tilted left
              child: _SingleSock(color: color2, isLeftSock: true),
            ),
          ),
          // Sock 2 (The "Right" Sock from the pair, colored color1)
          Positioned(
            right: 0,
            top: 2,
            child: Transform.rotate(
              angle: 0.2, // Tilted right
              child: _SingleSock(color: color1, isLeftSock: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleSock extends StatelessWidget {
  final Color color;
  final bool isLeftSock;

  const _SingleSock({required this.color, required this.isLeftSock});

  @override
  Widget build(BuildContext context) {
    // The 'socks' icon contains two socks. We crop it to show only one.
    // We use a widthFactor > 0.5 to ensure we get the full sock shape
    // adjusting the alignment to pick the left or right one.
    return ClipRect(
      child: Align(
        alignment: isLeftSock ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: 0.6, // Capture slightly more than half to be safe, or adjust to 0.5
        child: FaIcon(
          FontAwesomeIcons.socks,
          size: 22, // Slightly larger base size
          color: color,
        ),
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
