import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf_to_images/views/image_view.dart';
import 'package:pdfx/pdfx.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Uint8List> _images = [];
  String? selectedFileName;
  String? filePath;
  bool isLoading = false;

  void _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          selectedFileName = result.files.single.name;
          filePath = result.files.single.path;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  void _removePdf() {
    setState(() {
      selectedFileName = null;
      filePath = null;
    });
  }

  Future<void> _convertPdf(String path) async {
    if (selectedFileName != null) {
      setState(() {
        isLoading = true;
        _images.clear();
      });

      try {
        final pdfDocument = await PdfDocument.openFile(path);
        final pageCount = pdfDocument.pagesCount;
        List<Uint8List> images = [];

        for (int i = 1; i <= pageCount; i++) {
          final page = await pdfDocument.getPage(i);
          final pageImage = await page.render(
            width: page.width,
            height: page.height,
            format: PdfPageImageFormat.png,
          );
          images.add(pageImage!.bytes);
          await page.close();
        }

        setState(() {
          _images = images;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageGridScreen(images: _images),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF conversion completed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting PDF: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    print('Back button pressed');
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit App'),
        content: Text('Do you really want to exit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Do not exit
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Exit the app
            },
            child: Text('Exit'),
          ),
        ],
      ),
    );

    print('Dialog result: $shouldExit');
    return shouldExit ?? false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(
            'PDF to Image',
            style: GoogleFonts.roboto(
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.left,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  DottedBorder(
                    color: Colors.grey,
                    strokeWidth: 2,
                    dashPattern: [5, 5],
                    child: Container(
                      width: double.infinity,
                      height: 350,
                      child: Center(
                        child: selectedFileName == null
                            ? ElevatedButton(
                                onPressed: _pickPdf,
                                style: ElevatedButton.styleFrom(
                                  shadowColor:
                                      const Color.fromARGB(255, 98, 125, 172),
                                  backgroundColor:
                                      const Color.fromARGB(255, 157, 174, 204),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Select PDF",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        selectedFileName!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.black),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.clear, color: Colors.red),
                                        onPressed: _removePdf,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  isLoading
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton(
                                          onPressed: () {
                                            _convertPdf(filePath!);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shadowColor: const Color.fromARGB(
                                                255, 98, 125, 172),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 157, 174, 204),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            "Convert",
                                            style: GoogleFonts.roboto(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Your files are secure",
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                  const Spacer(),
                  const Text(
                    "@copyright pinch",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
