import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../wardrobe/application/wardrobe_images_provider.dart';
import 'widgets/horizontal_image_drawer.dart';
import 'widgets/particle_overlay.dart';
import 'widgets/stylized_category_button.dart';

class MismatchScreen extends ConsumerStatefulWidget {
  const MismatchScreen({super.key});

  @override
  ConsumerState<MismatchScreen> createState() => _MismatchScreenState();
}

class _MismatchScreenState extends ConsumerState<MismatchScreen> with TickerProviderStateMixin {
  List<String?> _selectedTops = [null];
  String? _selectedBottom;
  String? _analysisResult;
  String? _openTopCategory = 'wtop'; // Default open
  String? _openBottomCategory = 'wbottom'; // Default open
  bool _isAnalyzing = false;
  bool _showMergeOverlay = false;
  bool _isSinglesMode = false; // New state for Singles View
  late AnimationController _glowController;
  late AnimationController _mergeController;
  
  final ScrollController _thumbController = ScrollController();
  final ScrollController _bottomThumbController = ScrollController();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _mergeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _mergeController.dispose();
    _thumbController.dispose();
    _bottomThumbController.dispose();
    super.dispose();
  }

  double _getTabPosition(String id, double screenWidth) {
    if (_openTopCategory == id) return screenWidth - 28;
    
    final categories = ['wtop', 'jacket', 'shirt'];
    final closed = categories.where((c) => c != _openTopCategory).toList();
    int index = closed.indexOf(id);
    if (index == -1) return 0;
    
    int dist = (closed.length - 1) - index;
    return dist * 28.0; // Reduced width multiplier
  }

  double _getBottomTabPosition(String id, double screenWidth) {
    if (_openBottomCategory == id) return screenWidth - 28;
    
    final categories = ['skirt', 'wbottom'];
    final closed = categories.where((c) => c != _openBottomCategory).toList();
    int index = closed.indexOf(id);
    if (index == -1) return 0;
    
    int dist = (closed.length - 1) - index;
    return dist * 28.0; 
  }

  Future<void> _analyze() async {
    bool isValid = false;

    if (_isSinglesMode) {
      // In Singles Mode, we need at least the "One Piece" (which acts as a bottom slot)
      if (_selectedBottom != null) {
        isValid = true;
      }
    } else {
      // In Standard Mode, need Tops (non-null) and Bottom
      if (!_selectedTops.contains(null) && _selectedBottom != null) {
        isValid = true;
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSinglesMode 
            ? 'Please select a Bodycon dress' 
            : 'Please select all Tops and a Bottom'),
        ),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _showMergeOverlay = true;
    });

    // Play Merge Animation
    await _mergeController.forward(from: 0);

    setState(() {
      _showMergeOverlay = false;
    });

    _glowController.repeat(reverse: true);

    // Simulate HTTP Request (Dummy 3 seconds)
    await Future.delayed(const Duration(seconds: 3));
    
    _glowController.stop();
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult = "Looking good! \nNo mismatch detected."; 
      });
    }
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Material Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                StylizedCategoryButton(
                  icon: FontAwesomeIcons.shirt,
                  label: 'Tops',
                  color: Colors.cyanAccent,
                  onTap: () => _onCategorySelected('Tops'),
                ),
                 StylizedCategoryButton(
                  icon: FontAwesomeIcons.userAstronaut, // Pants icon approx
                  label: 'Bottoms',
                  color: Colors.purpleAccent,
                  onTap: () => _onCategorySelected('Bottoms'),
                ),
                StylizedCategoryButton(
                  icon: FontAwesomeIcons.personDress,
                  label: 'Singles',
                  color: Colors.pinkAccent,
                  onTap: () => _onCategorySelected('Singles'),
                  hasGlow: true, // User emphasized Singles?
                ),
                StylizedCategoryButton(
                  icon: FontAwesomeIcons.gem,
                  label: 'Accessory',
                  color: Colors.amberAccent,
                  onTap: () => _onCategorySelected('Accessory'),
                ),
                StylizedCategoryButton(
                  icon: FontAwesomeIcons.bagShopping,
                  label: 'Bag',
                  color: Colors.greenAccent,
                  onTap: () => _onCategorySelected('Bag'),
                ),
                 StylizedCategoryButton(
                  icon: FontAwesomeIcons.socks,
                  label: 'Footwear',
                  color: Colors.redAccent,
                  onTap: () => _onCategorySelected('Footwear'),
                ),
              ],
            ),
             const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _onCategorySelected(String category) {
    debugPrint('Selecting category: $category'); // Debug log
    setState(() {
      if (category == 'Singles') {
        _isSinglesMode = true;
      } else if (category == 'Tops' || category == 'Bottoms') {
        _isSinglesMode = false;
      }
    });
  }

  void _showImagePicker(bool isTop, {int? topIndex}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ImagePickerSheet(
        isTop: isTop,
        onSelect: (path) {
          setState(() {
            if (isTop) {
               if (topIndex != null && topIndex < _selectedTops.length) {
                 _selectedTops[topIndex] = path;
               } else if (_selectedTops.isNotEmpty) {
                 _selectedTops[0] = path;
               }
            } else {
              _selectedBottom = path;
            }
            _analysisResult = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagesAsync = ref.watch(wardrobeImagesProvider);
    final drawerWidth = 100.0; // Not used for logic, but kept var

    return Scaffold(
      /*
      appBar: AppBar(
        title: const Text('Mismatch Analysis'),
      ),
      */
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategorySheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      */
      body: SafeArea(
        child: Stack(
        children: [
          Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Unified Scroll View Area
                  // RESTORED: Selection Cards are always visible as per user request
                  SizedBox(
                    height: 260, 
                    child: Builder(
                      builder: (context) {
                         final screenWidth = MediaQuery.of(context).size.width;
                         // Adjusted for peek
                         final cardWidth = (screenWidth - 48) / 2.3;
                         
                         return SingleChildScrollView(
                           scrollDirection: Axis.horizontal,
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isSinglesMode) ...[
                                  // SINGLES MODE: 2 Boxes (One Piece + Jacket)
                                  Padding(
                                   padding: const EdgeInsets.only(right: 16),
                                   child: SizedBox(
                                     width: cardWidth,
                                     child: _SelectionCard(
                                       title: 'One Piece', // Or 'Singles'
                                       imagePath: _selectedBottom, // Bodycon stored in bottom slot
                                       message: _selectedBottom == null ? 'Select Bodycon' : null,
                                       onTap: () {
                                          // Typically this might open the picker but we have the strip below.
                                          _showImagePicker(false); // Can reuse standard picker logic if desired
                                       },
                                     ),
                                   ),
                                  ),
                                  Padding(
                                   padding: const EdgeInsets.only(right: 16),
                                   child: SizedBox(
                                     width: cardWidth,
                                     child: _SelectionCard(
                                       title: 'Jacket',
                                       imagePath: _selectedTops.isNotEmpty ? _selectedTops[0] : null,
                                       message: (_selectedTops.isEmpty || _selectedTops[0] == null) ? 'Select Jacket' : null,
                                       onTap: () => _showImagePicker(true, topIndex: 0),
                                     ),
                                   ),
                                  ),
                                ] else ...[
                                  // STANDARD MODE: Tops List + Add Button + Bottom Card
                                  ...List.generate(_selectedTops.length, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: SizedBox(
                                      width: cardWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                           Stack(
                                            children: [
                                              _SelectionCard(
                                                title: 'Top ${index + 1}',
                                                imagePath: _selectedTops[index],
                                                message: _selectedTops[index] == null ? 'Select Top' : null,
                                                onTap: () => _showImagePicker(true, topIndex: index),
                                              ),
                                              if (_selectedTops.length > 1)
                                                 Positioned(
                                                   top: 12,
                                                   right: 12,
                                                   child: GestureDetector(
                                                     onTap: () {
                                                       setState(() {
                                                         _selectedTops.removeAt(index);
                                                         _analysisResult = null;
                                                       });
                                                     },
                                                     child: Container(
                                                       padding: const EdgeInsets.all(4),
                                                       decoration: const BoxDecoration(
                                                         color: Colors.black54,
                                                         shape: BoxShape.circle,
                                                         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                                       ),
                                                       child: const Icon(Icons.remove, size: 16, color: Colors.white),
                                                     ),
                                                   ),
                                                 ),
                                            ],
                                           ),
                                           // Add Button below first top if limit not reached
                                           if (index == 0 && _selectedTops.length < 2)
                                             IconButton(
                                               onPressed: () => setState(() => _selectedTops.add(null)),
                                               icon: const Icon(Icons.add, size: 30),
                                               tooltip: "Add another Top",
                                             ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                
                                // Bottom Card (Standard Mode Only)
                                SizedBox(
                                  width: cardWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _SelectionCard(
                                        title: 'Bottom',
                                        imagePath: _selectedBottom,
                                        message: _selectedBottom == null ? 'Select Bottom' : null,
                                        onTap: () => _showImagePicker(false),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildHistoryIcon(),
                                    ],
                                  ),
                                ),
                                ],
                              ],
                           ),
                         );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final double hue = _glowController.value * 360;
                      final Color color1 = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
                      final Color color2 = HSVColor.fromAHSV(1.0, (hue + 120) % 360, 1.0, 1.0).toColor();
                      final Color color3 = HSVColor.fromAHSV(1.0, (hue + 240) % 360, 1.0, 1.0).toColor();

                      return GestureDetector(
                        onTap: _isAnalyzing ? null : _analyze,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(25),
                            border: _isAnalyzing ? Border.all(color: color1.withOpacity(0.8), width: 2) : Border.all(color: Colors.white, width: 1),
                            boxShadow: _isAnalyzing
                                ? [
                                    BoxShadow(
                                      color: color1.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: const Offset(-2, -2),
                                    ),
                                    BoxShadow(
                                      color: color2.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: const Offset(2, 2),
                                    ),
                                    BoxShadow(
                                      color: color3.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isAnalyzing)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color1)),
                                )
                              else
                                const Icon(Icons.analytics_outlined, color: Colors.white),
                              if (!_isAnalyzing) const SizedBox(width: 8),
                              Text(
                                _isAnalyzing ? 'Analyzing...' : 'Analyze Mismatch',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (_analysisResult != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, 
                               color: Theme.of(context).colorScheme.onPrimaryContainer, 
                               size: 40),
                          const SizedBox(height: 8),
                          Text(
                            _analysisResult!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Horizontal Split Tabs Side Drawer
          SizedBox(
            height: 60, // Reduced height to match bottom images visual size
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerRight,
              children: [
                // Drawer Panel Content
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width,
                  right: _openTopCategory != null ? 0 : -(MediaQuery.of(context).size.width - 28),
                  child: Container(
                    // Padding: Left 32 (Active Tab). Right 0.
                    padding: const EdgeInsets.only(left: 32, right: 0), 
                    color: Colors.grey.shade900.withOpacity(0.85), // Transparent Gray Background
                    child: imagesAsync.when(
                      data: (images) {
                        String filter = 'wtop';
                        if (_openTopCategory == 'jacket') filter = 'jacket';
                        if (_openTopCategory == 'shirt') filter = 'shirt';
                        
                        final filtered = images.where((path) => path.toLowerCase().contains(filter)).toList();
                        
                        if (filtered.isEmpty && _openTopCategory != null) return Center(child: Text("No ${filter}s found"));
                        if (_openTopCategory == null) return const SizedBox.shrink();

                        return ListView.builder(
                          controller: _thumbController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 70), // Ensure last items can be scrolled out from under tabs
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final path = filtered[index];
                            final isSelected = _selectedTops.contains(path);
                            return GestureDetector(
                              onTap: () => setState(() { 
                                // Quick select updates the first slot by default
                                if (_selectedTops.isNotEmpty) {
                                  _selectedTops[0] = path;
                                }
                                _analysisResult = null; 
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                margin: const EdgeInsets.only(right: 4), // Reduced Gap
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.transparent, width: 2),
                                  boxShadow: isSelected ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 8)] : [],
                                ),
                                child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.asset(path, fit: BoxFit.cover)),
                              ),
                            );
                          },
                        );
                      },
                       loading: () => const Center(child: CircularProgressIndicator()),
                       error: (_, __) => const SizedBox(),
                    ),
                  ),
                ),

                // Tab 1: Tops
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0, // Align with top
                  // Hide in Singles Mode
                  right: _isSinglesMode ? -100 : _getTabPosition('wtop', MediaQuery.of(context).size.width),
                  child: GestureDetector(
                    onTap: () => setState(() => _openTopCategory = _openTopCategory == 'wtop' ? null : 'wtop'),
                    child: Container(
                       width: 28, height: 60, // Match Drawer Height (60)
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         // Transparent Gray always
                         color: Colors.grey.shade900.withOpacity(0.6), 
                         borderRadius: BorderRadius.circular(8), 
                         boxShadow: [
                           if (_openTopCategory == 'wtop') // Glow when open
                             BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)
                           else
                             BoxShadow(color: Colors.black12, blurRadius: 4, offset:const Offset(-2, 0))
                         ],
                         border: Border.all(
                           color: _openTopCategory == 'wtop' ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                           width: 1, // Fixed 1px width
                         ),
                       ),
                       child: RotatedBox(quarterTurns: 3, child: Text("Tops", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _openTopCategory == 'wtop' ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white70))),
                    ),
                  ),
                ),

                // Tab 2: Jacket
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0, // Align with top
                  // Always visible (or adjusted position if it's the only one?)
                  // If it's the only one, maybe move it to the top position or keep it?
                  // Let's keep it in its slot for now, or move it to be the first one.
                  right: _isSinglesMode 
                      ? _getTabPosition('wtop', MediaQuery.of(context).size.width) // Take 'Tops' position (first slot)
                      : _getTabPosition('jacket', MediaQuery.of(context).size.width),
                  child: GestureDetector(
                    onTap: () => setState(() => _openTopCategory = _openTopCategory == 'jacket' ? null : 'jacket'),
                    child: Container(
                       width: 28, height: 60, // Match Drawer Height (60)
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         color: Colors.grey.shade900.withOpacity(0.6),
                         borderRadius: BorderRadius.circular(8),
                         boxShadow: [
                           if (_openTopCategory == 'jacket')
                             BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)
                           else
                             BoxShadow(color: Colors.black12, blurRadius: 4, offset:const Offset(-2, 0))
                         ],
                         border: Border.all(
                           color: _openTopCategory == 'jacket' ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                           width: 1,
                         ),
                       ),
                       child: RotatedBox(quarterTurns: 3, child: Text("Jacket", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _openTopCategory == 'jacket' ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white70))),
                    ),
                  ),
                ),

                // Tab 3: Shirt
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0, // Align with top
                  // Hide in Singles Mode
                  right: _isSinglesMode ? -100 : _getTabPosition('shirt', MediaQuery.of(context).size.width),
                  child: GestureDetector(
                    onTap: () => setState(() => _openTopCategory = _openTopCategory == 'shirt' ? null : 'shirt'),
                    child: Container(
                       width: 28, height: 60, // Match Drawer Height (60)
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         color: Colors.grey.shade900.withOpacity(0.6),
                         borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)), 
                         boxShadow: [
                           if (_openTopCategory == 'shirt')
                             BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)
                           else
                             BoxShadow(color: Colors.black12, blurRadius: 4, offset:const Offset(-2, 0))
                         ],
                         border: Border.all(
                           color: _openTopCategory == 'shirt' ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                           width: 1,
                         ),
                       ),
                       child: RotatedBox(quarterTurns: 3, child: Text("Shirt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _openTopCategory == 'shirt' ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white70))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12), // Added Gap between drawers

          // Bottom Drawer (Replaces Image Strip)
          SizedBox(
            height: 60,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerRight,
              children: [
                // Bottom Drawer Panel Content
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width,
                  right: (_openBottomCategory == 'skirt' || _openBottomCategory == 'wbottom') ? 0 : -(MediaQuery.of(context).size.width - 28),
                  child: Container(
                    padding: const EdgeInsets.only(left: 32, right: 0), 
                    color: Colors.grey.shade900.withOpacity(0.85),
                    child: imagesAsync.when(
                      data: (images) {
                        // Filter based on selected tab or defaults
                        String filter = 'wbottom'; // Default to pants
                        if (_openBottomCategory == 'skirt') filter = 'skirt';
                        // In Singles Mode, we might want Bodycon? User asked for Skirt/Bottoms specifically.
                        // Assuming this drawer is for standard mismatch mode.
                        
                        final filtered = images.where((path) => path.toLowerCase().contains(filter) || (filter == 'wbottom' && path.contains('pants'))).toList();
                        
                        if (filtered.isEmpty && (_openBottomCategory == 'skirt' || _openBottomCategory == 'wbottom')) return Center(child: Text("No ${filter}s found"));
                        if (!(_openBottomCategory == 'skirt' || _openBottomCategory == 'wbottom')) return const SizedBox.shrink();

                        return ListView.builder(
                          controller: _bottomThumbController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 60),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final path = filtered[index];
                            final isSelected = _selectedBottom == path;
                            return GestureDetector(
                              onTap: () => setState(() { 
                                _selectedBottom = path;
                                _analysisResult = null; 
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                margin: const EdgeInsets.only(right: 4), // Reduced Gap
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.transparent, width: 2),
                                  boxShadow: isSelected ? [BoxShadow(color: Colors.purpleAccent.withOpacity(0.6), blurRadius: 8)] : [],
                                ),
                                child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.asset(path, fit: BoxFit.cover)),
                              ),
                            );
                          },
                        );
                      },
                       loading: () => const Center(child: CircularProgressIndicator()),
                       error: (_, __) => const SizedBox(),
                    ),
                  ),
                ),

                // Tab 1: Skirt
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0,
                  right: _isSinglesMode ? -100 : _getBottomTabPosition('skirt', MediaQuery.of(context).size.width),
                  child: GestureDetector(
                    onTap: () => setState(() => _openBottomCategory = _openBottomCategory == 'skirt' ? null : 'skirt'),
                    child: Container(
                       width: 28, height: 60,
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         color: Colors.grey.shade900.withOpacity(0.6),
                         borderRadius: BorderRadius.circular(8), 
                         boxShadow: [
                           if (_openBottomCategory == 'skirt')
                             BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)
                           else
                             BoxShadow(color: Colors.black12, blurRadius: 4, offset:const Offset(-2, 0))
                         ],
                         border: Border.all(
                           color: _openBottomCategory == 'skirt' ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                           width: 1,
                         ),
                       ),
                       child: RotatedBox(quarterTurns: 3, child: Text("Skirt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _openBottomCategory == 'skirt' ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white70))),
                    ),
                  ),
                ),

                // Tab 2: Bottoms
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0,
                  right: _isSinglesMode ? -100 : _getBottomTabPosition('wbottom', MediaQuery.of(context).size.width),
                  child: GestureDetector(
                    onTap: () => setState(() => _openBottomCategory = _openBottomCategory == 'wbottom' ? null : 'wbottom'),
                    child: Container(
                       width: 28, height: 60,
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         color: Colors.grey.shade900.withOpacity(0.6), 
                         borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)), 
                         boxShadow: [
                           if (_openBottomCategory == 'wbottom')
                             BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)
                           else
                             BoxShadow(color: Colors.black12, blurRadius: 4, offset:const Offset(-2, 0))
                         ],
                         border: Border.all(
                           color: _openBottomCategory == 'wbottom' ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                           width: 1,
                         ),
                       ),
                       child: RotatedBox(quarterTurns: 3, child: Text("Bottoms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _openBottomCategory == 'wbottom' ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white70))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), // Bottom padding for tab bar clearance
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StylizedCategoryButton(
                  icon: FontAwesomeIcons.shirt,
                  label: 'Tops',
                  color: Colors.cyanAccent,
                  onTap: () => _onCategorySelected('Tops'),
                  hasGlow: !_isSinglesMode, // Glows when NOT in singles mode
                ),
                StylizedCategoryButton(
                  icon: FontAwesomeIcons.userAstronaut,
                  label: 'Bottoms',
                  color: Colors.purpleAccent,
                  onTap: () => _onCategorySelected('Bottoms'),
                  hasGlow: !_isSinglesMode, // Glows when NOT in singles mode
                  customIconPath: 'assets/icons/bottom.png',
                ),
                StylizedCategoryButton(
                  icon: FontAwesomeIcons.personDress,
                  label: 'Singles',
                  color: Colors.pinkAccent,
                  onTap: () => _onCategorySelected('Singles'),
                  hasGlow: _isSinglesMode, // Glows ONLY in singles mode
                  customIconPath: 'assets/icons/bodycon.png',
                ),
              ],
            ),
          ),
        ],
      ),
      ],
     ),
    ),
   );
 }

  Widget _buildHistoryIcon() {
    // Moving 40px right to occupy the whitespace margin
    return Transform.translate(
      offset: const Offset(40, 0),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.history, color: Colors.white, size: 24),
        onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("History Feature Coming Soon!")));
        },
      ),
    );
  }

  Widget _buildMergeOverlay() {
    // Approximate approximate positions of the cards for the particle effect
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2.3;
    final startY = 50.0; // Approx top padding in scroll view

    List<Rect> sourceRects = [];
    
    // Add Tops Rects
    for (int i = 0; i < _selectedTops.length; i++) {
        double x = 16.0 + (i * (cardWidth + 16.0));
        sourceRects.add(Rect.fromLTWH(x, startY, cardWidth, 200));
    }

    // Add Bottom Rect
    // It's after the tops in the Row
    double bottomX = 16.0 + (_selectedTops.length * (cardWidth + 16.0));
    sourceRects.add(Rect.fromLTWH(bottomX, startY, cardWidth, 200));

    // If we scrolled, these are wrong, but for visual flair it's okay. 
    // Ideally we'd use RenderBox, but this is a "Close Enough" approximation for the effect.

    return ParticleMismatchOverlay(
      controller: _mergeController,
      sourceRects: sourceRects,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String? imagePath;
  final String? message;
  final VoidCallback onTap;
  final Widget? overlay;

  const _SelectionCard({
    required this.title,
    required this.imagePath,
    this.message,
    required this.onTap,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imagePath != null
                    ? Image.asset(imagePath!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            title == 'Top' ? Icons.checkroom : Icons.vertical_align_bottom,
                            size: 48,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 8),
                          Text(message ?? title, style: TextStyle(color: Theme.of(context).disabledColor)),
                        ],
                      ),
              ),
            ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

class _ImagePickerSheet extends ConsumerWidget {
  final bool isTop;
  final Function(String) onSelect;

  const _ImagePickerSheet({required this.isTop, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(wardrobeImagesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      height: 500,
      child: Column(
        children: [
          Text('Select ${isTop ? "Top" : "Bottom"}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: imagesAsync.when(
              data: (images) {
                final filtered = images.where((path) {
                  if (isTop) return path.contains('wtop') || path.contains('top');
                  return path.contains('wbottom') || path.contains('bottom') || path.contains('pants');
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No items found."));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final path = filtered[index];
                    return GestureDetector(
                      onTap: () => onSelect(path),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(path, fit: BoxFit.cover),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => const Center(child: Text("Error loading images")),
            ),
          ),
        ],
      ),
    );
  }
}
