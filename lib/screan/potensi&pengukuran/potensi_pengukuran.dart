import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PotensiPengukuranPage extends StatefulWidget {
  const PotensiPengukuranPage({super.key});

  @override
  State<PotensiPengukuranPage> createState() => _PotensiPengukuranPageState();
}

class _PotensiPengukuranPageState extends State<PotensiPengukuranPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  File? _capturedImage;
  String? _selectedMunisipio;
  String? _selectedType;
  Map<String, String>? _selectedSegment;
  final TextEditingController _dbmController = TextEditingController();

  // Lista Munisípiu Telkomcel nian
  final List<String> _munisipios = [
    "Dili",
    "Baucau",
    "Liquica",
    "Ermera",
    "Aileu",
    "Manufahi",
    "Viqueque",
    "Lospalos",
    "Bobonaro",
    "Covalima",
    "Ainaro",
    "Manatuto",
    "Oecusse",
  ];

  final List<String> _types = ["Backbone", "Seader", "Distribution"];

  // Lista ID Kabel / seg FO husi kada Munisípiu
  final Map<String, Map<String, List<Map<String, String>>>> _segmentsData = {
    "Dili": {
      "Backbone": [
        {"name": "Dili - Liquica", "distance": "32 km", "core": "48 Core"},
        {"name": "Dili - Aileu", "distance": "47 km", "core": "24 Core"},
        {"name": "Dili - Manatuto", "distance": "60 km", "core": "48 Core"},
      ],
      "Seader": [
        {"name": "Seader Comoro", "distance": "5 km", "core": "12 Core"},
        {"name": "Seader Colmera", "distance": "3 km", "core": "24 Core"},
      ],
      "Distribution": [
        {"name": "Dist-A1", "distance": "0.5 km", "core": "6 Core"},
        {"name": "Dist-B2", "distance": "1.2 km", "core": "12 Core"},
      ],
    },
    "Baucau": {
      "Backbone": [
        {"name": "Baucau - Lospalos", "distance": "75 km", "core": "48 Core"},
        {"name": "Baucau - Viqueque", "distance": "58 km", "core": "24 Core"},
      ],
      "Seader": [
        {"name": "Seader Baucau Villa", "distance": "4 km", "core": "12 Core"},
      ],
      "Distribution": [
        {"name": "Dist-Baucau-1", "distance": "0.8 km", "core": "6 Core"},
      ],
    },
    // Generic fallback for other municipalities
    "Liquica": {
      "Backbone": [
        {"name": "Liquica - Dili", "distance": "32 km", "core": "48 Core"},
        {"name": "Liquica - Bobonaro", "distance": "65 km", "core": "24 Core"},
      ],
    },
  };

  // Funsaun hodi analiza rezultadu sukat
  void _analizaPengukuran() {
    // Verifikasaun: Se laiha foto capturada, labele kontinua
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Toma foto medição nian uluk antes kontinua!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      double dbmValue = double.parse(_dbmController.text);
      // Lójika: Se dBm liu -25 (ezemplu -27dBm), nia kategoria "Drop" no liga ba Preventive
      if (dbmValue < -25.0) {
        _showResultDialog(
          "PERIGU (dBm Drop)",
          "Valor sukat -${dbmValue.abs()} dBm ne'e aas liu padraun. Sistema sei kria Ticket Korektivu automátiku ba Munisípiu $_selectedMunisipio, seg ${_selectedSegment?['name'] ?? 'N/A'}.",
          Colors.red,
          true,
        );
      } else {
        _showResultDialog(
          "REDE ESTÁVEL",
          "Valor sukat -${dbmValue.abs()} dBm sei di'ak hela (Normal). Dadus rai ona iha Sistema Potensi.",
          Colors.green,
          false,
        );
      }
    }
  }

  // Funsaun hodi captura foto ho kamera (la husi gallery)
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Foto medição susesu captura ona!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro captura foto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSegmentDetails() {
    if (_selectedSegment == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFED1C24).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFED1C24),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Detalle Segmento: ${_selectedSegment!['name']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFED1C24),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(thickness: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _detailItem(
                  Icons.straighten,
                  "Distánsia",
                  _selectedSegment!['distance']!,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.withOpacity(0.3),
                ),
                _detailItem(
                  Icons.settings_input_component,
                  "Kore",
                  _selectedSegment!['core']!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFED1C24)),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showResultDialog(
    String title,
    String msg,
    Color color,
    bool isPreventive,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPreventive ? Icons.warning_amber_rounded : Icons.check_circle,
              size: 60,
              color: color,
            ),
            const SizedBox(height: 15),
            Text(msg, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Potensial no Medida"),
        backgroundColor: const Color(0xFFED1C24),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informasaun Kabel & Lokasaun",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),

              // 1. SELECT MUNISIPIU
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Hili Munisípiu",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.map),
                ),
                items: _munisipios
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedMunisipio = val;
                  _selectedType = null;
                  _selectedSegment = null;
                }),
                validator: (val) => val == null ? "Hili munisípiu ida" : null,
              ),
              const SizedBox(height: 20),

              // 2. SELECT TYPE (Backbone, Seader, Distribution)
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: "Hili Tipu Rede",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.account_tree_outlined),
                ),
                items: _types
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: _selectedMunisipio != null
                    ? (val) => setState(() {
                        _selectedType = val;
                        _selectedSegment = null;
                      })
                    : null,
                validator: (val) => val == null ? "Hili tipu rede ida" : null,
              ),
              const SizedBox(height: 20),

              // 3. SELECT SEGMENT
              DropdownButtonFormField<Map<String, String>>(
                value: _selectedSegment,
                decoration: InputDecoration(
                  labelText: "Hili Segmentu / ID Kabel",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.settings_input_component),
                ),
                items: (_selectedMunisipio != null && _selectedType != null)
                    ? (_segmentsData[_selectedMunisipio]?[_selectedType] ?? [])
                          .map(
                            (e) => DropdownMenuItem<Map<String, String>>(
                              value: e,
                              child: SizedBox(
                                width: 220,
                                child: Text(
                                  e['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          )
                          .toList()
                    : [],
                onChanged: _selectedType != null
                    ? (val) => setState(() => _selectedSegment = val)
                    : null,
                validator: (val) => val == null ? "Hili segmentu ida" : null,
              ),
              const SizedBox(height: 10),

              // SHOW SEGMENT DETAILS
              _buildSegmentDetails(),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 10),

              // 3. CAPTURA FOTO MEDISAUN (OBRIGATORIU - PRIMEIRA)
              const Text(
                "Evidência Medição (Obrigatório)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              // Preview foto capturada
              if (_capturedImage != null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_capturedImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Foto captura ona",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Toma fali"),
                    ),
                  ],
                ),
              ] else ...[
                // Butaun captura foto
                SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, size: 40),
                    label: const Text(
                      "Toma Foto Medição",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFED1C24),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "* Tenke upload foto medição nian antes klik analiza",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 20),

              const Text(
                "Rezultadu Sukat (OTDR/OPM)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),

              // 4. INPUT DBM
              TextFormField(
                controller: _dbmController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Valor sukat (dBm)",
                  hintText: "Ezemplu: -18.5",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.speed),
                  suffixText: "dBm",
                ),
                validator: (val) => val!.isEmpty ? "Input valor dBm" : null,
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 30),

              // 5. BUTAUN ANALIZA
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _capturedImage != null
                        ? const Color(0xFFED1C24)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _capturedImage != null ? _analizaPengukuran : null,
                  child: Text(
                    _capturedImage != null
                        ? "CHECK & ANALIZA REDE"
                        : "TENKE UPLOAD RESULTADO MEDISAUN",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
