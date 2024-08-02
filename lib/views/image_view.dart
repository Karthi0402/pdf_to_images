import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ImageGridScreen extends StatefulWidget {
  final List<Uint8List> images;

  const ImageGridScreen({Key? key, required this.images}) : super(key: key);

  @override
  _ImageGridScreenState createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends State<ImageGridScreen> {
  int? fullScreenImageIndex; // Store index of the image in full screen mode

  void _onImageTap(int index) {
    setState(() {
      fullScreenImageIndex = index; // Show the tapped image in full screen
    });
  }

  Future<void> _shareAllImages() async {
    if (widget.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images to share')),
      );
      return;
    }

    List<XFile> xFiles = [];
    final tempDir = await getTemporaryDirectory();

    for (int i = 0; i < widget.images.length; i++) {
      final bytes = widget.images[i];
      final imagePath = '${tempDir.path}/image_$i.png';
      final file = File(imagePath);
      await file.writeAsBytes(bytes);
      xFiles.add(XFile(imagePath));
    }

    final result =
        await Share.shareXFiles(xFiles, text: 'Check out these images!');

    if (result.status == ShareResultStatus.success) {
      print('Thank you for sharing the images!');
    } else if (result.status == ShareResultStatus.dismissed) {
      print('Sharing was dismissed');
    } else if (result.status == ShareResultStatus.unavailable) {
      print('Sharing is unavailable');
    }
  }

  Future<void> _saveAllImages() async {
    if (widget.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images to save')),
      );
      return;
    }

    try {
      for (int i = 0; i < widget.images.length; i++) {
        final bytes = widget.images[i];
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_image_$i.png');
        await tempFile.writeAsBytes(bytes);

        final result = await GallerySaver.saveImage(tempFile.path);
        if (result != true) {
          throw Exception('Failed to save image $i');
        }

        await tempFile.delete(); // Clean up the temporary file
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All images saved to gallery')),
      );
    } catch (e) {
      print("Error saving images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving images: $e')),
      );
    }
  }

  void _closeFullScreenImage() {
    setState(() {
      fullScreenImageIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Gallery',
          style: GoogleFonts.roboto(
            color: Colors.black,
          ),
        ),
      ),
      body: fullScreenImageIndex == null
          ? GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onImageTap(index),
                  child: Container(
                    color: Colors.grey[200],
                    child:
                        Image.memory(widget.images[index], fit: BoxFit.cover),
                  ),
                );
              },
            )
          : GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 10) {
                  // Swipe down
                  _closeFullScreenImage();
                }
              },
              child: PageView.builder(
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(widget.images[index], fit: BoxFit.contain),
                      Positioned(
                        top: 20,
                        left: 10,
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 30),
                          onPressed: _closeFullScreenImage,
                        ),
                      ),
                    ],
                  );
                },
                scrollDirection: Axis.horizontal,
                onPageChanged: (index) {
                  setState(() {
                    fullScreenImageIndex = index;
                  });
                },
              ),
            ),
      bottomNavigationBar: fullScreenImageIndex == null
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.save_alt),
                    onPressed: _saveAllImages,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareAllImages,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
