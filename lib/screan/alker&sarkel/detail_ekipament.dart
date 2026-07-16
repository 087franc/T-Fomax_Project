import 'package:flutter/material.dart';

class Equipment {
  final String id;
  final String tools_name;
  final String category;
  final String tools_type;
  final String unidade;
  final int total;
  final int good;
  final int broken;
  final int borrowed;
  final List<Equipment> originalItems;

  // Fields from the JSON response
  final String statusLabel;
  final String stockStatus;
  final String remarks;
  final String createdAt;
  final String updatedAt;

  Equipment({
    required this.id,
    required this.tools_name,
    required this.category,
    required this.tools_type,
    required this.unidade,
    required this.total,
    required this.good,
    required this.broken,
    required this.borrowed,
    this.originalItems = const [],
    this.statusLabel = '',
    this.stockStatus = '',
    this.remarks = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    final String idVal = json['id']?.toString() ??
        json['tools_type_id']?.toString() ??
        json['asset_id']?.toString() ??
        json['id_asset']?.toString() ??
        '';

    final String nameVal = json['tools_name']?.toString() ??
        json['name']?.toString() ??
        json['asset_name']?.toString() ??
        json['product_name']?.toString() ??
        'Ekipamentu';

    final String categoryVal = json['category']?.toString() ??
        json['category_name']?.toString() ??
        'Alker';

    final String typeVal = json['tools_type']?.toString() ??
        json['type']?.toString() ??
        'Tumtec';

    final String unitVal = json['unidade']?.toString() ??
        json['unit']?.toString() ??
        'Unit';

    final int totalVal = _toInt(
      json['total'] ??
          json['qty'] ??
          json['quantity'] ??
          json['total_stock'] ??
          json['stock'] ??
          1,
    );

    final String statusLabelVal = json['status_label']?.toString() ?? '';
    final String stockStatusVal = json['stock_status']?.toString() ?? '';
    final String remarksVal = json['remarks']?.toString() ?? '';
    final String createdAtVal = json['created_at']?.toString() ?? '';
    final String updatedAtVal = json['updated_at']?.toString() ?? '';

    // Calculate good, broken, and borrowed based on status_label or status code
    final String labelLower = statusLabelVal.toLowerCase().trim();
    final int statusCode = _toInt(json['status']);

    int goodVal = 0;
    int brokenVal = 0;
    int borrowedVal = 0;

    if (labelLower == 'baik' ||
        labelLower == 'diak' ||
        labelLower == 'di\'ak' ||
        labelLower == 'good' ||
        labelLower == 'ok' ||
        statusCode == 1) {
      goodVal = totalVal;
    } else if (labelLower == 'rusak' ||
        labelLower == 'aat' ||
        labelLower == 'broken' ||
        labelLower == 'damaged' ||
        statusCode == 2) {
      brokenVal = totalVal;
    } else if (labelLower == 'pinjam' ||
        labelLower == 'empresta' ||
        labelLower == 'borrowed' ||
        labelLower == 'borrow' ||
        statusCode == 3) {
      borrowedVal = totalVal;
    } else {
      // Default fallback
      goodVal = totalVal;
    }

    return Equipment(
      id: idVal,
      tools_name: nameVal,
      category: categoryVal,
      tools_type: typeVal,
      unidade: unitVal,
      total: totalVal,
      good: goodVal,
      broken: brokenVal,
      borrowed: borrowedVal,
      statusLabel: statusLabelVal.isNotEmpty
          ? statusLabelVal
          : (goodVal > 0
              ? 'Baik'
              : brokenVal > 0
                  ? 'Rusak'
                  : 'Pinjam'),
      stockStatus: stockStatusVal,
      remarks: remarksVal,
      createdAt: createdAtVal,
      updatedAt: updatedAtVal,
      originalItems: const [],
    );
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}

class DetailAlkerPage extends StatelessWidget {
  final Equipment item;
  const DetailAlkerPage({super.key, required this.item});

  String _formatDate(String isoString) {
    try {
      final DateTime dt = DateTime.parse(isoString).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      if (isoString.contains('T')) {
        final parts = isoString.split('T');
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return "${dateParts[2]}/${dateParts[1]}/${dateParts[0]}";
        }
      }
      return isoString;
    }
  }

  void _showItemDetails(
    BuildContext context,
    String title,
    Color color,
    List<Equipment> items,
    String type,
  ) {
    final filteredItems = items.where((subItem) {
      if (type == 'total') return subItem.total > 0;
      if (type == 'good') return subItem.good > 0;
      if (type == 'broken') return subItem.broken > 0;
      if (type == 'borrowed') return subItem.borrowed > 0;
      return true;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (filteredItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      "La iha dadus sasán nian.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final subItem = filteredItems[index];
                      int val = 0;
                      if (type == 'total') val = subItem.total;
                      if (type == 'good') val = subItem.good;
                      if (type == 'broken') val = subItem.broken;
                      if (type == 'borrowed') val = subItem.borrowed;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "ID Sasán: ${subItem.id.isNotEmpty ? subItem.id : 'N/A'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      // ignore: deprecated_member_use
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Qtd: $val",
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Status: ${subItem.statusLabel.isNotEmpty ? subItem.statusLabel : 'Baik'} (${subItem.stockStatus.isNotEmpty ? subItem.stockStatus : 'Normal'})",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              if (subItem.remarks.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.comment_outlined,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Notas: ${subItem.remarks}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (subItem.createdAt.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Data Kria: ${_formatDate(subItem.createdAt)}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final originalList =
        item.originalItems.isNotEmpty ? item.originalItems : [item];

    return Scaffold(
      appBar: AppBar(
        title: Text(item.tools_name),
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
                _buildStatCard(
                  context,
                  "Total",
                  item.total.toString(),
                  Colors.blue,
                  () => _showItemDetails(
                    context,
                    "Detallu Sasán Total",
                    Colors.blue,
                    originalList,
                    'total',
                  ),
                ),
                _buildStatCard(
                  context,
                  "Di'ak",
                  item.good.toString(),
                  Colors.green,
                  () => _showItemDetails(
                    context,
                    "Detallu Sasán Di'ak",
                    Colors.green,
                    originalList,
                    'good',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  "Aat",
                  item.broken.toString(),
                  Colors.red,
                  () => _showItemDetails(
                    context,
                    "Detallu Sasán Aat",
                    Colors.red,
                    originalList,
                    'broken',
                  ),
                ),
                _buildStatCard(
                  context,
                  "Empresta",
                  item.borrowed.toString(),
                  Colors.orange,
                  () => _showItemDetails(
                    context,
                    "Detallu Sasán Empresta",
                    Colors.orange,
                    originalList,
                    'borrowed',
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            _buildInfoRow("Kategoria", item.category),
            _buildInfoRow("Tipu Sasán", item.tools_type),
            _buildInfoRow("Unidade", item.unidade),
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
                Navigator.pop(context);
              },
              icon: const Icon(Icons.door_back_door),
              label: const Text(
                "Fila",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
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
