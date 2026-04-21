import 'dart:async'; // 1. Tambahkan import ini
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  File? _imageFile;
  String _healthCondition = "Saudável";
  final TextEditingController _taskController = TextEditingController();
  Position? _currentPosition;

  // 2. Tambahkan variabel untuk Timer dan String waktu
  Timer? _timer;
  String _currentTime = "";

  bool get isMorning => DateTime.now().hour >= 8 && DateTime.now().hour < 11;
  bool get isEvening => DateTime.now().hour >= 17 && DateTime.now().hour < 21;

  @override
  void initState() {
    super.initState();
    // 3. Jalankan timer saat pertama kali buka halaman
    _startTimer();
  }

  // 4. Fungsi untuk menjalankan jam secara real-time
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Menggunakan 'HH' untuk memastikan format 24 jam (17, 20, dst)
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    // 5. Penting: Hentikan timer saat keluar dari halaman
    _timer?.cancel();
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _getHiddenLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    _currentPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (photo != null) setState(() => _imageFile = File(photo.path));
  }

  void _showSuccessDialog(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk Button agar kode lebih rapi
  Widget _buildButton(
    String label,
    Color color,
    bool enabled,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lista Presensa FIXOM"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Tampilan jam yang sekarang sudah otomatis update
            Text(
              _currentTime.isEmpty ? "..." : _currentTime,
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())),
            const SizedBox(height: 30),

            if (isMorning) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Kondisaun Saúde (*)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _healthCondition,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    [
                          "Saudável",
                          "Isin-manas",
                          "Me'ar",
                          "Inus-metin",
                          "Ulun-Moras",
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() => _healthCondition = val!),
              ),
              const SizedBox(height: 20),
            ],

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Hasai Foto Oin (*)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text("Klik hodi hasai foto"),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 25),

            if (isEvening) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Relatóriu Servisu Ohin (*)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _taskController,
                maxLines: 3,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Hakerek saida mak halo ona...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],

            // Logika Tombol
            if (isMorning)
              _buildButton("CLOCK IN", Colors.green, _imageFile != null, () {
                _showSuccessDialog(
                  "Susesu In",
                  "Ita-nia kondisaun: $_healthCondition. Servisu di'ak!",
                );
              })
            else if (isEvening)
              _buildButton(
                "CLOCK OUT",
                Colors.redAccent,
                (_imageFile != null && _taskController.text.isNotEmpty),
                () {
                  _showSuccessDialog(
                    "Susesu Out",
                    "Obrigadu ba ita-nia servisu ohin. Deskansa di'ak!",
                  );
                },
              )
            else
              const Text(
                "Ondu la'ós oras presensa",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
