import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:style_advisor/src/features/auth/presentation/user_provider.dart';
import 'package:style_advisor/src/features/mismatch/presentation/analysis_result_screen.dart';
import 'package:style_advisor/src/features/style/data/style_repository.dart';
import '../../wardrobe/application/wardrobe_api_provider.dart';
import '../../wardrobe/domain/wardrobe_item.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Ensure this is available or use Image.network
import 'widgets/horizontal_image_drawer.dart';
import 'widgets/particle_overlay.dart';
import 'widgets/stylized_category_button.dart';
import 'widgets/sliding_options_drawer.dart';


enum _StripType { top, bottom, singles, footwear }

class MismatchScreen extends ConsumerStatefulWidget {
  const MismatchScreen({super.key});

  @override
  ConsumerState<MismatchScreen> createState() => _MismatchScreenState();
}

class _MismatchScreenState extends ConsumerState<MismatchScreen> with TickerProviderStateMixin {
  final List<String?> _selectedTops = [null]; // Start with one empty top slot
  String? _selectedBottom;
  String? _selectedDress; // dedicated variable for Singles mode
  String? _selectedFootwear;
  String? _analysisResult;
  String? _activeTopCategory = 'Tops'; // Default open
  String? _activeBottomCategory = 'Jeans'; // Default open
  String? _activeSinglesCategory = 'Dress'; // Default open
  String? _activeFootwearCategory = 'Heels'; // Default open
  bool _isAnalyzing = false;
  bool _showMergeOverlay = false;
  bool _isSinglesMode = false; // New state for Singles View
  late AnimationController _glowController;
  late AnimationController _mergeController;
  
  // Mood Selection
  String _selectedMood = 'Casual';
  final List<String> _moods = ['Casual', 'Party', 'Date Lunch', 'Date Night', 'Office', 'Gym'];
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



  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      if (_isSinglesMode) {
        throw Exception("Style scoring for singles is coming soon!");
      }

      final user = ref.read(userProvider);
      if (user == null) throw Exception("User session not found");

      final items = ref.read(wardrobeApiProvider).asData?.value ?? [];
      
      // Get Top
      final topUrl = _selectedTops.isNotEmpty ? _selectedTops[0] : null;
      if (topUrl == null) throw Exception("Please select a top");
      
      final topItem = items.firstWhere(
        (i) => i.imageUrl == topUrl, 
        orElse: () => throw Exception("Top item data not found")
      );

      // Get Bottom
      if (_selectedBottom == null) throw Exception("Please select a bottom");
      
      final bottomItem = items.firstWhere(
        (i) => i.imageUrl == _selectedBottom, 
        orElse: () => throw Exception("Bottom item data not found")
      );
      
      // Get Layer (Optional)
      WardrobeItem? layerItem;
      if (_selectedTops.length > 1 && _selectedTops[1] != null) {
         try {
           layerItem = items.firstWhere((i) => i.imageUrl == _selectedTops[1]);
         } catch (_) {} 
      }

      final repo = ref.read(styleRepositoryProvider);
      
      // Assuming the API returns a JSON string or descriptive text.
      // If it returns a JSON object, we might want to parse it. 
      // For now, we display the raw response or basic success.
      final result = await repo.scoreStyle(
        mood: _selectedMood ?? "Casual Date",
        top: topItem,
        bottom: bottomItem,
        layer: layerItem,
        userId: user.id,
      );
      
      if (!mounted) return;

      debugPrint("API Response: $result"); // Debugging

      // Extract scores (handle if they are strings or numbers)
      double parseScore(dynamic val) {
        if (val is num) return val.toDouble();
        if (val is String) {
             // Handle "85%" or "85"
             final cleaned = val.replaceAll('%', '').trim();
             return double.tryParse(cleaned) ?? 0.0;
        }
        return 0.0;
      }

      // Check for nested 'data' if API wrapper exists
      final data = result.containsKey('data') ? result['data'] : result;

      // Map Keys: total_score, mood_score, match_confidence (inside matched_palette)
      final double totalScore = parseScore(data['total_score'] ?? 85); 
      final double vibeScore = parseScore(data['mood_score'] ?? 80);
      
      double colorScore = 90;
      if (data['matched_palette'] != null && data['matched_palette'] is Map) {
         colorScore = parseScore(data['matched_palette']['match_confidence'] ?? 90);
      } else {
         colorScore = parseScore(data['match_confidence'] ?? 90);
      }

