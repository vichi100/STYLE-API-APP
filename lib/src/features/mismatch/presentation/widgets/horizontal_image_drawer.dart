import 'package:flutter/material.dart';

class HorizontalImageDrawer extends StatelessWidget {
  final List<String> images;
  final String? selectedPath;
  final ValueChanged<String> onSelect;
  final String title;

  const HorizontalImageDrawer({
    super.key,
    required this.images,
    required this.selectedPath,
    required this.onSelect,
    this.title = 'Quick Select Tops',
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No items found')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
           Text(
            title,
             style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          SizedBox(
            height: 80, // Fixed height for the image strip
            child: ListView.builder( 
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final path = images[index];
                final isSelected = selectedPath == path;
                
                return GestureDetector(
                  onTap: () => onSelect(path),
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
                        )
                      ] : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        path, 
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
