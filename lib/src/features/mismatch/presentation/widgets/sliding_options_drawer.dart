import 'package:flutter/material.dart';

class DrawerOptionItem {
  final String label;
  final Color color;
  final VoidCallback onTap;

  DrawerOptionItem({
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class SlidingOptionsDrawer extends StatefulWidget {
  final Widget child;
  final List<DrawerOptionItem> options; 
  final bool isSmall;

  const SlidingOptionsDrawer({
    super.key,
    required this.child,
    required this.options,
    this.isSmall = false,
  });

  @override
  State<SlidingOptionsDrawer> createState() => _SlidingOptionsDrawerState();
}

class _SlidingOptionsDrawerState extends State<SlidingOptionsDrawer> {
  bool _isOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sizing Logic
    final double handleWidth = widget.isSmall ? 24.0 : 40.0;
    final double buttonWidth = widget.isSmall ? 35.0 : 50.0; // Slimmer buttons (was 50/70)
    final double iconSize = widget.isSmall ? 20.0 : 30.0;
    
    final double drawerContentWidth = buttonWidth * widget.options.length; 
    final double totalDrawerWidth = drawerContentWidth + handleWidth;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Content (Child)
        widget.child,

        // Drawer
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: _isOpen ? 0 : -(drawerContentWidth), // Hide content, keep handle
          width: totalDrawerWidth,
          child: Row(
            children: [
              // Handle (Back Arrow Strip)
              GestureDetector(
                onTap: _toggleDrawer,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: handleWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151), // Dark Slate Grey
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(0)), 
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isOpen ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white,
                    size: iconSize, 
                  ),
                ),
              ),

              // Action Buttons
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.options.map((item) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          item.onTap();
                          _toggleDrawer(); // Auto-close
                        },
                        child: Container(
                          color: item.color,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RotatedBox(
                            quarterTurns: 3, // Vertical 270 degrees
                            child: Text(
                              item.label,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
