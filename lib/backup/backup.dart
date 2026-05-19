// import 'package:flutter/material.dart';

// void main() {
//   runApp(
//     const MaterialApp(debugShowCheckedModeBanner: false, home: DashboardPage()),
//   );
// }

// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> menuItems = [
//       {'title': 'Presensi', 'icon': Icons.touch_app, 'color': Colors.red},
//       {'title': 'Corrective', 'icon': Icons.build, 'color': Colors.blue},
//       {
//         'title': 'Preventive',
//         'icon': Icons.energy_savings_leaf,
//         'color': Colors.orange,
//       },
//       {
//         'title': 'Proactive',
//         'icon': Icons.settings_input_component,
//         'color': Colors.red,
//       },
//       {
//         'title': 'Potensi & \nPengukuran',
//         'icon': Icons.bolt,
//         'color': Colors.green,
//       },
//       {
//         'title': 'Alker & Sarker',
//         'icon': Icons.inventory_2,
//         'color': Colors.red,
//       },
//       {'title': 'Project Team', 'icon': Icons.groups, 'color': Colors.grey},
//       {
//         'title': 'Tagging',
//         'icon': Icons.location_on_outlined,
//         'color': Colors.blue,
//       },
//       {'title': 'Download', 'icon': Icons.file_download, 'color': Colors.red},
//     ];

//     return Scaffold(
//       backgroundColor: Colors.blueGrey[50],
//       appBar: AppBar(
//         title: const Text(
//           "Dashboard Menu",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         elevation: 2,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
//         child: GridView.count(
//           crossAxisCount: 3,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12, // Espasu entre kantu sira ba leten no kraik
//           childAspectRatio:
//               0.75, // <--- Ida ne'e halo kantu naruk ba kraik (height boot liu)
//           children: menuItems.map((item) {
//             return Column(
//               mainAxisSize: MainAxisSize
//                   .min, // Atu column foti de'it espasu ne'ebé presiza
//               children: [
//                 // Parte Ikon ne'ebé boot no kapaas liu
//                 Container(
//                   padding: const EdgeInsets.all(
//                     16,
//                   ), // Aumenta espasu iha ikon laran
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(
//                       20,
//                     ), // Halo kantu kapaas liu
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     item['icon'],
//                     size: 45,
//                     color: item['color'],
//                   ), // Ikon boot tan uitoan
//                 ),
//                 const SizedBox(height: 12), // Espasu entre ikon no naran
//                 // Parte Titulu ho limite lina
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 4),
//                   child: Text(
//                     item['title'],
//                     textAlign: TextAlign.center,
//                     maxLines: 2, // Limite ba lina rua de'it
//                     overflow: TextOverflow
//                         .ellipsis, // Se naruk liu, nia sei tau pontu tolu (...)
//                     style: const TextStyle(
//                       fontSize: 11.5,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                       height: 1.2, // Distánsia entre lina 1 no lina 2
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
// //

//presensi

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';

// class PresensiPage extends StatefulWidget {
//   const PresensiPage({super.key});

//   @override
//   State<PresensiPage> createState() => _PresensiPageState();
// }

// class _PresensiPageState extends State<PresensiPage> {
//   File? _imageFile;
//   String _healthCondition = "Saudável";
//   final TextEditingController _taskController = TextEditingController();
//   Position? _currentPosition;

//   // LÓJIKA TEMPU (Muda oras iha ne'e se presiza)
//   bool get isMorning => DateTime.now().hour >= 6 && DateTime.now().hour < 11;
//   bool get isEvening => DateTime.now().hour >= 17 && DateTime.now().hour < 21;

//   @override
//   void initState() {
//     super.initState();
//     // _getHiddenLocation(); // Foti GPS subar husi dadeer kedas
//   }

//   // // GPS Hidden ba Admin
//   Future<void> _getHiddenLocation() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     _currentPosition = await Geolocator.getCurrentPosition();
//   }

//   // Kamera de'it (Mantein kódigu uluk nian)
//   Future<void> _takePhoto() async {
//     final picker = ImagePicker();
//     final photo = await picker.pickImage(
//       source: ImageSource.camera,
//       imageQuality: 50,
//     );
//     if (photo != null) setState(() => _imageFile = File(photo.path));
//   }

