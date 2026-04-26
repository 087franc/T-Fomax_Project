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
  String? _selectedKabel;
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

  // Lista ID Kabel / seg FO husi kada Munisípiu
  final Map<String, List<String>> _kabelsegtsByMunisipio = {
    "Dili": ["seg Comoro - Tibar", "seg Dili - Baucau", "seg Dili - Liquica"],
    "Baucau": [
      "seg. Baucau Villa - Vemasse",
      "seg. Baucau - Liquica",
      "seg. Baucau - Ermera",
      "seg. Baucau - Aileu",
    ],
    "Liquica": [
      "seg. Liquica - Lospalos",
      "seg. Liquica - Baucau",
      "seg. Liquica - Ermera",
      "seg. Liquica - Maliana",
    ],
    "Ermera": [
      "seg. Ermera - Hatulia",
      "seg. Ermera - Liquica",
      "seg. Ermera - Baucau",
      "seg. Ermera - Ainaro",
    ],
    "Aileu": [
      "seg. Aileu - Manatuto",
      "seg. Aileu - Baucau",
      "seg. Aileu - Ermera",
      "seg. Aileu - Manufahi",
    ],
    "Manufahi": [
      "seg. Manufahi - Viqueque",
      "seg. Manufahi - Liquica",
      "seg. Manufahi - Baucau",
      "seg. Manufahi - Oecusse",
    ],
    "Viqueque": [
      "seg. Viqueque - Covalima",
      "seg. Viqueque - Manufahi",
      "seg. Viqueque - Liquica",
      "seg. Viqueque - Manatuto",
    ],
    "Lospalos": [
      "seg. Lospalos - Baucau",
      "seg. Lospalos - Liquica",
      "seg. Lospalos - Ermera",
      "seg. Lospalos - Aileu",
    ],
    "Bobonaro": [
      "seg. Bobonaro - Maliana",
      "seg. Bobonaro - Liquica",
      "seg. Bobonaro - Ermera",
      "seg. Bobonaro - Ainaro",
    ],
    "Covalima": [
      "seg. Covalima - Viqueque",
      "seg. Covalima - Manufahi",
      "seg. Covalima - Liquica",
      "seg. Covalima - Manatuto",
    ],
    "Ainaro": [
      "seg. Ainaro - Manatuto",
      "seg. Ainaro - Baucau",
      "seg. Ainaro - Ermera",
      "seg. Ainaro - Manufahi",
    ],
    "Manatuto": [
      "seg. Manatuto - Aileu",
      "seg. Manatuto - Ainaro",
      "seg. Manatuto - Liquica",
      "seg. Manatuto - Oecusse",
    ],
    "Oecusse": [
      "seg. Oecusse - Liquica",
      "seg. Oecusse - Manufahi",
      "seg. Oecusse - Baucau",
      "seg. Oecusse - Ainaro",
    ],
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
          "Valor sukat -${dbmValue.abs()} dBm ne'e aas liu padraun. Sistema sei kria Ticket PREVENTIVE automátiku ba Munisípiu $_selectedMunisipio, seg $_selectedKabel.",
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
                  _selectedKabel =
                      null; // Reset kabel selection when municipality changes
                }),
                validator: (val) => val == null ? "Hili munisípiu ida" : null,
              ),
              const SizedBox(height: 20),

              // 2. SELECT KABEL ID / segT
              DropdownButtonFormField<String>(
                value: _selectedKabel,
                decoration: InputDecoration(
                  labelText: "ID Kabel / seg FO",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.settings_input_component),
                ),
                items: (_selectedMunisipio != null
                    ? (_kabelsegtsByMunisipio[_selectedMunisipio] ?? [])
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: SizedBox(
                                width: 220,
                                child: Text(e, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          )
                          .toList()
                    : <DropdownMenuItem<String>>[]),
                onChanged: (val) => setState(() => _selectedKabel = val),
                validator: (val) => val == null ? "Hili ID Kabel" : null,
              ),
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
