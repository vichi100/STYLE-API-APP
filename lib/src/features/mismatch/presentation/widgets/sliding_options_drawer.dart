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
  final Color? optionsBackgroundColor; // New param

  const SlidingOptionsDrawer({
    super.key,
    required this.child,
    required this.options,
    this.isSmall = false,
    this.optionsBackgroundColor,
  });

  @override
  State<SlidingOptionsDrawer> createState() => _SlidingOptionsDrawerState();
}

class _SlidingOptionsDrawerState extends State<SlidingOptionsDrawer> {
  // ... (keep state logic same)
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
    final double buttonWidth = widget.isSmall ? 35.0 : 50.0; 
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
          right: _isOpen ? 0 : -(drawerContentWidth), 
          width: totalDrawerWidth,
          child: Row(
            children: [
              // Handle
              GestureDetector(
                onTap: _toggleDrawer,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: handleWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151), 
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
                    // Logic: If custom background is set, use it for bg and item.color for text.
                    // Else, use item.color for bg and white/gold for text.
                    final bgColor = widget.optionsBackgroundColor ?? item.color;
                    final textColor = widget.optionsBackgroundColor != null 
                        ? item.color 
                        : (item.color.computeLuminance() < 0.15 ? Colors.amberAccent : Colors.white);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          item.onTap();
                          _toggleDrawer(); 
                        },
                        child: Container(
                          color: bgColor,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RotatedBox(
                            quarterTurns: 3, 
                            child: Text(
                              item.label,
                              style: TextStyle(
                                  color: textColor, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 11
                              ),
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
