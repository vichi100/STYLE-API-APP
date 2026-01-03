import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController(text: "Vichi");
  final TextEditingController _mobileController = TextEditingController(text: "+91 98765 43210");
  final TextEditingController _emailController = TextEditingController(text: "vichi@example.com");
  final TextEditingController _heightController = TextEditingController(text: "5' 9\"");
  final TextEditingController _weightController = TextEditingController(text: "65 kg");

  File? _closeUpImage;
  File? _fullLengthImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isCloseUp) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isCloseUp) {
            _closeUpImage = File(image.path);
          } else {
            _fullLengthImage = File(image.path);
          }
          _checkForChanges();
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Initial State Tracking
  late String _initialName;
  late String _initialMobile;
  late String _initialEmail;
  late String _initialHeight;
  late String _initialWeight;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initialName = _nameController.text;
    _initialMobile = _mobileController.text;
    _initialEmail = _emailController.text;
    _initialHeight = _heightController.text;
    _initialWeight = _weightController.text;

    // Add listeners to detect changes
    _nameController.addListener(_checkForChanges);
    _mobileController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _heightController.addListener(_checkForChanges);
    _weightController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = 
        _nameController.text != _initialName ||
        _mobileController.text != _initialMobile ||
        _emailController.text != _initialEmail ||
        _heightController.text != _initialHeight ||
        _weightController.text != _initialWeight ||
        _closeUpImage != null ||  // Assuming initially null for now
        _fullLengthImage != null; // Assuming initially null for now
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF131314), // Dark background
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surface,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const SizedBox(height: 10),
             // Profile Fields
             _EditableProfileField(controller: _nameController, icon: Icons.person_outline, label: 'Name'),
             
             const SizedBox(height: 16),
             _EditableProfileField(controller: _mobileController, icon: Icons.phone_outlined, label: 'Mobile', keyboardType: TextInputType.phone),
             
             const SizedBox(height: 16),
             _EditableProfileField(controller: _emailController, icon: Icons.email_outlined, label: 'Email', keyboardType: TextInputType.emailAddress),
             
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(
                   child: _EditableProfileField(controller: _heightController, icon: Icons.height, label: 'Height'),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: _EditableProfileField(controller: _weightController, icon: Icons.monitor_weight_outlined, label: 'Weight'),
                 ),
               ],
             ),
             
             const SizedBox(height: 32),
             const Divider(color: Colors.white10),
             const SizedBox(height: 24),

             // Image Upload Boxes
             Row(
               children: [
                 Expanded(
                   child: _buildImageBox(
                     label: 'Close Up Pic',
                     image: _closeUpImage,
                     onTap: () => _pickImage(true),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: _buildImageBox(
                     label: 'Full Length',
                     image: _fullLengthImage,
                     onTap: () => _pickImage(false),
                   ),
                 ),
               ],
             ),
             
             const SizedBox(height: 40),
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _hasChanges 
                     ? () {
                         // TODO: Save logic -> Update _initialValues
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
                         setState(() {
                            _initialName = _nameController.text;
                            _initialMobile = _mobileController.text;
                            _initialEmail = _emailController.text;
                            _initialHeight = _heightController.text;
                            _initialWeight = _weightController.text;
                            _closeUpImage = null; // Reset for demo or handle real persistence logic if needed
                            _fullLengthImage = null;
                            _hasChanges = false;
                         });
                       }
                     : null, // Disable if no changes
                 style: ElevatedButton.styleFrom(
                   backgroundColor: _hasChanges ? Colors.white : Colors.white10,
                   foregroundColor: _hasChanges ? Colors.black : Colors.white38,
                   disabledBackgroundColor: Colors.white10,
                   disabledForegroundColor: Colors.white38,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               ),
             ),
          ],
        ),
      ),
    );
  }



}

class _EditableProfileField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;

  const _EditableProfileField({
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
  });

  @override
  State<_EditableProfileField> createState() => _EditableProfileFieldState();
}

class _EditableProfileFieldState extends State<_EditableProfileField> {
  late bool _isReadOnly;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isReadOnly = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _enableEditing() {
    setState(() {
      _isReadOnly = false;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        readOnly: _isReadOnly,
        style: const TextStyle(color: Colors.white),
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.label, // Label moves up when typing (Material Design behavior)
          labelStyle: const TextStyle(color: Colors.white54),
          floatingLabelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(widget.icon, color: Colors.white38, size: 20),
          suffixIcon: _isReadOnly
              ? GestureDetector(
                  onTap: _enableEditing,
                  child: Container(
                    color: Colors.transparent, 
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.edit, color: Colors.white70, size: 18),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          // isDense is removed to allow space for floating label
        ),
        onTapOutside: (_) {},
      ),
    );
  }
}
  Widget _buildImageBox({required String label, required File? image, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              image: image != null
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_a_photo, color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

