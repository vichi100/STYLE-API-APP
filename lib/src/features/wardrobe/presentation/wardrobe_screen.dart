import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:style_advisor/src/features/camera/presentation/fashion_camera_screen.dart';
import 'package:style_advisor/src/utils/image_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:style_advisor/src/features/auth/presentation/user_provider.dart';
import 'package:style_advisor/src/features/auth/domain/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'upload_provider.dart';
import 'upload_status_widget.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<File> _uploadedImages = [];
  List<Map<String, dynamic>> _serverImages = []; // Stores {id, url}
  dynamic _highlightedItem;
  bool _isLoading = true;
  late AnimationController _animationController;
  
  // Selection State
  bool _isSelectionMode = false;
  bool _isPickingImage = false; // Separate state for OS-level gap
  final Set<String> _selectedServerIds = {};
  final Set<File> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWardrobeItems();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWardrobeItems() async {
    final user = ref.read(userProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final dio = Dio();

    try {
      final response = await dio.post(
        '$baseUrl/wardrobe/items',
        data: {
          'user_id': user.id,
          'mobile': user.mobile,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        debugPrint("Wardrobe Data: $data");

        if (mounted) {
          setState(() {
            final imageBaseUrl = dotenv.env['IMAGE_BASE_URL']?.trim() ?? '';
            _serverImages = data.map((item) {
              if (item is Map<String, dynamic>) {
                 final relativeUrl = item['image_url'] as String? ?? '';
                 final fullUrl = "$imageBaseUrl$relativeUrl";
                 final id = item['image_id']?.toString() ?? item['\$id']?.toString() ?? ''; // Fallback ID
                 debugPrint("Constructed URL: $fullUrl, ID: $id");
                 return {'id': id, 'url': fullUrl};
              }
              return {'id': 'unknown', 'url': item.toString()};
            }).toList().cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }




      } else {
        if (mounted) setState(() => _isLoading = false);
        debugPrint("Failed to fetch wardrobe items: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching wardrobe items: $e");
    }
  }



  Future<void> _uploadImage(File file, {bool silent = false}) async {
    final user = ref.read(userProvider);
    if (user == null) {
      debugPrint("No user found.");
      return;
    }

    try {
      final dio = Dio();
      // ... (Dio Setup)
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
        "user_id": user.id,
        "mobile": user.mobile,
      });

      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      final response = await dio.post(
        '$baseUrl/garments/upload-garment',
        data: formData,
      );

      if (response.statusCode == 200) {
         if (mounted) {
           setState(() {
             _uploadedImages.add(file);
             _highlightedItem = file; // Trigger highlight
           });

           if (!silent) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Upload complete! Added to wardrobe.', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xFF1E1E1E),
              ),
             );
           }

           // Remove highlight after 2 seconds
           Future.delayed(const Duration(seconds: 2), () {
             if (mounted) {
               setState(() {
                 _highlightedItem = null;
               });
             }
           });
         }
      } else {
        if (mounted && !silent) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${response.statusMessage}', style: const TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF1E1E1E),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint("API Error: $e");
      if (mounted && !silent) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error connecting to server', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF1E1E1E),
          ),
        );
      }
    }
  }

  Future<void> _processPickedFile(XFile? rawImage, {bool silent = false}) async {
     try {
      if (rawImage != null) {
        final File rawFile = File(rawImage.path);
        // ignore: avoid_print
        print("Original Wardrobe Image Size: ${(await rawFile.length()) / 1024} KB");

        // Compress using ImageHelper optimized for garments
        final File compressedFile = await ImageHelper.processImage(
          rawFile,
          type: ImageType.garment,
        );

        if (mounted) {
          // Upload to API
          await _uploadImage(compressedFile, silent: silent);

          // ignore: avoid_print
          print("Compressed Wardrobe Image Size: ${(await compressedFile.length()) / 1024} KB");
          // ignore: avoid_print
          print("New Wardrobe Item Path: ${compressedFile.path}");
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
  }

  Widget _buildDeepDiveEffect(Widget child) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(2), // Slim border
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: 3.14 * 2,
              colors: const [
                Colors.blue,
                Colors.red,
                Colors.yellow,
                Colors.green,
                Colors.blue,
              ],
              transform: GradientRotation(_animationController.value * 6.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3 + 0.2 * _animationController.value),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }



  Future<void> _pickImage(ImageSource source) async {
    // Debounce: Prevent double-taps while picker is opening
    if (_isPickingImage) return;

    try {
      if (source == ImageSource.camera) {
         final XFile? image = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FashionCameraScreen()),
        );
        _processPickedFile(image);
      } else {
        // Gallery - Allow Multi-Select
        
        // Show Spinner IMMEDIATELY to bridge OS gap
        setState(() {
          _isPickingImage = true;
        });

        final List<XFile> images;
        try {
           images = await _picker.pickMultiImage();
        } finally {
           // Hide spinner as soon as OS returns
           if (mounted) {
             setState(() {
               _isPickingImage = false;
             });
           }
        }
        
        if (images.isEmpty) return;

        // Show Initial Progress (Persistent SnackBar) - Show IMMEDIATELY
        if (mounted && ref.read(currentTabProvider) == 3) {
           ref.read(isUploadingProvider.notifier).state = true;
           ref.read(uploadProgressProvider.notifier).state = "Processing ${images.length} items...";

           ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Force instant show
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: _buildDeepDiveEffect(const UploadStatusWidget()),
               backgroundColor: Colors.transparent,
               elevation: 0,
               duration: const Duration(minutes: 5), // Keep open until manually hidden
               behavior: SnackBarBehavior.floating, 
               margin: const EdgeInsets.only(bottom: 5, left: 0, right: 0),
               padding: EdgeInsets.zero, 
             ),
           );
        } else {
           if (mounted) ref.read(isUploadingProvider.notifier).state = true;
        }

        // Check Network Status (Background)
        final connectivityResult = await Connectivity().checkConnectivity();
        final bool isFastNetwork = connectivityResult.contains(ConnectivityResult.wifi) || 
                                   connectivityResult.contains(ConnectivityResult.ethernet);

        int count = 0;
        final int total = images.length;
        
        // Lightweight update function (Only updates State)
        void updateProgress(int completed) {
           ref.read(uploadProgressProvider.notifier).state = 'Uploading $completed of $total...';
        }

        try {
          if (isFastNetwork) {
            // Turbo Mode: Safe Parallelism (Batched)
            // Processing too many images at once can crash the app (OOM) or choke bandwidth.
            // We process in batches of 4 to balance Speed vs Stability.
            const int batchSize = 4;
            for (var i = 0; i < images.length; i += batchSize) {
              final end = (i + batchSize < images.length) ? i + batchSize : images.length;
              final batch = images.sublist(i, end);
              
              // Upload this batch in parallel, then wait for them to finish before starting next batch
              await Future.wait(batch.map((image) async {
                await _processPickedFile(image, silent: true);
                count++;
                updateProgress(count);
              }));
            }
          } else {
            // Sequential Uploads (Slow Network)
            for (final image in images) {
               await _processPickedFile(image, silent: true);
               count++;
               updateProgress(count);
            }
          }
        } finally {
          // Reset Provider
          if (mounted) {
            ref.read(isUploadingProvider.notifier).state = false;
            ref.read(uploadProgressProvider.notifier).state = null;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            // Show Success Message
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 backgroundColor: const Color(0xFF1E1E1E), 
                 content: Text('${images.length} items uploaded successfully!', style: const TextStyle(color: Colors.white)),
                 behavior: SnackBarBehavior.floating,
               ),
             );
          }
        }
      } // Close ELSE block
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }




  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take Photo (Silhouette Mode)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(dynamic item) {
    setState(() {
      if (item is File) {
        if (_selectedFiles.contains(item)) {
          _selectedFiles.remove(item);
        } else {
          _selectedFiles.add(item);
        }
      } else if (item is Map) {
        debugPrint("TOGGLE: Server Item selected: $item");
        final id = item['id'] as String;
        if (_selectedServerIds.contains(id)) {
          _selectedServerIds.remove(id);
        } else {
          _selectedServerIds.add(id);
        }
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    debugPrint("DELETE: Starting delete process...");
    final int count = _selectedFiles.length + _selectedServerIds.length;
    if (count == 0) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Items?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete $count items?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistic Update
    final List<File> filesToRemove = _selectedFiles.toList();
    final List<String> idsToRemove = _selectedServerIds.toList();

    setState(() {
      _uploadedImages.removeWhere((file) => filesToRemove.contains(file));
      _serverImages.removeWhere((item) => idsToRemove.contains(item['id']));
      
      _selectedFiles.clear();
      _selectedServerIds.clear();
      _isSelectionMode = false;
    });

    // API Call to remove server items
    if (idsToRemove.isNotEmpty) {
      final user = ref.read(userProvider);
      if (user != null) {
        try {
          final dio = Dio();
          final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
          
          debugPrint("Deleting IDs: $idsToRemove");
          final requestData = {
              'user_id': user.id,
              'mobile': user.mobile,
              'item_ids': idsToRemove,
          };
          debugPrint("Request Body: $requestData");

          await dio.post(
            '$baseUrl/wardrobe/remove',
            data: requestData,
          );
          debugPrint("Deleted ${idsToRemove.length} items from server.");
        } catch (e) {
          debugPrint("Delete API failed: $e");
          // Revert or Sync
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to sync delete with server. Refreshing...', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xFF1E1E1E),
              ),
             );
             _fetchWardrobeItems(); 
          }
           return;
        }
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected items deleted.', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-fetch logic: Listen for login or first load
    ref.listen<User?>(userProvider, (previous, next) {
      if (next != null && (previous == null || next.id != previous.id)) {
        debugPrint("User logged in/switched. Fetching wardrobe...");
        // Reset loading state if needed to show spinner? Or just fetch silently/overlay?
        // Let's set loading to true to show spinner.
        setState(() => _isLoading = true);
        _fetchWardrobeItems();
      }
    });

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    
    final allImages = [..._uploadedImages, ..._serverImages];
    final user = ref.read(userProvider);
    
    // Reactive: Restore SnackBar if returning to Wardrobe while uploading
    ref.listen(currentTabProvider, (previous, next) {
      if (next == 3 && ref.read(isUploadingProvider)) {
        final progressText = ref.read(uploadProgressProvider);
        if (progressText != null) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               backgroundColor: Colors.transparent, 
               elevation: 0,
               behavior: SnackBarBehavior.floating,
               margin: const EdgeInsets.only(bottom: 5, left: 0, right: 0),
               padding: EdgeInsets.zero,
               content: _buildDeepDiveEffect(
                 Row(
                   children: [
                     const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Text(
                         progressText,
                         style: const TextStyle(color: Colors.white, fontSize: 16),
                       ),
                     ),
                   ],
                 ),
               ),
               duration: const Duration(minutes: 1), 
             ),
           );
        }
      } else if (next != 3) {
        // Explicitly hide if leaving tab
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });

    // Combine lists: uploaded first, then server


    // Combine lists: uploaded first, then server
    
    final scaffold = Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _isSelectionMode ? Icons.close : Icons.edit,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              if (_isSelectionMode) {
                 _isSelectionMode = false;
                 _selectedFiles.clear();
                 _selectedServerIds.clear();
              } else {
                _isSelectionMode = true;
              }
            });
          },
        ),
        title: const Text(
          'Wardrobe',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal),
        ),
        actions: [
          if (_isSelectionMode && (_selectedFiles.isNotEmpty || _selectedServerIds.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteSelectedItems,
            )
          else
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: () => _showImageSourceModal(context),
            ),
        ],
      ),
      body: allImages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.checkroom, size: 60, color: Colors.white24),
                   const SizedBox(height: 16),
                   const Text(
                     "Your wardrobe is empty.",
                     style: TextStyle(color: Colors.white54, fontSize: 16),
                   ),
                   const SizedBox(height: 8),
                   ElevatedButton.icon(
                     onPressed: () => _pickImage(ImageSource.gallery),
                     icon: const Icon(Icons.add),
                     label: const Text("Add First Item"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white24,
                       foregroundColor: Colors.white,
                     ),
                   )
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final imageItem = allImages[index];
                
                final bool isSelected = (imageItem is File && _selectedFiles.contains(imageItem)) ||
                                        (imageItem is Map && _selectedServerIds.contains(imageItem['id']));

                // Debug log to confirm builder execution
                debugPrint("BUILDER: Item $index, Type: ${imageItem.runtimeType}");
                
                final imageWidget = Builder(
                  builder: (context) {
                    try {
                      if (imageItem is File) {
                        return Image.file(
                          imageItem,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                             return Container(color: Colors.grey[900], child: const Icon(Icons.error));
                          },
                        );
                      } else {
                         // Explicitly debug the item before casting
                         // debugPrint("BUILDER_INNER: Processing map item: $imageItem");
                         final itemMap = imageItem as Map; // removed strict generic for safety
                         final url = itemMap['url']?.toString() ?? '';
                         
                         debugPrint("BUILDER_INNER: Creating DioNetworkImage for $url");
                         
                         return DioNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error) {
                            debugPrint("!!! DIO IMAGE ERROR [$url] !!! : $error");
                            return Container(color: Colors.grey[900], child: const Icon(Icons.broken_image));
                          },
                        );
                      }
                    } catch (e, stack) {
                      debugPrint("BUILDER_CRASH: $e");
                      debugPrint(stack.toString());
                      return Container(color: Colors.red, child: Text("Error: $e"));
                    }
                  }
                );



                // Highlight Logic for New Uploads
                final isHighlighted = (imageItem is File) && (imageItem == _highlightedItem);

                Widget content;
                
                if (isHighlighted) {
                   content = AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                         margin: const EdgeInsets.all(4), // Match Default Card Margin
                         padding: const EdgeInsets.all(1.5), 
                         decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: SweepGradient(
                            center: Alignment.center,
                            startAngle: 0,
                            endAngle: 3.14 * 2,
                            colors: const [
                              Colors.blue,
                              Colors.red,
                              Colors.yellow,
                              Colors.green,
                              Colors.blue,
                            ],
                            transform: GradientRotation(_animationController.value * 6.28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3 + 0.2 * _animationController.value),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.5),
                          child: imageWidget,
                        ),
                      );
                    },
                  );
                } else {
                   content = Card(
                     clipBehavior: Clip.antiAlias,
                     elevation: 2,
                     margin: const EdgeInsets.all(4), // Consistent margin
                     child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageWidget,
                         if (_isSelectionMode)
                          Container(
                            color: isSelected ? Colors.black45 : Colors.transparent,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.blueAccent : Colors.white,
                            ),
                          ),
                      ],
                     ),
                   );
                }
                
                return GestureDetector(
                   onTap: _isSelectionMode ? () => _toggleSelection(imageItem) : null,
                   onLongPress: _isSelectionMode ? null : () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54, // Dim background
                        builder: (context) => BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Image Card
                                Container(
                                  // Removed white decoration and padding
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imageItem is File 
                                      ? Image.file(imageItem, fit: BoxFit.contain)
                                      : DioNetworkImage(
                                          imageUrl: (imageItem as Map<String, dynamic>)['url'], 
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error) => const Icon(Icons.error),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Options Menu
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E), // Dark Theme Background
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                         Navigator.pop(context); // Close dialog
                                         // Share Logic
                                         if (imageItem is File) {
                                            Share.shareXFiles([XFile(imageItem.path)], text: 'Check out this item from my wardrobe!');
                                         } else if (imageItem is Map) {
                                            final url = (imageItem)['url'];
                                            Share.share('Check out this item: $url');
                                         }
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Share",
                                              style: TextStyle(
                                                fontSize: 16, 
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white // White Text
                                              ),
                                            ),
                                            Icon(Icons.ios_share, color: Colors.white), // White Icon
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                ],
                              ),
                            ),
                          ),
                        );
                   },
                   child: content,
                );
              },
            ),
    );

    return Stack(
      children: [
        scaffold,
        // Loading Overlay for "Copying..." Phase
        if (_isPickingImage)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   CircularProgressIndicator(color: Colors.white),
                   SizedBox(height: 16),
                   Text("Preparing Gallery...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class DioNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext, Object)? errorBuilder;

  const DioNetworkImage({required this.imageUrl, this.fit = BoxFit.cover, this.errorBuilder, super.key});

  @override
  State<DioNetworkImage> createState() => _DioNetworkImageState();
}

class _DioNetworkImageState extends State<DioNetworkImage> {
  late Future<Response> _imageFuture; // Removed strict generic

  @override
  void initState() {
    super.initState();
    debugPrint("DIO_INIT: Requesting ${widget.imageUrl}");
    _imageFuture = Dio().get(
      widget.imageUrl, 
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant DioNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      debugPrint("DIO_UPDATE: Url changed to ${widget.imageUrl}");
       _imageFuture = Dio().get(
        widget.imageUrl, 
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Response>( // Removed strict generic
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data == null) {
           debugPrint("DIO_ERROR [${widget.imageUrl}]: ${snapshot.error}");
           if (widget.errorBuilder != null) return widget.errorBuilder!(context, snapshot.error ?? "Unknown Error");
           return const Icon(Icons.error, color: Colors.red);
        }
        
        try {
          final data = snapshot.data!.data;
          // Robust casting to Uint8List
          List<int> bytes;
          if (data is List<int>) {
            bytes = data;
          } else if (data is List) {
            bytes = data.cast<int>();
          } else {
            throw Exception("Invalid data type: ${data.runtimeType}");
          }
          
          return Image.memory(
             Uint8List.fromList(bytes),
             fit: widget.fit,
          );
        } catch (e) {
          debugPrint("DIO_PARSE_ERROR: $e");
          return const Icon(Icons.broken_image, color: Colors.orange);
        }
      },
    );
  }
}
