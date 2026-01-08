import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:style_advisor/src/features/auth/presentation/user_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../theme/theme_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _pendingImagePath;

  @override
  void initState() {
    super.initState();
    // Initial greeting
    Future.delayed(const Duration(milliseconds: 500), () {
      final user = ref.read(userProvider);
      
      final missingProfile = user?.missingProfile ?? false;
      final missingWardrobe = user?.missingWardrobe ?? false;
      final isNewUser = user?.isNewUser ?? false;

      if (isNewUser || (missingProfile && missingWardrobe)) {
         _addBotMessage(
             "✨ Heyyy! Quick glow-up step 👀\n"
             "Do this once & slay always 🔥\n\n"
             "👤 [**Update your profile**](command:profile)\n\n"
             "👗 [**Add your clothes**](command:wardrobe)\n\n"
             "More personal. More accurate. Vibe check."
         );
      } else if (missingProfile) {
         _addBotMessage(
             "✨ Heyyy! Just one quick thing 👀\n"
             "To give you the best recs, I need to see you shine! ✨\n\n"
             "👤 [**Update your profile**](command:profile)\n\n"
             "Trust me, it makes a huge difference! 💅"
         );
      } else if (missingWardrobe) {
         _addBotMessage(
             "✨ Heyyy! Your closet is looking a bit empty 👀\n"
             "Let's fix that so I can style you properly! 🔥\n\n"
             "👗 [**Add your clothes**](command:wardrobe)\n\n"
             "More outfits = more slay. Period. 💅"
         );
      } else {
         _addBotMessage("Hey! I'm Adā, your personal stylist. How you wanna slay today? ✨");
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo != null) {
        setState(() {
          _pendingImagePath = photo.path;
        });
        _focusNode.requestFocus();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F20),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty && _pendingImagePath == null) return;
    
    final imageToSend = _pendingImagePath;
    _textController.clear();
    setState(() {
      _pendingImagePath = null;
    });

    _addUserMessage(text, imagePath: imageToSend);
    _focusNode.requestFocus(); // Keep focus

    // Simulate Bot Response
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        if (imageToSend != null) {
           _addBotMessage("Ooh, I love this vibe! 📸 Let me analyze this piece for you...");
        } else {
           _addBotMessage("That sounds fabulous! Let me find the perfect look for that. 👗👠");
        }
      }
    });
  }

  void _addUserMessage(String? text, {String? imagePath}) {
    setState(() {
      _messages.insert(0, _ChatMessage(text: text, imagePath: imagePath, isUser: true));
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.insert(0, _ChatMessage(text: text, isUser: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Adā'), // Adā
            Text(
              'Inspire / Styl / Sly / Unbothered',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push('/profile');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: const Color(0xFF131314), // Gemini Dark Background
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true, // Start from bottom
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == 0) {
                      return const _TypingIndicatorBubble();
                    }
                    // Adjust index if typing indicator is present
                    final msgIndex = _isTyping ? index - 1 : index;
                    final message = _messages[msgIndex];
                    return _MessageBubble(message: message);
                  },
                ),
              ),
              _buildInputArea(context), // Pass context for theme access if needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      color: const Color(0xFF131314), // Match bg
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F20), // Input BG
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.grey),
                onPressed: _showAttachmentOptions,
              ),
              if (_pendingImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_pendingImagePath!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _pendingImagePath = null),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Ask Adā...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: _handleSubmitted,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String? text;
  final String? imagePath;
  final bool isUser;

  _ChatMessage({this.text, this.imagePath, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    if (!isUser) {
      // Bot Message (No bubble, just text + icon)
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 0), // Align with text top
              child: Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20), // Gemini Sparkle
            ),
            const SizedBox(width: 12),
            Flexible(
              child: MarkdownBody(
                data: message.text ?? '',
                onTapLink: (text, href, title) {
                  if (href != null) {
                    if (href == 'command:profile') {
                      context.push('/profile');
                    } else if (href == 'command:wardrobe') {
                      context.go('/wardrobe'); // Use go for shell route branches
                    }
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  strong: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: Colors.white70),
                  a: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // User Message (Dark Grey Bubble)
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2F32), // Dark bubble
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.imagePath != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 8.0),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: Image.file(
                         File(message.imagePath!), 
                         height: 200, 
                         width: 200, 
                         fit: BoxFit.cover
                       ),
                     ),
                   ),
                  if (message.text != null)
                    Text(
                      message.text!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
           const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 12),
            // Minimal typing indicator (just dots, no bg)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: const Row(
                children: [
                   _Dot(delay: 0),
                   SizedBox(width: 4),
                   _Dot(delay: 100),
                   SizedBox(width: 4),
                   _Dot(delay: 200),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
