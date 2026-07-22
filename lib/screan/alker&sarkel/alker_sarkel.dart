import 'dart:convert';
import 'package:T_Fomax/services/api_service.dart';
import 'package:flutter/material.dart';
import 'detail_ekipament.dart';

class AlkerSarkerPage extends StatefulWidget {
  const AlkerSarkerPage({super.key});

  @override
  State<AlkerSarkerPage> createState() => _AlkerSarkerPageState();
}

class _AlkerSarkerPageState extends State<AlkerSarkerPage> {
  List<Equipment> inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().get("/api/v1/assets");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<dynamic> rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map && data.containsKey('data')) {
          rawList = data['data'] is List ? data['data'] : [];
        }

        if (mounted) {
          setState(() {
            final List<Equipment> loadedItems = rawList.map((item) {
              if (item is Map<String, dynamic>) {
                return Equipment.fromJson(item);
              } else if (item is Map) {
                return Equipment.fromJson(Map<String, dynamic>.from(item));
              }
              return Equipment(
                id: '',
                tools_name: '',
                category: '',
                tools_type: '',
                unidade: '',
                total: 0,
                good: 0,
                broken: 0,
                borrowed: 0,
              );
            }).toList();

            // Print debug info for each loaded item to diagnose API response
            for (var item in loadedItems) {
              debugPrint(
                "API Item: id='${item.id}', tools_name='${item.tools_name}', tools_type='${item.tools_type}', total=${item.total}, good=${item.good}, broken=${item.broken}, borrowed=${item.borrowed}",
              );
            }

            // 1. Deduplicate by ID to prevent double-counting due to duplicate API rows
            final Map<String, Equipment> distinctById = {};
            for (var item in loadedItems) {
              final idKey = item.id.isNotEmpty
                  ? item.id
                  : UniqueKey().toString();
              distinctById[idKey] = item;
            }

            // 2. Group and aggregate equipment by tools_name and tools_type (case-insensitive)
            final Map<String, List<Equipment>> groupedByNameAndType = {};
            for (var item in distinctById.values) {
              final String nameKey =
                  "${item.tools_name.trim().toLowerCase()}_${item.tools_type.trim().toLowerCase()}";
              if (!groupedByNameAndType.containsKey(nameKey)) {
                groupedByNameAndType[nameKey] = [];
              }
              groupedByNameAndType[nameKey]!.add(item);
            }

            // 3. Build the aggregated Equipment list with original items populated
            final List<Equipment> aggregatedList = [];
            for (var entry in groupedByNameAndType.entries) {
              final groupItems = entry.value;
              final firstItem = groupItems.first;

              int totalSum = 0;
              int goodSum = 0;
              int brokenSum = 0;
              int borrowedSum = 0;

              for (var git in groupItems) {
                totalSum += git.total;
                goodSum += git.good;
                brokenSum += git.broken;
                borrowedSum += git.borrowed;
              }

              aggregatedList.add(
                Equipment(
                  id: firstItem.id,
                  tools_name: firstItem.tools_name,
                  category: firstItem.category,
                  tools_type: firstItem.tools_type,
                  unidade: firstItem.unidade,
                  total: totalSum,
                  good: goodSum,
                  broken: brokenSum,
                  borrowed: borrowedSum,
                  statusLabel: firstItem.statusLabel,
                  stockStatus: firstItem.stockStatus,
                  remarks: firstItem.remarks,
                  createdAt: firstItem.createdAt,
                  updatedAt: firstItem.updatedAt,
                  originalItems: groupItems,
                  tools_id: firstItem.tools_id,
                  tools_type_id: firstItem.tools_type_id,
                ),
              );
            }
            inventory = aggregatedList;
          });
        }
        debugPrint("Items Loaded: ${inventory.length}");
      } else {
        debugPrint("Error: API returned status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception fetching data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
        elevation: 1,
        title: const Row(
          children: [
            SizedBox(width: 10),
            Text(
              "Fasilidade no Ekipamento",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC6141F)),
            )
          : ListView.builder(
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
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
                      child: const Icon(
                        Icons.inventory_2,
                        color: Color(0xFFC6141F),
                      ),
                    ),
                    title: Text(
                      item.tools_name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Tipu: ${item.tools_type} | Unidade: ${item.unidade}",
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
