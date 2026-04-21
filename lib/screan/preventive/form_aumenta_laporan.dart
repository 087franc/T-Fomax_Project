import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class StartPatroliPage extends StatefulWidget {
  const StartPatroliPage({super.key});

  @override
  State<StartPatroliPage> createState() => _StartPatroliPageState();
}

class _StartPatroliPageState extends State<StartPatroliPage> {
  // 1. DADUS USER HUSI JSON
  final String userDataJson =
      '{"id": "001", "name": "Marcos de Deus", "role": "Field Technician"}';
  late Map<String, dynamic> user;

  final TextEditingController _keteranganController = TextEditingController();
  String? _selectedKategori;

  // VARIABLE HODI RAI OPSIAUN SIM/NAO
  String _isBlankSpot = "Não";
  String _needEscalation = "Não";

  File? _imageFile;
  String _currentAddress = "Klika hodi foti lokasaun";

  final List<String> _kategoriList = [
    "Check Fiber Optic",
    "Check ODP/ODC",
    "Pole Maintenance",
    "Cleaning Site",
  ];

  @override
  void initState() {
    super.initState();
    user = jsonDecode(userDataJson);
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (photo != null) setState(() => _imageFile = File(photo.path));
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS di HP menyala
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Layanan lokasi (GPS) dimatikan.');
      return;
    }

    // 2. Cek status izin saat ini
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Minta izin ke user
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('User menolak izin lokasi.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // User menolak permanen (Don't ask again)
      print('Izin ditolak permanen. Buka Settings untuk mengaktifkan.');
      return;
    }

    // 3. Jika semua oke, baru ambil posisi
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentAddress =
          "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("HAHU PATROLI"),
        backgroundColor: const Color(0xFFED1C24),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER DISPLAY
            _buildUserHeader(),
            const SizedBox(height: 25),

            // KATEGORIA
            _buildLabel("Kategori Atividade (*)"),
            DropdownButtonFormField<String>(
              hint: const Text("Hili Kategoria"),
              value: _selectedKategori,
              decoration: _inputStyle(),
              items: _kategoriList
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedKategori = val),
            ),
            const SizedBox(height: 20),

            // KETERANGAN
            _buildLabel("Deskrisaun Atividade (*)"),
            TextField(
              controller: _keteranganController,
              maxLines: 3,
              decoration: _inputStyle(hint: "Hakerek detalhe servisu..."),
            ),
            const SizedBox(height: 20),

            // --- SEKSIUN RADIO BUTTON (SIM / NAO) ---
            _buildLabel("Iha Fatin Mamuk? (*)"),
            _buildRadioOptions(
              currentValue: _isBlankSpot,
              onChanged: (val) => setState(() => _isBlankSpot = val!),
            ),
            const Divider(),

            _buildLabel("Servisu sira Presija Eskalasaun? (*)"),
            _buildRadioOptions(
              currentValue: _needEscalation,
              onChanged: (val) => setState(() => _needEscalation = val!),
            ),
            const Divider(),
            const SizedBox(height: 10),

            // FOTO
            _buildLabel("Foti Foto (*)"),
            _buildPhotoBox(),
            const SizedBox(height: 20),

            // LOKASAUN
            _buildLabel("Lokasi GPS (*)"),
            _buildLocationTile(),

            const SizedBox(height: 35),

            // BUTAUN SUBMETE
            _buildSubmitButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // WIDGET HODI Kria OPSIAUN SIM / NAO (RADIO)
  Widget _buildRadioOptions({
    required String currentValue,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text("Sim"),
            value: "Sim",
            // ignore: deprecated_member_use
            groupValue: currentValue,
            activeColor: const Color(0xFFED1C24),
            // ignore: deprecated_member_use
            onChanged: onChanged,
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text("Não"),
            value: "Não",
            // ignore: deprecated_member_use
            groupValue: currentValue,
            activeColor: const Color(0xFFED1C24),
            // ignore: deprecated_member_use
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // HELPER WIDGETS
  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle, size: 40, color: Color(0xFFED1C24)),
          const SizedBox(width: 12),
          Text(
            user['name'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputStyle({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildPhotoBox() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildLocationTile() {
    return ListTile(
      tileColor: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      leading: const Icon(Icons.my_location, color: Colors.blue),
      title: Text(_currentAddress, style: const TextStyle(fontSize: 13)),
      trailing: TextButton(onPressed: _getLocation, child: const Text("FOTI")),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED1C24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // HARUKA DADUS BA GOLANG
          print("Blank Spot: $_isBlankSpot, Eskalasi: $_needEscalation");
          _showSuccess();
        },
        child: const Text(
          "SUBMETE PATROLI",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Relatóriu Susesu Envia!"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