//   void _showSuccessDialog(String title, String msg) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.check_circle, color: Colors.green, size: 60),
//             const SizedBox(height: 15),
//             Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             const SizedBox(height: 10),
//             Text(msg, textAlign: TextAlign.center),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                 onPressed: () {
//                   Navigator.pop(context); // Taka dialog
//                   Navigator.pop(context); // Fila ba Home
//                 },
//                 child: const Text("OK", style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     String currentTime = DateFormat('HH:mm').format(DateTime.now());

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("Lista Presensa FIXOM"),
//         backgroundColor: Colors.redAccent,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             Text(
//               currentTime,
//               style: const TextStyle(
//                 fontSize: 50,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.redAccent,
//               ),
//             ),
//             Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())),
//             const SizedBox(height: 30),

//             // 1. FORM SAÚDE (MOSU DADEER DE'IT)
//             if (isMorning) ...[
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Kondisaun Saúde (*)",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: _healthCondition,
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.grey[100],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//                 items: ["Saudável", "Fever", "Me'ar", "Inus-metin"]
//                     .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                     .toList(),
//                 onChanged: (val) => setState(() => _healthCondition = val!),
//               ),
//               const SizedBox(height: 20),
//             ],

//             // 2. FOTO (MANTEIN KODIGU ULUK)
//             const Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 "Hasai Foto Oin (*)",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 8),
//             GestureDetector(
//               onTap: _takePhoto,
//               child: Container(
//                 height: 220,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(15),
//                   border: Border.all(color: Colors.grey.shade300, width: 2),
//                 ),
//                 child: _imageFile != null
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(13),
//                         child: Image.file(_imageFile!, fit: BoxFit.cover),
//                       )
//                     : const Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.camera_alt, size: 50, color: Colors.grey),
//                           Text("Klik hodi hasai foto"),
//                         ],
//                       ),
//               ),
//             ),
//             const SizedBox(height: 25),

//             // 3. DAILY TASK SUMMARY (MOSU LOROKRAIK DE'IT)
//             if (isEvening) ...[
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Relatóriu Servisu Ohin (*)",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _taskController,
//                 maxLines: 3,
//                 onChanged: (val) => setState(() {}),
//                 decoration: InputDecoration(
//                   hintText: "Hakerek saida mak halo ona...",
//                   filled: true,
//                   fillColor: Colors.grey[100],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 25),
//             ],

//             // 4. LÓJIKA BUTAUN (TIME IN / TIME OUT)
//             if (isMorning)
//               _buildButton("CLOCK IN", Colors.green, _imageFile != null, () {
//                 _showSuccessDialog(
//                   "Susesu In",
//                   "Ita-nia kondisaun: $_healthCondition. Servisu di'ak!",
//                 );
//                 print(
//                   "ADMIN RECEIVE GPS: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}",
//                 );
//               })
//             else if (isEvening)
//               _buildButton(
//                 "CLOCK OUT",
//                 Colors.redAccent,
//                 (_imageFile != null && _taskController.text.isNotEmpty),
//                 () {
//                   _showSuccessDialog(
//                     "Susesu Out",
//                     "Obrigadu ba ita-nia servisu ohin. Deskansa di'ak!",
//                   );
//                   print("ADMIN RECEIVE TASK: ${_taskController.text}");
//                 },
//               )
//             else
//               const Text(
//                 "Butaun la mosu iha oras ne'e.",
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(
//     String label,
//     Color color,
//     bool isEnabled,
//     VoidCallback onPressed,
//   ) {
//     return SizedBox(
//       width: double.infinity,
//       height: 55,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: isEnabled ? color : Colors.grey[300],
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           elevation: 0,
//         ),
//         onPressed: isEnabled
//             ? onPressed
//             : null, // Butaun mate se kondisaun seidauk nakonu
//         child: Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       ),
//     );

//   }
// }

// form aumenta Laporan

// import 'package:flutter/material.dart';
// import 'preventive.dart';
// import 'preventivepage.dart';

// class TambahLaporanPage extends StatefulWidget {
//   const TambahLaporanPage({super.key});

//   @override
//   State<TambahLaporanPage> createState() => _TambahLaporanPageState();
// }

// class _TambahLaporanPageState extends State<TambahLaporanPage> {
//   String? selectedKategori = 'Melhoramentu';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.redAccent, // Kór matak FIXOM
//         title: const Text(
//           "Form Preventive",
//           style: TextStyle(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.chevron_left, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.chevron_right, color: Colors.white),
//             onPressed: () {},
//           ),
//           // MENU TITIK TIGA HODI LOKE LISTA TICKET
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert, color: Colors.white),
//             onSelected: (value) {
//               if (value == 'list') {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const PreventiveListPage(),
//                   ),
//                 );
//               } else if (value == 'lista Patroli') {
//                 // Mensajen temporáriu ba menu seluk
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const PreventivePage(),
//                   ),
//                 );
//               }
//             },
//             itemBuilder: (BuildContext context) => [
//               const PopupMenuItem(
//                 value: 'list',
//                 child: Text("Hare Lista Ticket"),
//               ),
//               PopupMenuItem(
//                 value: 'lista Patroli',
//                 child: Text("Hare lista Patroli"),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Aumeta Relatorio Patroli",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 15),
//             // Input naran (User chip)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
//               child: Row(
//                 children: [Chip(label: const Text("ALCINO D.F.M. VALENTE"))],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("Kategoria Aktividade (*)"),
//             // Dropdown Menu hanesan iha imajen
//             DropdownButtonFormField<String>(
//               value: selectedKategori,
//               decoration: const InputDecoration(border: OutlineInputBorder()),
//               items:
//                   [
//                         '- Hili Kategoria Aktividade -',
//                         'Preventivu',
//                         'Melhoramentu',
//                       ]
//                       .map(
//                         (label) =>
//                             DropdownMenuItem(value: label, child: Text(label)),
//                       )
//                       .toList(),
//               onChanged: (value) => setState(() => selectedKategori = value),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//
// corrective

