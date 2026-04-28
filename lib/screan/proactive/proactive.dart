import 'dart:io'; // Atu jere file foto
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import library foun

class TambahProactivePage extends StatefulWidget {
  const TambahProactivePage({super.key});

  @override
  State<TambahProactivePage> createState() => _TambahProactivePageState();
}

class _TambahProactivePageState extends State<TambahProactivePage> {
  final TextEditingController _deskripsiController = TextEditingController();

  // File hodi rai foto ne'ebé hasai
  File? _imageFile;

  // Funsaun hodi loke Kamera
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      // Loke Kamera (muda ba ImageSource.gallery se hakarak loke galeria)
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Haktuik kualidade atu file labele boot liu
      );

      if (pickedFile != null) {
        // Se hasai duni foto, rai ba variable _imageFile
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Erru loke kamera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Formulario Proactive",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Deskrisaun Proactive",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Foto Attachment Proactive",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // KAISA FOTO (InkWell deteta klik)
            InkWell(
              onTap: _pickImage, // Loke funsaun kamera
              child: Container(
                width: 180,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  // Clip atu imajen tuir kantu kaisa nian
                  borderRadius: BorderRadius.circular(12),
                  child: _imageFile != null
                      // SE IHA FOTO: Hatudu foto ne'ebé hasai ona
                      ? Image.file(
                          _imageFile!,
                          fit: BoxFit.cover, // Halo foto fit iha kaisa boot
                        )
                      // SE SEIDAUK IHA FOTO: Hatudu íkone "+" hanesan uluk
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 80, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              "Aumenta Foun\nFoto Attachment\nProactive",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 50),
            // Butaun SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B0000), Color(0xFFFF0000)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Check se dadus kompletu
                    if (_deskripsiController.text.isEmpty ||
                        _imageFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Favor hatama deskrisaun no foto"),
                        ),
                      );
                      return;
                    }
                    // Lójika hodi simpan dadus (haruka ba backend)
                    print(
                      "Simpan: ${_deskripsiController.text}, Foto: ${_imageFile!.path}",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Submete Proactive",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
