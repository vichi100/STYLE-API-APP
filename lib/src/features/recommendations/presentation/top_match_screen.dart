import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../wardrobe/application/wardrobe_images_provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class TopMatchScreen extends ConsumerStatefulWidget {
  const TopMatchScreen({super.key});

  @override
  ConsumerState<TopMatchScreen> createState() => _TopMatchScreenState();
}

class _TopMatchScreenState extends ConsumerState<TopMatchScreen> {
  // Track the selected category. Default could be null or the first one.
  String? _selectedCategory = 'Casual'; 
  final ScrollController _thumbController = ScrollController();
  final CardSwiperController _swiperController = CardSwiperController();
  
  // Sync state for CardSwiper and Thumbnails
  int _highlightIndex = 0; // The actual visible image index in the full list

  @override
  void dispose() {
    _thumbController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the image provider
    final imagesAsync = ref.watch(wardrobeImagesProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        centerTitle: true,
        title: const Text(
          'Top Matches',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: Column(
          children: [
            // Swipeable Image Carousel Area
            Expanded(
              child: imagesAsync.when(
                data: (images) {
                  if (images.isEmpty) {
                    return const Center(child: Text('No wardrobe images found'));
                  }
                  
                  return CardSwiper(
                    controller: _swiperController,
                    cardsCount: images.length,
                    numberOfCardsDisplayed: 1, // Only show the top card, hiding the "deck"
                    backCardOffset: const Offset(0, 0), // No offset needed if only 1 is shown
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    onSwipe: (previousIndex, currentIndex, direction) {
                      setState(() {
                        if (currentIndex != null) {
                           _highlightIndex = currentIndex;
                        }
                      });
                      return true;
                    },
                    cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: DecorationImage(
                            image: AssetImage(images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
            
            // Thumbnail Strip with Navigation
            Container(
              margin: const EdgeInsets.only(top: 0), // Closer to deck
              height: 25,
              child: imagesAsync.when(
                data: (images) {
                  if (images.isEmpty) return const SizedBox();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left Arrow
                      InkWell(
                        onTap: () {
                          _thumbController.animateTo(
                            (_thumbController.offset - 100).clamp(0.0, _thumbController.position.maxScrollExtent),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Icon(Icons.chevron_left, color: Colors.white.withOpacity(0.7), size: 20),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Centered List (5 items visible approx 120px)
                      SizedBox(
                        width: 120, 
                        child: ListView.builder(
                          controller: _thumbController,
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final isSelected = _highlightIndex == index;
                            return GestureDetector(
                              onTap: () {
                                _swiperController.moveTo(index);
                                setState(() {
                                  _highlightIndex = index;
                                });
                              },
                              child: Container(
                                width: 20, // Tiny thumbnails
                                margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.2), 
                                      width: isSelected ? 2.0 : 0.5,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ] : [],
                                  image: DecorationImage(
                                    image: AssetImage(images[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 8),

                      // Right Arrow
                      InkWell(
                        onTap: () {
                           _thumbController.animateTo(
                            (_thumbController.offset + 100).clamp(0.0, _thumbController.position.maxScrollExtent),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7), size: 20),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (err, stack) => const SizedBox(),
              ),
            ),

            const SizedBox(height: 32), // Increased gap before Category

             // Mobile Bento Grid for Categories
             StaggeredGrid.count(
                crossAxisCount: 4, 
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  // Row 1
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 0.7,
                    child: _BentoTile(
                      label: 'Casual',
                      icon: Icons.weekend_outlined,
                      color: const Color(0xFF64B5F6),
                      isSelected: _selectedCategory == 'Casual',
                      onTap: () => _onCategorySelected('Casual'),
                    ),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 0.7,
                    child: _BentoTile(
                      label: 'Party',
                      icon: Icons.celebration_outlined,
                      color: const Color(0xFFFF1744), // Red Hot
                      isSelected: _selectedCategory == 'Party',
                      onTap: () => _onCategorySelected('Party'),
                    ),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 0.7,
                    child: _BentoTile(
                      label: 'Date Lunch',
                      icon: Icons.restaurant_outlined,
                      color: const Color(0xFFFFD54F),
                      isSelected: _selectedCategory == 'Date Lunch',
                      onTap: () => _onCategorySelected('Date Lunch'),
                    ),
                  ),
                  // Row 2
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 0.7,
                    child: _BentoTile(
                      label: 'Date Night',
                      icon: Icons.local_bar_outlined,
                      color: const Color(0xFFBA68C8),
                      isSelected: _selectedCategory == 'Date Night',
                      onTap: () => _onCategorySelected('Date Night'),
                    ),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 0.7,
                    child: _BentoTile(
                      label: 'Office',
                      icon: Icons.business_center_outlined,
                      color: const Color(0xFF81C784),
                      isSelected: _selectedCategory == 'Office',
                      onTap: () => _onCategorySelected('Office'),
                    ),
                  ),
                   StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 0.7,
                    child: _BentoTile(
                      label: 'Gym',
                      icon: Icons.fitness_center_outlined,
                      color: const Color(0xFFE57373),
                      isSelected: _selectedCategory == 'Gym',
                      onTap: () => _onCategorySelected('Gym'),
                    ),
                  ),
                ],
              ),
          ],
        ),
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
    final bgColor = isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        // Use opaque scaffold background when selected to block the shadow from showing "inside"
        // This creates the "Border Glow Only" effect.
        color: isSelected ? Theme.of(context).scaffoldBackgroundColor : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(3.0), // Minimal padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Hug content
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, color: color, size: showLargeIcon ? 24 : 16), // Tiny icons
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9, // Micro font
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null, 
                      height: 1.0, // Tight line height
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