// import 'package:flutter/material.dart';
// import 'chat_team.dart';

// class CorrectivePage extends StatefulWidget {
//   const CorrectivePage({super.key});

//   @override
//   State<CorrectivePage> createState() => _CorrectivePageState();
// }

// class _CorrectivePageState extends State<CorrectivePage> {
//   // SIMULASAUN USER ID (User ne'ebé login hela agora)
//   final String myTeamId = "TEAM-FRANS-01";

//   final List<Map<String, dynamic>> _tickets = [
//     {
//       "id": "TKT-FO-001",
//       "title": "Fiber Optic Cut (FO Putus)",
//       "status": "OPEN",
//       "claimed_by": null, // Seidauk iha na'in
//     },
//     {
//       "id": "TKT-FO-002",
//       "title": "Signal Degradation",
//       "status": "OPEN",
//       "claimed_by": null,
//     },
//     {
//       "id": "TKT-FO-003",
//       "title": "Splice Loss",
//       "status": "OPEN",
//       "claimed_by": null,
//     },
//     {
//       "id": "TKT-FO-004",
//       "title": "Connector Issue",
//       "status": "OPEN",
//       "claimed_by": null,
//     },
//   ];

//   void _handleAction(int index) {
//     var ticket = _tickets[index];

//     // 1. SE STATUS OPEN -> HALO CLAIM
//     if (ticket['status'] == "OPEN") {
//       _confirmClaim(index);
//     }
//     // 2. SE ON PROCESS -> CEK SESE MAK CLAIM?
//     else if (ticket['status'] == "ON PROCESS") {
//       if (ticket['claimed_by'] == myTeamId) {
//         // HAU MAK NA'IN -> BELE TAMA
//         _navigateToChat(index);
//       } else {
//         // EMA SELUK MAK NA'IN -> HATUDU WARNING
//         _showAccessDenied();
//       }
//     }
//   }

//   void _confirmClaim(int index) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Claim Ticket?"),
//         content: const Text(
//           "Ita ho ita-nia tim sei foti responsabilidade ba ticket ne'e.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("CANCEL"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 _tickets[index]['status'] = "ON PROCESS";
//                 _tickets[index]['claimed_by'] = myTeamId; // REJISTA NA'IN
//               });
//               Navigator.pop(context);
//               _navigateToChat(index);
//             },
//             child: const Text("CLAIM"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToChat(int index) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CorrectiveChatPage(
//           ticketId: _tickets[index]['id'],
//           onFinalize: () {
//             setState(() {
//               _tickets[index]['status'] = "CLOSED";
//             });
//           },
//         ),
//       ),
//     );
//   }

//   void _showAccessDenied() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Failha! Ticket ne'e ema seluk mak claim ona."),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Corrective (Gangguan)"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: _tickets.length,
//         itemBuilder: (context, index) {
//           var t = _tickets[index];
//           bool isMyTicket = t['claimed_by'] == myTeamId;
//           bool isOpen = t['status'] == "OPEN";
//           bool isClosed = t['status'] == "CLOSED";

