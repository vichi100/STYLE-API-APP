import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    if (value.length == 10 && int.tryParse(value) != null) {
      // Auto-login on valid input
      context.go('/kai');
    }
  }

  void _onLogin() {
    if (_isValid) {
      // Navigate to Dashboard
      // Assuming '/dashboard' or '/' is the main app route
      context.go('/'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/icons/loginbg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Gradient Overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // 3. Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title area
                  // Logo / Title area
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final titleSize = screenWidth * 0.12; // Responsive Title
                      final subtitleSize = screenWidth * 0.045; // Responsive Subtitle
                      
                      return Column(
                        children: [
                          Text(
                            'Adā', // 'STYL',
                            style: GoogleFonts.outfit(
                              fontSize: titleSize.clamp(32.0, 80.0), // Min 32, Max 80
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Personal AI Stylist',
                            style: GoogleFonts.outfit(
                              fontSize: subtitleSize.clamp(14.0, 24.0),
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 60),

                  // Custom Input Box Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, // Reduced padding to prevent overflow on small screens
                      vertical: 8, 
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // dynamically calculate sizes based on available width
                        final itemWidth = constraints.maxWidth / 10;
                        final iconSize = itemWidth * 0.65; // ~65% of slot width
                        final fontSize = itemWidth * 0.8;  // ~80% of slot width

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Visible Layer: Hint OR Row of Slots
                            if (_mobileController.text.isEmpty)
                              SizedBox(
                                height: itemWidth * 1.3, // Match Row height to prevent jump
                                child: Center(
                                  child: Text(
                                    'Enter Mobile Number',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: fontSize * 0.9, // Responsive, slightly smaller than digits
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(10, (index) {
                                // Colors List
                                final iconColors = [
                                  Colors.grey,            // 0: (Never seen as placeholder)
                                  Colors.pinkAccent,      // 1: Skirt (Seen after 1 digit)
                                  Colors.redAccent,       // 2: Heel  (Seen after 2 digits)
                                  Colors.orangeAccent,    // 3: Bag
                                  Colors.amberAccent,     // 4: Style
                                  Colors.greenAccent,     // 5: Watch
                                  Colors.cyanAccent,      // 6: Diamond
                                  Colors.blueAccent,      // 7: Heart
                                  Colors.indigoAccent,    // 8: Star
                                  Colors.purpleAccent,    // 9: Basket
                                  Colors.tealAccent,      // 9: DryClean (Actually 10th item)
                                  // We need 10 items. 0-9.
                                  // 0: grey
                                  // 1: pink
                                  // 2: red
                                  // 3: orange
                                  // 4: amber
                                  // 5: green
                                  // 6: cyan
                                  // 7: blue
                                  // 8: indigo
                                  // 9: purple
                                ];
                                // Let's correct the list length implicitly or explicitly if needed, 
                                // but previously it was working with the list I gave.
                                // Just ensuring I copy the context correctly.
                                
                                // Fashion Icons List
                                final icons = [
                                  Icons.checkroom_outlined,
                                  Icons.shopping_bag_outlined,
                                  Icons.style_outlined,
                                  Icons.watch_outlined,
                                  Icons.diamond_outlined,
                                  Icons.favorite_border,
                                  Icons.star_border,
                                  Icons.shopping_basket_outlined,
                                  Icons.dry_cleaning_outlined,
                                  Icons.storefront_outlined,
                                ];

                                final isFilled = _mobileController.text.length > index;
                                
                                return SizedBox(
                                  width: itemWidth, 
                                  height: itemWidth * 1.3, // Aspect ratio roughly maintained
                                  child: Center(
                                    child: isFilled
                                        ? Text(
                                            _mobileController.text[index],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : index == 1 
                                              ? _PartyDressIcon(
                                                  color: iconColors[index],
                                                  size: iconSize,
                                                )
                                              : index == 2
                                                  ? _HeelIcon(
                                                      color: iconColors[index],
                                                      size: iconSize,
                                                    )
                                                  : index == 6 
                                                      ? _SunglassIcon(
                                                          color: iconColors[index % iconColors.length], // Safe access
                                                          size: iconSize,
                                                        )
                                                      : index == 9
                                                          ? _LipstickIcon(
                                                              color: iconColors[index % iconColors.length],
                                                              size: iconSize,
                                                            )
                                                          : Icon(
                                                              icons[index % icons.length],
                                                              color: iconColors[index % iconColors.length],
                                                              size: iconSize, 
                                                            ),
                                  ),
                                );
                                }),
                              ),

                            // Hidden Input Layer (Captures Focus & Text)
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.0,
                                child: TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  autofocus: false,
                                  showCursor: false, // Hide cursor to rely on slot visuals
                                  cursorColor: Colors.transparent, // Ensure cursor is invisible
                                  style: const TextStyle(color: Colors.transparent), // Ensure text is invisible
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (val) {
                                    setState(() {}); // Rebuild visible layer
                                    _validateInput(val);
                                  },
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero, // Remove padding to align
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyDressIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _PartyDressIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PartyDressPainter(color: color),
    );
  }
}

class _PartyDressPainter extends CustomPainter {
  final Color color;

  _PartyDressPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ViewBox is 24x24. Scale to widget size.
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final path = Path();
    
    // Elegant Party Dress Path
    path.moveTo(9, 3);          // Top Left Strap
    path.lineTo(10, 10);        // Waist Left
    path.quadraticBezierTo(7, 15, 5, 21); // Skirt Flare Left
    path.lineTo(19, 21);        // Hem
    path.quadraticBezierTo(17, 15, 14, 10); // Skirt Flare Right
    path.lineTo(15, 3);         // Top Right Strap
    path.lineTo(12, 5);         // Neck V-point
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeelIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _HeelIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeelPainter(color: color),
    );
  }
}

class _HeelPainter extends CustomPainter {
  final Color color;

  _HeelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final path = Path();
    // Custom High Heel Path
    // M5 21 L7 21 L7 12 Q12 18 18 18 L20 18 L20 15 Q12 15 5 5 Z
    path.moveTo(5, 21);
    path.lineTo(7, 21);
    path.lineTo(7, 12);
    path.quadraticBezierTo(12, 18, 18, 18);
    path.lineTo(20, 18);
    path.lineTo(20, 15);
    path.quadraticBezierTo(12, 15, 5, 5);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SunglassIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _SunglassIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SunglassPainter(color: color),
    );
  }
}

class _SunglassPainter extends CustomPainter {
  final Color color;

  _SunglassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final path = Path();
    
    // Wayfarer Style
    // Top Bar
    path.moveTo(4, 8);
    path.lineTo(20, 8);
    
    // Left Lens Frame
    path.moveTo(4, 8);
    path.quadraticBezierTo(4, 15, 6, 17); // Left side curve
    path.quadraticBezierTo(9, 18, 11, 15); // Bottom curve to bridge
    path.lineTo(11, 8); // Close top
    
    // Right Lens Frame
    path.moveTo(20, 8);
    path.quadraticBezierTo(20, 15, 18, 17); // Right side curve
    path.quadraticBezierTo(15, 18, 13, 15); // Bottom curve to bridge
    path.lineTo(13, 8); // Close top
    
    // Bridge
    path.moveTo(11, 9);
    path.quadraticBezierTo(12, 8, 13, 9);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LipstickIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _LipstickIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LipstickPainter(color: color),
    );
  }
}

class _LipstickPainter extends CustomPainter {
  final Color color;

  _LipstickPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final path = Path();
    
    // Top Part: M10 2h4v6h-4z (Rect x=10, y=2, w=4, h=6)
    path.addRect(const Rect.fromLTWH(10, 2, 4, 6));
    
    // Bottom Case: M9 8h6v12H9z (Rect x=9, y=8, w=6, h=12)
    path.addRect(const Rect.fromLTWH(9, 8, 6, 12));
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


