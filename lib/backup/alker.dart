// import 'package:flutter/material.dart';

// class InventoryIntegratedPage extends StatefulWidget {
//   const InventoryIntegratedPage({super.key});

//   @override
//   State<InventoryIntegratedPage> createState() =>
//       _InventoryIntegratedPageState();
// }

// class _InventoryIntegratedPageState extends State<InventoryIntegratedPage> {
//   // DADUS INVENTORY NE'EBÉ LIGA BA NIA HISTORY (ONE-TO-MANY)
//   final List<Map<String, dynamic>> _inventoryItems = [
//     {
//       "id": "TL-FS-01",
//       "name": "Fusion Splicer Fujikura",
//       "status": "In Use",
//       "is_good": true,
//       "current_holder": "Francisco Soares",
//       "history": [
//         {
//           "user": "Mateus Belo",
//           "date": "2026-03-10",
//           "type": "Return",
//           "note": "Kondisaun di'ak",
//         },
//         {
//           "user": "Francisco Soares",
//           "date": "2026-03-28",
//           "type": "Borrow",
//           "note": "Projetu Baucau",
//         },
//       ],
//     },
//     {
//       "id": "TL-OTDR-05",
//       "name": "OTDR VIAVI",
//       "status": "Available",
//       "is_good": false, // Ezemplu: Presiza Kalibrasaun
//       "current_holder": "-",
//       "history": [
//         {
//           "user": "Antonio da Costa",
//           "date": "2026-03-15",
//           "type": "Return",
//           "note": "Bateria uitoan ona",
//         },
//       ],
//     },
//     {
//       "id": "TL-OPM-12",
//       "name": "Optical Power Meter",
//       "status": "Available",
//       "is_good": true,
//       "current_holder": "-",
//       "history": [],
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F9),
//       appBar: AppBar(
//         title: const Text(
//           "ASKER & SERVER",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//         ),
//         backgroundColor: const Color(0xFFED1C24),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           // SUMMARY HEADER
//           _buildHeaderSummary(),

//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: _inventoryItems.length,
//               itemBuilder: (context, index) {
//                 final item = _inventoryItems[index];
//                 return _buildInventoryCard(item);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // WIDGET CARD EKIPAMENTU
//   Widget _buildInventoryCard(Map<String, dynamic> item) {
//     bool isAvailable = item['status'] == "Available";

//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: ExpansionTile(
//         leading: CircleAvatar(
//           backgroundColor: item['is_good'] ? Colors.green[50] : Colors.red[50],
//           child: Icon(
//             item['is_good'] ? Icons.build_circle : Icons.warning,
//             color: item['is_good'] ? Colors.green : Colors.red,
//           ),
//         ),
//         title: Text(
//           item['name'],
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text("ID: ${item['id']} | Status: ${item['status']}"),
//         trailing: Icon(
//           isAvailable ? Icons.check_circle : Icons.pause_circle,
//           color: isAvailable ? Colors.green : Colors.orange,
//         ),

//         // IHA NE'E MAK LISTA HISTORY MOSU (CHILD)
//         children: [
//           const Divider(),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 "History Borrow/Return:",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//           ),
//           if (item['history'].isEmpty)
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Text(
//                 "Seidauk iha istória empresta.",
//                 style: TextStyle(
//                   fontStyle: FontStyle.italic,
//                   color: Colors.grey,
//                 ),
//               ),
//             ),

//           // MAPPING HISTORY DATA
//           ...(item['history'] as List).map((log) {
//             return ListTile(
//               dense: true,
//               leading: Icon(
//                 log['type'] == "Borrow"
//                     ? Icons.arrow_upward
//                     : Icons.arrow_downward,
//                 color: log['type'] == "Borrow" ? Colors.red : Colors.blue,
//                 size: 20,
//               ),
//               title: Text("${log['user']} (${log['type']})"),
//               subtitle: Text("${log['date']} - Obs: ${log['note']}"),
//             );
//           }).toList(),

//           // BUTAUN AKSAUN IHA OKOS CARD
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () => _showBorrowReturnForm(item),
//                     icon: Icon(isAvailable ? Icons.outbox : Icons.all_inbox),
//                     label: Text(isAvailable ? "EMPRESTA" : "ENTREGA"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isAvailable ? Colors.blue : Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 IconButton(
//                   onPressed: () => _reportDamage(item),
//                   icon: const Icon(Icons.report_problem, color: Colors.orange),
//                   tooltip: "Report Damage",
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderSummary() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Color(0xFFED1C24),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _summaryBox("TOTAL", "${_inventoryItems.length}"),
//           _summaryBox("IN USE", "1"),
//           _summaryBox("ISSUE", "1"),
//         ],
//       ),
//     );
//   }

//   Widget _summaryBox(String title, String value) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           title,
//           style: const TextStyle(color: Colors.white70, fontSize: 12),
//         ),
//       ],
//     );
//   }

//   // FORMULÁRIU EMPRESTA/ENTREGA
//   void _showBorrowReturnForm(Map<String, dynamic> item) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//           left: 20,
//           right: 20,
//           top: 20,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Update Status: ${item['name']}",
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 15),
//             const TextField(
//               decoration: InputDecoration(
//                 labelText: "Naran Tékniku",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),
//             const TextField(
//               decoration: InputDecoration(
//                 labelText: "Notas (Objetivu/Kondisaun)",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFED1C24),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   "SUBMETE",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   void _reportDamage(Map<String, dynamic> item) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           "Relata failansu ba ${item['name']} haruka ona ba Admin.",
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';