      final String verdict = data['critique'] ?? data['mood_analysis'] ?? data.toString();
      
      final Map<String, dynamic>? suggestions = data['suggestions'];
      // Extract inspiration URL if available
      final String? inspirationUrl = data['pinterest_search_url'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            topImage: topUrl,
            bottomImage: _selectedBottom,
            layerImage: (_selectedTops.length > 1) ? _selectedTops[1] : null,
            result: verdict,
            totalScore: totalScore,
            vibeScore: vibeScore,
            colorScore: colorScore,
            suggestions: suggestions,
            inspirationUrl: inspirationUrl,
          ),
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Widget _buildMoodSelector() {
    // Helper to get Mood Data
    (IconData, Color) getMoodData(String mood) {
      switch (mood) {
        case 'Casual': return (Icons.weekend_outlined, const Color(0xFF64B5F6));
        case 'Party': return (Icons.celebration_outlined, const Color(0xFFFF1744));
        case 'Date Lunch': return (Icons.restaurant_outlined, const Color(0xFFFFD54F));
        case 'Date Night': return (Icons.local_bar_outlined, const Color(0xFFBA68C8));
        case 'Office': return (Icons.business_center_outlined, const Color(0xFF81C784));
        case 'Gym': return (Icons.fitness_center_outlined, const Color(0xFFE57373));
        default: return (Icons.style, Colors.cyanAccent);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _moods.map((mood) {
              final isSelected = _selectedMood == mood;
              final data = getMoodData(mood);
              
              return _BentoTile(
                label: mood,
                icon: data.$1,
                color: data.$2,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedMood = mood),
              );
            }).toList(),
          ),
        ),
      ],
    );
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
    debugPrint('Selecting category: $category'); 
    setState(() {
      if (category == 'Singles') {
        _isSinglesMode = true;
        _activeSinglesCategory = 'Oomph'; // Auto-open "Oomph" drawer by default
      } else if (category == 'Tops' || category == 'Bottoms') {
        _isSinglesMode = false;
        
        // Ensure Tops are ALWAYS open by default when returning to Standard Mode
        if (_activeTopCategory == null) _activeTopCategory = 'Top'; 
        
        // If specifically clicked Bottoms, ensure Bottoms are open (Jeans default)
        if (category == 'Bottoms' && _activeBottomCategory == null) {
           _activeBottomCategory = 'Jeans';
        }
      } else {
         // Should we handle Footwear etc?
      }
    });
  }

  void _showImagePicker(bool isTop, {int? topIndex}) {
    showModalBottomSheet(
      context: context,

      builder: (ctx) => _ImagePickerSheet(
        isTop: isTop,
        isLayer: topIndex != null && topIndex > 0, // Pass true if it's a secondary top slot
        onSelect: (path) {
          setState(() {
            if (isTop) {
               // Directly use topIndex if provided, otherwise default to 0
               final targetIndex = topIndex ?? 0;
               
               if (targetIndex < _selectedTops.length) {
                  _selectedTops[targetIndex] = path;
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
    final imagesAsync = ref.watch(wardrobeApiProvider);
    final drawerWidth = 100.0;

    return Scaffold(
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
                        // Selection Cards Area
                        SizedBox(
                          width: double.infinity,
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                                SizedBox(
                                  height: 260,
                                  child: Builder(
                                    builder: (context) {
                                      final screenWidth = MediaQuery.of(context).size.width;
                                      final cardWidth = (screenWidth - 48) / 2.3;

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (_isSinglesMode) ...[
                                              // SINGLES MODE
                                              Padding(
                                                padding: const EdgeInsets.only(right: 16),
                                                child: SizedBox(
                                                  width: cardWidth,
                                                  child: _SelectionCard(
                                                    title: 'One Piece',
                                                    imagePath: _selectedDress,
                                                    message: _selectedDress == null ? 'Select Bodycon' : null,
                                                    onTap: null, 
                                                    onDelete: null,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(right: 16),
                                                child: SizedBox(
                                                  width: cardWidth,
                                                  child: _SelectionCard(
                                                    title: 'Footwear',
                                                    imagePath: _selectedFootwear,
                                                    message: _selectedFootwear == null ? 'Select Shoes' : null,
                                                    onTap: () => _onCategorySelected('Footwear'),
                                                    onDelete: null,
                                                  ),
                                                ),
                                              ),
                                            ] else ...[
                                              // STANDARD MODE
                                              ...List.generate(_selectedTops.length, (index) {
                                                return Padding(
                                                  key: ValueKey('top_$index'),
                                                  padding: const EdgeInsets.only(right: 16),
                                                  child: SizedBox(
                                                    width: cardWidth,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        _SelectionCard(
                                                            title: index == 0 ? 'Top' : 'Layer',
                                                            imagePath: _selectedTops[index],
                                                            message: _selectedTops[index] == null ? (index == 0 ? 'Select Top' : 'Select Layer') : null,
                                                            onTap: () => _showImagePicker(true, topIndex: index),
                                                            onDelete: index > 0 ? () {
                                                              setState(() {
                                                                _selectedTops.removeAt(index);
                                                                _analysisResult = null;
                                                              });
                                                            } : null,
                                                          ),
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

                                              // Bottom Card
                                              SizedBox(
                                                width: cardWidth,
                                                child: _SelectionCard(
                                                  title: 'Bottom',
                                                  imagePath: _selectedBottom,
                                                  message: _selectedBottom == null ? 'Select Bottom' : null,
                                                  onTap: () => _showImagePicker(false),
                                                  onDelete: null,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              Positioned(
                                right: -11,
                                top: 200,
                                child: _buildHistoryIcon(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        

                  
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
          
          // Mood Selector (Fixed above drawers)
          const SizedBox(height: 8),
          _buildMoodSelector(),
          const SizedBox(height: 8),

          // Action Bar for Top Selection (Visible only when NOT in Singles Mode)
          if (!_isSinglesMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 8), 
              child: SizedBox(
                height: 70, 
                child: imagesAsync.when(
                  data: (items) {
                    final topCategories = items
                        .where((i) => i.generalCategory.toLowerCase() == 'top')
                        .map((i) => i.customCategory)
                        .toSet()
                        .toList();
                    
                    if (topCategories.isEmpty) topCategories.add('Tops');
                    topCategories.sort();

                    return SlidingOptionsDrawer(
                      isSmall: true,
                      optionsBackgroundColor: const Color(0xFF212121),
                      options: topCategories.map((cat) => 
                        DrawerOptionItem(
                          label: cat, 
                          color: _getColorForCategory(cat), 
                          onTap: () => setState(() => _activeTopCategory = cat)
                        )
                      ).toList(),
                      child: Align(
                         alignment: Alignment.centerLeft, 
                         child: _activeTopCategory != null 
                             ? _buildInlineImageStrip(_activeTopCategory!, stripType: _StripType.top) 
                             : const SizedBox.shrink(),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const Center(child: Text("Error loading options")),
                ),
              ),
            ),

          if (!_isSinglesMode) const SizedBox(height: 2),



               // Action Bar for Bottom Selection (Visible only when NOT in Singles Mode)
                if (!_isSinglesMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 0, 8), 
                    child: SizedBox(
                      height: 70, 
                      child: imagesAsync.when(
                        data: (items) {
                          final bottomCategories = items
                              .where((i) {
                                 final g = i.generalCategory.toLowerCase();
                                 return g == 'bottom' || g.contains('pant') || g.contains('skirt') || g.contains('short');
                              })
                              .map((i) => i.customCategory)
                              .toSet()
                              .toList();
                          
                          if (bottomCategories.isEmpty) {
                             bottomCategories.addAll(['Jeans', 'Trousers', 'Skirts', 'Shorts']);
                          }
                          bottomCategories.sort();

                          return SlidingOptionsDrawer(
                            isSmall: true,
                            optionsBackgroundColor: const Color(0xFF212121),
                            options: bottomCategories.map((cat) => 
                              DrawerOptionItem(
                                label: cat, 
                                color: _getColorForCategory(cat), 
                                onTap: () => setState(() => _activeBottomCategory = cat)
                              )
                            ).toList(),
                            child: Align(
                               alignment: Alignment.centerLeft, 
                               child: _activeBottomCategory != null
                                   ? _buildInlineImageStrip(_activeBottomCategory!, stripType: _StripType.bottom) 
                                   : const SizedBox.shrink(),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Center(child: Text("Error")),
                      ),
                    ),
                  ),

                // Action Bar for Singles Selection (Visible only in Singles Mode)
                if (_isSinglesMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 0, 8), 
                    child: SizedBox(
                      height: 70, 
                      child: imagesAsync.when(
                        data: (items) {
                          final singlesCategories = items
                              .where((i) {
                                 final g = i.generalCategory.toLowerCase();
                                 return g.contains('dress') || g.contains('gown') || g.contains('suit') || g.contains('jump') || g.contains('one');
                              })
                              .map((i) => i.customCategory)
                              .toSet()
                              .toList();
                          
                          if (singlesCategories.isEmpty) {
                             singlesCategories.addAll(['Oomph', 'Dress', 'Gowns', 'Jumpsuits']);
                          }
                          singlesCategories.sort();

                          return SlidingOptionsDrawer(
                            isSmall: true,
                            optionsBackgroundColor: const Color(0xFF212121),
                            options: singlesCategories.map((cat) => 
                              DrawerOptionItem(
                                label: cat, 
                                color: _getColorForCategory(cat), 
                                onTap: () => setState(() => _activeSinglesCategory = cat)
                              )
                            ).toList(),
                            child: Align(
                               alignment: Alignment.centerLeft, 
                               child: _activeSinglesCategory != null
                                   ? _buildInlineImageStrip(_activeSinglesCategory!, stripType: _StripType.singles) 
                                   : const SizedBox.shrink(),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Center(child: Text("Error")),
                      ),
                    ),
                  ),

                if (_isSinglesMode) const SizedBox(height: 2), 

                // Footwear Drawer for Singles Mode
                if (_isSinglesMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 0, 8), 
                    child: SizedBox(
                      height: 70, 
                      child: imagesAsync.when(
                        data: (items) {
                          final footwearCategories = items
                              .where((i) {
                                 final g = i.generalCategory.toLowerCase();
                                 return g.contains('shoe') || g.contains('footwear') || g.contains('heel') || g.contains('boot') || g.contains('sandal') || g.contains('sneaker');
                              })
                              .map((i) => i.customCategory)
                              .toSet()
                              .toList();
                          
                          if (footwearCategories.isEmpty) {
                             footwearCategories.addAll(['Heels', 'Boots', 'Sneakers']);
                          }
                          footwearCategories.sort();

                          return SlidingOptionsDrawer(
                            isSmall: true,
                            optionsBackgroundColor: const Color(0xFF212121),
                            options: footwearCategories.map((cat) => 
                              DrawerOptionItem(
                                label: cat, 
                                color: _getColorForCategory(cat), 
                                onTap: () => setState(() => _activeFootwearCategory = cat)
                              )
                            ).toList(),
                            child: Align(
                               alignment: Alignment.centerLeft, 
                               child: _activeFootwearCategory != null
                                   ? _buildInlineImageStrip(_activeFootwearCategory!, stripType: _StripType.footwear) 
                                   : const SizedBox.shrink(),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Center(child: Text("Error")),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StylizedCategoryButton(
                        icon: FontAwesomeIcons.shirt,
                        label: 'Tops',
                        color: Colors.cyanAccent,
                        onTap: () => _onCategorySelected('Tops'),
                        hasGlow: !_isSinglesMode,
                      ),
                      StylizedCategoryButton(
                        icon: FontAwesomeIcons.userAstronaut,
                        label: 'Bottoms',
                        color: Colors.purpleAccent,
                        onTap: () => _onCategorySelected('Bottoms'),
                        hasGlow: !_isSinglesMode,
                        customIconPath: 'assets/icons/bottom.png',
                      ),
                      StylizedCategoryButton(
                        icon: FontAwesomeIcons.personDress,
                        label: 'Singles',
                        color: Colors.pinkAccent,
                        onTap: () => _onCategorySelected('Singles'),
                        hasGlow: _isSinglesMode,
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



  Widget _buildInlineImageStrip(String category, {required _StripType stripType}) {
    final imagesAsync = ref.watch(wardrobeApiProvider);
    
    return Row(
      children: [
        // Horizontal Image List
        Expanded(
          child: imagesAsync.when(
            data: (items) {
               // Filter Logic for API Items
               // We filter by 'customCategory' matching the selected category label
               // AND ensure it matches the general type (Top/Bottom) to avoid category name collisions if any
               
               final filtered = items.where((item) {
                 // Check category match
                 bool catMatch = item.customCategory.toLowerCase() == category.toLowerCase();
                 
                 // Check Type Match
                 if (stripType == _StripType.top) {
                    return catMatch && item.generalCategory.toLowerCase() == 'top'; // or 'Top'?
                 } else if (stripType == _StripType.bottom) {
                     // Bottom Categories: Match custom category AND ensure general category is valid
                     final g = item.generalCategory.toLowerCase();
                     final isBottom = g == 'bottom' || g.contains('pant') || g.contains('skirt') || g.contains('short');
                     return catMatch && isBottom;
                 } else if (stripType == _StripType.singles) {
                     // Singles: Match custom category AND ensure general category is valid
                     final g = item.generalCategory.toLowerCase();
                     final isSingle = g.contains('dress') || g.contains('gown') || g.contains('suit') || g.contains('jump') || g.contains('one');
                     
                     if (category == 'Oomph') return isSingle; // 'Oomph' shows all single items
                     
                     return catMatch && isSingle;
                 } else {
                     // Footwear
                     final g = item.generalCategory.toLowerCase();
                     final isFootwear = g.contains('shoe') || g.contains('footwear') || g.contains('heel') || g.contains('boot') || g.contains('sandal') || g.contains('sneaker');
                     return catMatch && isFootwear;
                 }

               }).toList();


              if (filtered.isEmpty) return const Text("No items", style: TextStyle(color: Colors.white54, fontSize: 10));
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 40), // Pad right for drawer handle!
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final path = item.imageUrl;
                  
                  // Check if selected

                  bool isSelected = false;
                  if (stripType == _StripType.bottom) isSelected = _selectedBottom == path;
                  else if (stripType == _StripType.singles) isSelected = _selectedDress == path;
                  else if (stripType == _StripType.footwear) isSelected = _selectedFootwear == path;
                  else isSelected = _selectedTops.contains(path);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (stripType == _StripType.bottom) {
                             _selectedBottom = path;
                        } else if (stripType == _StripType.footwear) {
                             _selectedFootwear = path;
                        } else {
                          // Tops or Singles (One Piece)
                          if (_isSinglesMode && stripType == _StripType.singles) {
                              _selectedDress = path; // Updated to use dedicated Dress variable
                          } else {
                          // Tops
                          // Smart Layering Logic:
                          // If current item is a "Layer" type and we already have a Top (index 0), then ADD/UPDATE it as a Layer (index > 0).
                          final c = item.customCategory.toLowerCase();
                          final isLayerItem = c.contains('jacket') || c.contains('layer') || c.contains('coat') || c.contains('blazer') || c.contains('cardigan') || c.contains('shrug');
                          
                          if (isLayerItem && _selectedTops.isNotEmpty && _selectedTops[0] != null) {
                              // We have a top, and this is a layer.
                              // Check if we have a second slot?
                              if (_selectedTops.length < 2) {
                                  _selectedTops.add(path); // Add as new layer
                              } else {
                                  _selectedTops[1] = path; // Replace current layer (simplification)
                              }
                          } else {
                              // Standard behavior: Replace Main Top
                              if (_selectedTops.isNotEmpty) {
                                  _selectedTops[0] = path;
                              } else {
                                  _selectedTops.add(path);
                              }
                          }
                          }
                        }
                        _analysisResult = null;
                      });
                    },

                    child: Container(
                      width: 55, // Increased width
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24, width: isSelected ? 2 : 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                            path, 
                            fit: BoxFit.cover, 
                            alignment: Alignment.topCenter,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24, size: 20),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_,__) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  // Helper for dynamic colors
  Color _getColorForCategory(String category) {
      final key = category.toLowerCase();
      
      // Tops (Vibrant for Dark Theme)
      if (key.contains('top')) return Colors.redAccent;
      if (key.contains('shirt')) return Colors.lightBlueAccent; // Vibrant Blue
      if (key.contains('layer') || key.contains('jacket')) return Colors.yellowAccent; // Vibrant Yellow
      if (key.contains('active')) return Colors.tealAccent; // Vibrant Teal
      if (key.contains('ethnic')) return Colors.purpleAccent;
      
      // Singles (Vibrant for Dark Theme)
      if (key.contains('dress')) return Colors.pinkAccent; 
      if (key.contains('gown')) return Colors.cyanAccent;
      if (key.contains('jump') || key.contains('suit')) return Colors.amberAccent;
      if (key.contains('one')) return Colors.lightGreenAccent;

      // Bottoms (Vibrant for Dark Theme)
      if (key.contains('jean')) return Colors.lightBlueAccent; // Vibrant Blue/Grey
      if (key.contains('trouser') || key.contains('pant')) return Colors.amber; // Brown is too dark, use Amber/Orange
      if (key.contains('skirt')) return Colors.pinkAccent;
      if (key.contains('short')) return Colors.deepOrangeAccent;
      
      // Footwear (Vibrant Text Colors for Dark Theme)
      if (key.contains('heel') || key.contains('pump') || key.contains('stiletto')) return Colors.pinkAccent; 
      if (key.contains('boot')) return Colors.orangeAccent;
      if (key.contains('sneaker') || key.contains('shoe')) return Colors.limeAccent;
      if (key.contains('sandal') || key.contains('flat')) return Colors.cyanAccent;
      
      // Default
      return Colors.grey.shade400; 
  }

  Widget _buildDrawerOption(String label, Color color, VoidCallback onTap) {
    // Determine text color based on background luminance
    // If background is very dark, use Amber/Gold for premium look, otherwise White.
    Color textColor = Colors.white;
    if (color.computeLuminance() < 0.15) { // < 0.15 essentially catches Black and very deep shades
       textColor = Colors.amberAccent; 
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: color,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: RotatedBox(
          quarterTurns: 3, // Vertical 270 degrees
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11), // Dynamic text color
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible, 
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryIcon() {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.history, color: Colors.white, size: 24),
      onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("History Feature Coming Soon!")));
      },
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
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // Added
  final VoidCallback? onShare;  // Added
  final Widget? overlay;

  const _SelectionCard({
    required this.title,
    required this.imagePath,
    this.message,
    this.onTap,
    this.onDelete, // Modified
    this.onShare,  // Modified
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
                    ? Image.network(
                        imagePath!, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                      )
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

            // Delete Button (Check if onDelete provided)
            if (onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, color: Colors.white, size: 16),
                  ),
                ),
              ),

          ], // Added missing closing bracket
        ),
      ),
    );
  }
}

class _ImagePickerSheet extends ConsumerWidget {
  final bool isTop;
  final bool isLayer; // New param
  final Function(String) onSelect;

  const _ImagePickerSheet({required this.isTop, this.isLayer = false, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(wardrobeApiProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      height: 500,
      child: Column(
        children: [
          Text('Select ${isTop ? "Top" : "Bottom"}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: imagesAsync.when(
              data: (items) {
                final filtered = items.where((item) {
                  // Basic filtering by general category logic from API items
                  if (isTop) {
                      // If it's a specific Layer slot, filter for jackets/layers
                      if (isLayer) {
                         final c = item.customCategory.toLowerCase();
                         return c.contains('jacket') || c.contains('layer') || c.contains('coat') || c.contains('blazer') || c.contains('cardigan') || c.contains('shrug');
                      }
                      return item.generalCategory.toLowerCase() == 'top';
                  }
                  return item.generalCategory.toLowerCase() == 'bottom' || item.generalCategory.toLowerCase().contains('pants');
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
                    final item = filtered[index];
                    return GestureDetector(
                      onTap: () => onSelect(item.imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                            item.imageUrl, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24),
                        ),
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


class _BentoTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool showLargeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BentoTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSelected = false,
    this.showLargeIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    // Defines the glow/border color. If selected, use the color itself fully bright.
    // If not selected, it's dimmed.
    final borderColor = isSelected ? color : color.withOpacity(0.5);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        // Use opaque scaffold background when selected to block the shadow from showing "inside"
        // This creates the "Border Glow Only" effect.
        color: isSelected ? Theme.of(context).scaffoldBackgroundColor : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20), // Pill shape for compact text
        border: Border.all(
          color: borderColor, 
          width: isSelected ? 2.0 : 1.0, 
        ),
        boxShadow: isSelected ? [
          // Outer glow only
          BoxShadow(
            color: color.withOpacity(0.8), // Stronger glow color
            blurRadius: 8,
            spreadRadius: 0, // Keep it tight to the border
          ),
          BoxShadow(
            color: color.withOpacity(0.4), // Ambient glow
            blurRadius: 16,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Compact padding
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
          ),
        ),
      ),
    );
  }
}
