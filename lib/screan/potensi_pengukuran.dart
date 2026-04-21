import 'package:flutter/material.dart';

class PotensiPengukuranPage extends StatefulWidget {
  const PotensiPengukuranPage({super.key});

  @override
  State<PotensiPengukuranPage> createState() => _PotensiPengukuranPageState();
}

class _PotensiPengukuranPageState extends State<PotensiPengukuranPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMunisipio;
  final TextEditingController _dbmController = TextEditingController();
  final TextEditingController _kabelController = TextEditingController();

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

  // Funsaun hodi analiza rezultadu sukat
  void _analizaPengukuran() {
    if (_formKey.currentState!.validate()) {
      double dbmValue = double.parse(_dbmController.text);

      // Lójika: Se dBm liu -25 (ezemplu -27dBm), nia kategoria "Drop" no liga ba Preventive
      if (dbmValue < -25.0) {
        _showResultDialog(
          "PERIGU (dBm Drop)",
          "Valor sukat -${dbmValue.abs()} dBm ne'e aas liu padraun. Sistema sei kria Ticket PREVENTIVE automátiku ba Munisípiu $_selectedMunisipio.",
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
        title: const Text("Potensi & Pengukuran"),
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
                onChanged: (val) => setState(() => _selectedMunisipio = val),
                validator: (val) => val == null ? "Hili munisípiu ida" : null,
              ),
              const SizedBox(height: 20),

              // 2. INPUT KABEL ID / SEGMENT
              TextFormField(
                controller: _kabelController,
                decoration: InputDecoration(
                  labelText: "ID Kabel / Segmentu FO",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.settings_input_component),
                ),
                validator: (val) => val!.isEmpty ? "Input ID Kabel" : null,
              ),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Rezultadu Sukat (OTDR/OPM)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),

              // 3. INPUT DBM
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
              const SizedBox(height: 30),

              // 4. BUTAUN ANALIZA
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED1C24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _analizaPengukuran,
                  child: const Text(
                    "CHECK & ANALIZA REDE",
                    style: TextStyle(
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
