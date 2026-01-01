import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../wardrobe/application/wardrobe_images_provider.dart';
import 'widgets/horizontal_image_drawer.dart';

class MismatchScreen extends ConsumerStatefulWidget {
  const MismatchScreen({super.key});

  @override
  ConsumerState<MismatchScreen> createState() => _MismatchScreenState();
}

class _MismatchScreenState extends ConsumerState<MismatchScreen> {
  String? _selectedTop;
  String? _selectedBottom;
  String? _analysisResult;
  bool _isDrawerOpen = false;
  
  final ScrollController _thumbController = ScrollController();
  final ScrollController _bottomThumbController = ScrollController();

  @override
  void dispose() {
    _thumbController.dispose();
    _bottomThumbController.dispose();
    super.dispose();
  }

  void _analyze() {
    if (_selectedTop == null || _selectedBottom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a Top and a Bottom')),
      );
      return;
    }
    
    // Mock Analysis Logic
    setState(() {
      _analysisResult = "Looking good! \nNo mismatch detected."; 
    });
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
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _CategoryItem(
                  icon: FontAwesomeIcons.personDress,
                  label: 'Singles',
                  color: Colors.pinkAccent,
                  onTap: () => _onCategorySelected('Singles'),
                ),
                _CategoryItem(
                  icon: FontAwesomeIcons.gem, // Jewelry
                  label: 'Accessory',
                  color: Colors.amberAccent,
                  onTap: () => _onCategorySelected('Accessory'),
                ),
                _CategoryItem(
                  icon: FontAwesomeIcons.bagShopping,
                  label: 'Bag',
                  color: Colors.purpleAccent,
                  onTap: () => _onCategorySelected('Bag'),
                ),
                _CategoryItem(
                  icon: FontAwesomeIcons.vest, // Jacket approx
                  label: 'Jacket',
                  color: Colors.cyanAccent,
                  onTap: () => _onCategorySelected('Jacket'),
                ),
                _CategoryItem(
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
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category category selected'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImagePicker(bool isTop) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ImagePickerSheet(
        isTop: isTop,
        onSelect: (path) {
          setState(() {
            if (isTop) {
              _selectedTop = path;
            } else {
              _selectedBottom = path;
            }
            _analysisResult = null; // Reset analysis
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagesAsync = ref.watch(wardrobeImagesProvider);
    final drawerWidth = 100.0; // Not used for logic, but kept var

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mismatch Analysis'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategorySheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SelectionCard(
                          title: 'Top',
                          imagePath: _selectedTop,
                          message: _selectedTop == null ? 'Tap to select Top' : null,
                          onTap: () => _showImagePicker(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SelectionCard(
                          title: 'Bottom',
                          imagePath: _selectedBottom,
                          message: _selectedBottom == null ? 'Tap to select Bottom' : null,
                          onTap: () => _showImagePicker(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _analyze,
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Analyze Mismatch'),
                    ),
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
          
          // Drawer placed right above the bottom strips
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: _isDrawerOpen ? 160 : 0,
              width: double.infinity,
              child: _isDrawerOpen ? imagesAsync.when(
                data: (images) {
                  final topImages = images.where((path) => path.contains('/wtop/') || path.contains('wtop')).toList();
                  return HorizontalImageDrawer(
                    images: topImages,
                    selectedPath: _selectedTop,
                    onSelect: (path) {
                       setState(() {
                         _selectedTop = path;
                         _analysisResult = null;
                       });
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ) : const SizedBox.shrink(),
            ),
          ),

          // Bottom Image Strips (Pinned)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDrawerOpen = !_isDrawerOpen;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tops', // Changed from Quick Select Tops
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isDrawerOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                 imagesAsync.when(
                  data: (images) {
                    final topImages = images.where((path) => path.contains('/wtop/') || path.contains('wtop')).toList();
                    
                    if (topImages.isEmpty) {
                       return const SizedBox(
                        height: 60,
                        child: Center(child: Text('No tops found')),
                      );
                    }

                    return SizedBox(
                      height: 60,
                      child: ListView.builder(
                        controller: _thumbController,
                        scrollDirection: Axis.horizontal,
                        itemCount: topImages.length,
                        itemBuilder: (context, index) {
                          final path = topImages[index];
                          final isSelected = _selectedTop == path;
                          
                          return GestureDetector(
                            onTap: () {
                               setState(() {
                                 _selectedTop = path;
                                 _analysisResult = null;
                               });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.cyanAccent : Colors.transparent,
                                  width: isSelected ? 2.0 : 0.0,
                                ),
                                boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.6),
                                      blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ] : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.asset(path, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick Select Bottoms',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                imagesAsync.when(
                  data: (images) {
                    final bottomImages = images.where((path) => path.contains('/wbottom/') || path.contains('wbottom')).toList();
                    
                    if (bottomImages.isEmpty) {
                       return const SizedBox(
                        height: 60,
                        child: Center(child: Text('No bottoms found')),
                      );
                    }

                    return SizedBox(
                      height: 60,
                      child: ListView.builder(
                        controller: _bottomThumbController,
                        scrollDirection: Axis.horizontal,
                        itemCount: bottomImages.length,
                        itemBuilder: (context, index) {
                          final path = bottomImages[index];
                          final isSelected = _selectedBottom == path;
                          
                          return GestureDetector(
                            onTap: () {
                               setState(() {
                                 _selectedBottom = path;
                                 _analysisResult = null;
                               });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.cyanAccent : Colors.transparent,
                                  width: isSelected ? 2.0 : 0.0,
                                ),
                                boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.6),
                                      blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ] : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.asset(path, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
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

  const _SelectionCard({
    required this.title,
    required this.imagePath,
    this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
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
