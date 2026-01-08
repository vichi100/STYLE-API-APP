
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:style_advisor/src/utils/country_service.dart';
import 'package:style_advisor/src/features/auth/domain/user.dart';
import 'package:style_advisor/src/features/auth/presentation/user_provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin, CodeAutoFill {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showOtp = false;
  String _dialCode = "+91"; // Default fallback
  String? _serverOtp; // Store the OTP received from server

  @override
  void initState() {
    super.initState();
    _fetchCountryCode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.addListener(() {
      setState(() {
        // Switch view halfway through the flip
        if (_animationController.value >= 0.5) {
          _showOtp = true;
        } else {
          _showOtp = false;
        }
      });
    });
  }
  
  Future<void> _fetchCountryCode() async {
    final details = await CountryService.getCountryDetails();
    if (mounted) {
      setState(() {
        _dialCode = details['dial_code'] ?? "+91";
      });
    }
  }

  @override

  void dispose() {
    cancel();
    _mobileController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      setState(() {
        _otpController.text = code!;
      });
      _validateOtp(code!);
    }
  }

  Future<void> _sendOtp(String mobile) async {
    try {
      final dio = Dio();
      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      // Using the IP provided by the user
      final response = await dio.post(
        '$baseUrl/auth/otp', 
        data: {'mobile': mobile},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final encodedOtp = response.data['otp'];
        // Decode Base64 OTP
        final decodedOtp = utf8.decode(base64Decode(encodedOtp));
        setState(() {
          _serverOtp = decodedOtp;
        });
        debugPrint("OTP Received and Decoded: $_serverOtp");
      } else {
        debugPrint("Failed to send OTP: ${response.statusMessage}");
      }
    } catch (e) {
      debugPrint("Error sending OTP: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server')),
        );
      }
    }
  }

  Future<void> _performLogin(String fullMobileNumber) async {
    try {
      final dio = Dio();
      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      final response = await dio.post(
        '$baseUrl/auth/login',
        data: {'mobile': fullMobileNumber},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData != null && responseData is Map<String, dynamic>) {
           if (responseData['data'] != null) {
              final userDataMap = responseData['data'] as Map<String, dynamic>;
              final rawStatus = responseData['status'];
              
              // Check status OR name for new user detection
              final isNewUser = rawStatus == 'new_user' || userDataMap['Name'] == 'New User';
              
              try {
                final user = User.fromJson(userDataMap, isNewUser: isNewUser);
                ref.read(userProvider.notifier).state = user;
                debugPrint("User logged in: $user");
              } catch (e) {
                debugPrint("Error parsing user data: $e");
              }
           }
        }
        
        if (mounted) {
           context.go('/kai');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${response.statusMessage}')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error performing login: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to login server')),
        );
      }
    }
  }

  void _validateMobile(String value) {
    if (value.length == 10) {
      // Trigger Flip Animation
      _animationController.forward();
      // Listen for SMS autofill
      listenForCode();
      // Call Backend to send OTP
      _sendOtp(value);
    }
  }

  void _validateOtp(String value) {
    if (value.length == 6) { 
        // TODO: Remove test OTP 999999 before production
        if ((_serverOtp != null && value == _serverOtp) || value == '999999') {
           // OTP Matches - Proceed to Login API
           // Construct full mobile number with dial code
           // Remove spaces if any in _dialCode just in case, though usually it's clean
           final fullMobile = "${_dialCode.trim()}${_mobileController.text}";
           _performLogin(fullMobile);
        } else if (_serverOtp != null) {
           // OTP Mismatch
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Invalid OTP'), 
               backgroundColor: Colors.redAccent,
             ),
           );
           // Clear OTP field for retry? Or just let user edit.
           _otpController.clear();
        } else {
           // Backdoor for testing if server is unreachable / no OTP received yet
           // Remove this in production or handle gracefully
           debugPrint("Verification skipped (No server OTP). Allowing for dev/demo if needed, or block.");
           // For now, blocking if no OTP received to enforce security as requested
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Verifying... please wait for OTP')),
           );
        }
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

                  // Animated Flip Container
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // 3D Flip Transform
                      final angle = _animationController.value * 3.14159; // PI (180 degrees)
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspective
                        ..rotateX(angle);
                        
                      // If showing back (OTP), rotate it back so it's not mirrored
                      if (_showOtp) {
                         transform.rotateX(-3.14159);
                      }

                      return Transform(
                        transform: transform,
                        alignment: Alignment.center,
                        child: _showOtp ? _buildOtpInput() : _buildMobileInput(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 60) / 10; // Reverted padding calc
          final iconSize = itemWidth * 0.65; 
          final fontSize = itemWidth * 0.8;

          return InputDecorator(
            decoration: InputDecoration(
              labelText: "  $_dialCode  ", // Country code on border with spacing
              labelStyle: const TextStyle(
                color: Colors.white70, 
                fontSize: 22, 
                fontWeight: FontWeight.bold
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              
              fillColor: Colors.black.withOpacity(0.3),
              filled: true,

              // Borders
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_mobileController.text.isEmpty)
                  SizedBox(
                    height: itemWidth * 1.3,
                    child: Center(
                      child: Text(
                        'Enter Mobile Number',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: fontSize * 0.9,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(10, (index) {
                      final iconColors = [
                        Colors.grey, Colors.pinkAccent, Colors.redAccent, Colors.orangeAccent,
                        Colors.amberAccent, Colors.greenAccent, Colors.cyanAccent, Colors.blueAccent,
                        Colors.indigoAccent, Colors.purpleAccent, Colors.tealAccent,
                      ];
                      final icons = [
                        Icons.checkroom_outlined, Icons.shopping_bag_outlined, Icons.style_outlined,
                        Icons.watch_outlined, Icons.diamond_outlined, Icons.favorite_border,
                        Icons.star_border, Icons.shopping_basket_outlined, Icons.dry_cleaning_outlined,
                        Icons.storefront_outlined,
                      ];

                      final isFilled = _mobileController.text.length > index;
                      
                      return SizedBox(
                        width: itemWidth, 
                        height: itemWidth * 1.3,
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
                              : index == 1 ? _PartyDressIcon(color: iconColors[index], size: iconSize)
                              : index == 2 ? _HeelIcon(color: iconColors[index], size: iconSize)
                              : index == 6 ? _SunglassIcon(color: iconColors[index % iconColors.length], size: iconSize)
                              : index == 9 ? _LipstickIcon(color: iconColors[index % iconColors.length], size: iconSize)
                              : Icon(icons[index % icons.length], color: iconColors[index % iconColors.length], size: iconSize),
                        ),
                      );
                    }),
                  ),

                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      autofocus: true, 
                      showCursor: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) {
                        setState(() {});
                        _validateMobile(val);
                      },
                      decoration: const InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      // No padding here, TextField handles it
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofocus: true,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          letterSpacing: 10, 
          fontWeight: FontWeight.bold
        ),
        textAlign: TextAlign.center,
        autofillHints: const [AutofillHints.oneTimeCode],
        onChanged: _validateOtp,
        decoration: InputDecoration(
          counterText: "",
          labelText: "$_dialCode ${_mobileController.text}",
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          
          fillColor: Colors.black.withOpacity(0.3),
          filled: true,

          // Borders
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white30),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          
          hintText: "• • • • • •",
          hintStyle: const TextStyle(color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
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