//           return Card(
//             child: ListTile(
//               title: Text(
//                 t['id'],
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(
//                 "${t['title']}\nStatus: ${t['status']}",
//                 style: TextStyle(
//                   color: isClosed
//                       ? Colors.grey
//                       : (isOpen ? Colors.blue : Colors.orange),
//                 ),
//               ),
//               trailing: ElevatedButton(
//                 // Se CLOSED, butaun mate. Se ema seluk foti, butaun kór seluk.
//                 onPressed: isClosed ? null : () => _handleAction(index),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isOpen
//                       ? Colors.blue
//                       : (isMyTicket ? Colors.orange : Colors.grey),
//                 ),
//                 child: Text(
//                   isOpen ? "CLAIM" : (isMyTicket ? "ENTER CHAT" : "ON PROCESS"),
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// chat
// import 'dart:io';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class CorrectiveChatPage extends StatefulWidget {
//   final String ticketId;
//   final Function() onFinalize;
//   const CorrectiveChatPage({
//     super.key,
//     required this.ticketId,
//     required this.onFinalize,
//   });

//   @override
//   State<CorrectiveChatPage> createState() => _CorrectiveChatPageState();
// }

// class _CorrectiveChatPageState extends State<CorrectiveChatPage> {
//   final TextEditingController _msgController = TextEditingController();
//   final List<Map<String, dynamic>> _messages = [];
//   Timer? _reminderTimer;

//   @override
//   void initState() {
//     super.initState();
//     // 1. INÍSIU TIMER 30 MINUTUS (Simulasaun de'it ba segundu 10 hodi ita bele haree)
//     _startSlaReminder();
//   }

//   void _startSlaReminder() {
//     _reminderTimer = Timer(const Duration(minutes: 30), () {
//       if (mounted) {
//         _showSlaAlert();
//       }
//     });
//   }

//   void _showSlaAlert() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("⚠️ SLA REMINDER"),
//         content: const Text(
//           "Ticket ne'e la'o ona minutus 30. Favor finaliza lalais ka update progresu!",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }

//   // 2. FUNSAUN HARUKA IMAJEN
//   Future<void> _sendImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _messages.add({
//           "user": "Frans",
//           "type": "image",
//           "content": File(pickedFile.path),
//           "time": DateTime.now(),
//         });
//       });
//     }
//   }

//   // 3. FUNSAUN HARUKA TESTU
//   void _sendText() {
//     if (_msgController.text.isNotEmpty) {
//       setState(() {
//         _messages.add({
//           "user": "Frans",
//           "type": "text",
//           "content": _msgController.text,
//           "time": DateTime.now(),
//         });
//       });
//       _msgController.clear();
//     }
//   }

//   @override
//   void dispose() {
//     _reminderTimer?.cancel();
//     super.dispose();
//   }

//   void _processFinalize() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Finaliza Servisu?"),
//         content: const Text(
//           "Klik 'SIM' hodi taka ticket ne'e. Labele loke fali depois de taka.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("KANSELA"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             onPressed: () {
//               widget.onFinalize(); // EKSEKUTA CALLBACK BA PAGE ULUK
//               Navigator.pop(context); // Taka Dialog
//               Navigator.pop(context); // Sai husi Chat (ba Lista)

//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Ticket Mate ona (Closed)!")),
//               );
//             },
//             child: const Text("SIM, TAKA TICKET"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.ticketId),
//         backgroundColor: Colors.blueGrey[800],
//         actions: [
//           // BUTAUN FINALIZE IHA LETEN
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//               ),
//               onPressed: _processFinalize,
//               icon: const Icon(Icons.check_circle, size: 18),
//               label: const Text("FINALIZE"),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: true, // Chat foun mosu husi okos
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final chat = _messages.reversed.toList()[index];
//                 return _buildChatBubble(chat);
//               },
//             ),
//           ),
//           _buildInputArea(),
//         ],
//       ),
//     );
//   }

//   Widget _buildChatBubble(Map<String, dynamic> chat) {
//     bool isMe = chat['user'] == "Frans";
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Column(
//           crossAxisAlignment: isMe
//               ? CrossAxisAlignment.end
//               : CrossAxisAlignment.start,
//           children: [
//             Text(
//               chat['user'],
//               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 5),
//             chat['type'] == "text"
//                 ? Text(chat['content'])
//                 : ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.file(chat['content'], width: 200),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInputArea() {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.image, color: Colors.blue),
//             onPressed: _sendImage,
//           ),
//           Expanded(
//             child: TextField(
//               controller: _msgController,
//               decoration: const InputDecoration(
//                 hintText: "Hakerek mensajen...",
//                 border: InputBorder.none,
//               ),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.send, color: Colors.blue),
//             onPressed: _sendText,
//           ),
//         ],
//       ),
//     );
//   }
// }

// Home page

// import 'package:flutter/material.dart';
// // import 'dart:convert';xa
// // import 'preventive.dart';
// // import 'screan/form_aumenta_laporan.dart';
// import 'screan/proactive.dart';
// import 'screan/presensi.dart';
// import 'screan/corrective/corective.dart';
// import 'screan/potensi_pengukuran.dart';
// // import 'preventivepage.dart';
// import 'screan/alker_sarkel.dart';
// import 'screan/projectteam.dart';
// import 'screan/preventivepage.dart';

// void main() {
//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: MainDashboardPage(),
//     ),
//   );
// }

// // --- DASHBOARD PAGE ---
// class MainDashboardPage extends StatelessWidget {
//   const MainDashboardPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> menuItems = [
//       {'title': 'Presensi', 'icon': Icons.touch_app, 'color': Colors.red},
//       {'title': 'Corrective', 'icon': Icons.build, 'color': Colors.blue},
//       {
//         'title': 'Preventive',
//         'icon': Icons.energy_savings_leaf,
//         'color': Colors.orange,
//       },
//       {
//         'title': 'Proactive',
//         'icon': Icons.settings_input_component,
//         'color': Colors.red,
//       },
//       {
//         'title': 'Potensi & \nPengukuran',
//         'icon': Icons.bolt,
//         'color': Colors.green,
//       },
//       {
//         'title': 'Alker & Sarker',
//         'icon': Icons.inventory_2,
//         'color': Colors.red,
//       },
//       {'title': 'Project Team', 'icon': Icons.groups, 'color': Colors.grey},
//       {
//         'title': 'Tagging',
//         'icon': Icons.location_on_outlined,
//         'color': Colors.blue,
//       },
//       {'title': 'Download', 'icon': Icons.file_download, 'color': Colors.red},
//     ];

//     return Scaffold(
//       backgroundColor: Colors.blueGrey[50],
//       appBar: AppBar(
//         title: const Text("T-Fomax Dashboard", style: TextStyle(fontSize: 16)),
//         backgroundColor: Colors.redAccent,
//         foregroundColor: Colors.white,
//         elevation: 2,
//       ),
//       body: Stack(
//         children: [
//           // 1. Layer Gambar Background
//           Opacity(
//             opacity:
//                 0.3, // Nilai 0.0 sampai 1.0 (semakin kecil semakin transparan)
//             child: Container(
//               decoration: const BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage(
//                     'img/telkomcel.jpg',
//                   ), // Ganti dengan path gambar Anda
//                   fit: BoxFit.cover, // Gambar menutupi seluruh layar
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
//             child: GridView.count(
//               crossAxisCount: 3,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//               childAspectRatio: 0.75,
//               children: menuItems.map((item) {
//                 return InkWell(
//                   onTap: () {
//                     // Lójika hodi muda pájina ba Preventive
//                     if (item['title'] == 'Preventive') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const PreventivePage(),
//                         ),
//                       );
//                     } else if (item['title'] == 'Proactive') {
//                       // Mensajen temporáriu ba menu seluk
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => TambahProactivePage(),
//                         ),
//                       );
//                     } else if (item['title'] == 'Presensi') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => PresensiPage()),
//                       );
//                     } else if (item['title'] == 'Corrective') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => CorrectivePage(),
//                         ),
//                       );
//                     } else if (item['title'] == 'Potensi & \nPengukuran') {
//                       // Mensajen temporáriu ba menu seluk
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const PotensiPengukuranPage(),
//                         ),
//                       );
//                     } else if (item['title'] == 'Alker & Sarker') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const InventoryIntegratedPage(),
//                         ),
//                       );
//                     } else if (item['title'] == 'Project Team') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const ProjectTeamPage(),
//                         ),
//                       );
//                     } else {
//                       // Mensajen temporáriu ba menu seluk
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text("Menu ${item['title']} seidauk prontu"),
//                         ),
//                       );
//                     }
//                   },
//                   borderRadius: BorderRadius.circular(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Icon(
//                           item['icon'],
//                           size: 45,
//                           color: item['color'],
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 4),
//                         child: Text(
//                           item['title'],
//                           textAlign: TextAlign.center,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             fontSize: 11.5,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                             height: 1.2,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
