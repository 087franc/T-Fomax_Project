import 'package:flutter/material.dart';

// 1. DEFINE MODEL EQUIPMENT (Tau iha kraik ka kria file ketak)
class Equipment {
  final String id;
  final String name;
  final String category;
  final String unit;
  final int total;
  final int good;
  final int broken;
  final int borrowed;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.total,
    required this.good,
    required this.broken,
    required this.borrowed,
  });
}

class AlkerSarkerPage extends StatefulWidget {
  const AlkerSarkerPage({super.key});

  @override
  State<AlkerSarkerPage> createState() => _AlkerSarkerPageState();
}

class _AlkerSarkerPageState extends State<AlkerSarkerPage> {
  final List<Equipment> inventory = [
    Equipment(
      id: "EQ-01",
      name: "Splicer Fujikura",
      category: "Alker",
      unit: "Unit",
      total: 10,
      good: 7,
      broken: 1,
      borrowed: 2,
    ),
    Equipment(
      id: "EQ-02",
      name: "OPM",
      category: "Alker",
      unit: "Unit",
      total: 15,
      good: 12,
      broken: 3,
      borrowed: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
        elevation: 1,
        // IMPLEMENTASAUN LOGO HO TESTU IHA APPBAR
        title: Row(
          children: [
            // Garanja file logo iha ona pasta assets
            // Image.asset('img/T-Fomax.png', height: 35),
            const SizedBox(width: 10),
            const Text("Alker & Sarker", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: inventory.length,
        itemBuilder: (context, index) {
          final item = inventory[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: const Color(0xFFC6141F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2, color: Color(0xFFC6141F)),
              ),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Kategoria: ${item.category} | Tot: ${item.total}",
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailAlkerPage(item: item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DetailAlkerPage extends StatelessWidget {
  final Equipment item;
  const DetailAlkerPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: const Color(0xFFC6141F), // Mean Telkomcel
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Dashboard Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Total", item.total.toString(), Colors.blue),
                _buildStatCard("Di'ak", item.good.toString(), Colors.green),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Aat", item.broken.toString(), Colors.red),
                _buildStatCard(
                  "Empresta",
                  item.borrowed.toString(),
                  Colors.orange,
                ),
              ],
            ),
            const Divider(height: 40),
            _buildInfoRow("ID Sasán", item.id),
            _buildInfoRow("Kategoria", item.category),
            _buildInfoRow("Unidade", item.unit),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC6141F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Lójika ba Empresta
              },
              icon: const Icon(Icons.handshake),
              label: const Text(
                "EMPRESTA SASÁN",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