// class InventoryIntegratedPage extends StatefulWidget {
//   const InventoryIntegratedPage({super.key});

//   @override
//   State<InventoryIntegratedPage> createState() =>
//       _InventoryIntegratedPageState();
// }

// class _InventoryIntegratedPageState extends State<InventoryIntegratedPage> {
//   // DADUS INVENTORY NE'EBÉ LIGA BA NIA HISTORY (ONE-TO-MANY)
//   final List<Map<String, dynamic>> _inventoryItems = [
//     {
//       "id": "TL-FS-01",
//       "name": "Fusion Splicer Fujikura",
//       "status": "In Use",
//       "is_good": true,
//       "current_holder": "Francisco Soares",
//       "history": [
//         {
//           "user": "Mateus Belo",
//           "date": "2026-03-10",
//           "type": "Return",
//           "note": "Kondisaun di'ak",
//         },
//         {
//           "user": "Francisco Soares",
//           "date": "2026-03-28",
//           "type": "Borrow",
//           "note": "Projetu Baucau",
//         },
//       ],
//     },
//     {
//       "id": "TL-OTDR-05",
//       "name": "OTDR VIAVI",
//       "status": "Available",
//       "is_good": false, // Ezemplu: Presiza Kalibrasaun
//       "current_holder": "-",
//       "history": [
//         {
//           "user": "Antonio da Costa",
//           "date": "2026-03-15",
//           "type": "Return",
//           "note": "Bateria uitoan ona",
//         },
//       ],
//     },
//     {
//       "id": "TL-OPM-12",
//       "name": "Optical Power Meter",
//       "status": "Available",
//       "is_good": true,
//       "current_holder": "-",
//       "history": [],
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F9),
//       appBar: AppBar(
//         title: const Text(
//           "ASKER & SERVER",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//         ),
//         backgroundColor: const Color(0xFFED1C24),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           // SUMMARY HEADER
//           _buildHeaderSummary(),

//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: _inventoryItems.length,
//               itemBuilder: (context, index) {
//                 final item = _inventoryItems[index];
//                 return _buildInventoryCard(item);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // WIDGET CARD EKIPAMENTU
//   Widget _buildInventoryCard(Map<String, dynamic> item) {
//     bool isAvailable = item['status'] == "Available";

//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: ExpansionTile(
//         leading: CircleAvatar(
//           backgroundColor: item['is_good'] ? Colors.green[50] : Colors.red[50],
//           child: Icon(
//             item['is_good'] ? Icons.build_circle : Icons.warning,
//             color: item['is_good'] ? Colors.green : Colors.red,
//           ),
//         ),
//         title: Text(
//           item['name'],
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text("ID: ${item['id']} | Status: ${item['status']}"),
//         trailing: Icon(
//           isAvailable ? Icons.check_circle : Icons.pause_circle,
//           color: isAvailable ? Colors.green : Colors.orange,
//         ),

//         // IHA NE'E MAK LISTA HISTORY MOSU (CHILD)
//         children: [
//           const Divider(),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 "History Borrow/Return:",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//           ),
//           if (item['history'].isEmpty)
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Text(
//                 "Seidauk iha istória empresta.",
//                 style: TextStyle(
//                   fontStyle: FontStyle.italic,
//                   color: Colors.grey,
//                 ),
//               ),
//             ),

//           // MAPPING HISTORY DATA
//           ...(item['history'] as List).map((log) {
//             return ListTile(
//               dense: true,
//               leading: Icon(
//                 log['type'] == "Borrow"
//                     ? Icons.arrow_upward
//                     : Icons.arrow_downward,
//                 color: log['type'] == "Borrow" ? Colors.red : Colors.blue,
//                 size: 20,
//               ),
//               title: Text("${log['user']} (${log['type']})"),
//               subtitle: Text("${log['date']} - Obs: ${log['note']}"),
//             );
//           }).toList(),

//           // BUTAUN AKSAUN IHA OKOS CARD
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () => _showBorrowReturnForm(item),
//                     icon: Icon(isAvailable ? Icons.outbox : Icons.all_inbox),
//                     label: Text(isAvailable ? "EMPRESTA" : "ENTREGA"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isAvailable ? Colors.blue : Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 IconButton(
//                   onPressed: () => _reportDamage(item),
//                   icon: const Icon(Icons.report_problem, color: Colors.orange),
//                   tooltip: "Report Damage",
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderSummary() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Color(0xFFED1C24),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _summaryBox("TOTAL", "${_inventoryItems.length}"),
//           _summaryBox("IN USE", "1"),
//           _summaryBox("ISSUE", "1"),
//         ],
//       ),
//     );
//   }

//   Widget _summaryBox(String title, String value) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           title,
//           style: const TextStyle(color: Colors.white70, fontSize: 12),
//         ),
//       ],
//     );
//   }

//   // FORMULÁRIU EMPRESTA/ENTREGA
//   void _showBorrowReturnForm(Map<String, dynamic> item) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//           left: 20,
//           right: 20,
//           top: 20,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Update Status: ${item['name']}",
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 15),
//             const TextField(
//               decoration: InputDecoration(
//                 labelText: "Naran Tékniku",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),
//             const TextField(
//               decoration: InputDecoration(
//                 labelText: "Notas (Objetivu/Kondisaun)",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFED1C24),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   "SUBMETE",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   void _reportDamage(Map<String, dynamic> item) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           "Relata failansu ba ${item['name']} haruka ona ba Admin.",
//         ),
//       ),
//     );
//   }
// }
