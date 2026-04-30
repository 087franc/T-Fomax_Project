// import 'dart:io'; // Atu jere file foto
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // Import library foun
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'dart:convert';

// class TambahProactivePage extends StatefulWidget {
//   const TambahProactivePage({super.key});

//   @override
//   State<TambahProactivePage> createState() => _TambahProactivePageState();
// }

// class _TambahProactivePageState extends State<TambahProactivePage> {
//   File? imageFile;

//   final TextEditingController _deskripsiController = TextEditingController();

//   // File hodi rai foto ne'ebé hasai
//   File? _imageFile;

//   String _userId = "";
//   String _sessionToken = "";
//   String _sessionId = "";
//   bool _isLoading = false;

//   static const String _baseUrl = "http://172.20.222.144:3000";

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _userId = prefs.getString('user_id') ?? "";
//       _sessionToken = prefs.getString('session_token') ?? "";
//       _sessionId = prefs.getString('session_id') ?? "";
//     });
//     debugPrint(
//       "User ID: $_userId, Session: $_sessionId, Token: ${_sessionToken.isNotEmpty ? 'Present' : 'Missing'}",
//     );
//   }

//   // Funsaun hodi loke Kamera
//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     try {
//       // Loke Kamera (muda ba ImageSource.gallery se hakarak loke galeria)
//       final XFile? pickedFile = await picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 50, // Haktuik kualidade atu file labele boot liu
//       );

//       if (pickedFile != null) {
//         // Se hasai duni foto, rai ba variable _imageFile
//         setState(() {
//           _imageFile = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       print("Erru loke kamera: $e");
//     }
//   }

//   Future<String?> _sendProactive() async {
//     setState(() => _isLoading = true);

//     try {
//       final now = DateTime.now();
//       final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

//       final Map<String, dynamic> data = {
//         "description": _deskripsiController.text,
//         "posted_by": _userId,
//       };

//       var uri = Uri.parse("$_baseUrl/api/v1/proactive");
//       var request = http.MultipartRequest('POST', uri);

//       // Add Authorization header
//       if (_sessionToken.isNotEmpty) {
//         request.headers["Authorization"] = "Bearer $_sessionToken";
//       }

//       data.forEach((key, value) {
//         request.fields[key] = value.toString();
//       });

//       if (_imageFile != null) {
//         var stream = http.ByteStream(_imageFile!.openRead());
//         var length = await _imageFile!.length();
//         var multipartFile = http.MultipartFile(
//           'image_profs',
//           stream,
//           length,
//           filename: _imageFile!.path.split('/').last,
//         );
//         request.files.add(multipartFile);
//       }

//       var response = await request.send().timeout(const Duration(seconds: 30));
//       final responseBody = await response.stream.bytesToString();

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = jsonDecode(responseBody);
//         return responseData['message'] ?? "Proactive submete suksesu";
//       } else {
//         try {
//           final decoded = jsonDecode(responseBody);
//           return decoded['message'] ??
//               "Erro submete proactive: ${response.reasonPhrase}";
//         } catch (e) {
//           return "Erro submete proactive: ${response.statusCode}";
//         }
//       }
//     } catch (e) {
//       return "Erru koneksaun: $e";
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showLoadingDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const AlertDialog(
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(color: Colors.redAccent),
//             SizedBox(height: 20),
//             Text("Sending data to server..."),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSuccessDialog(String title, String msg) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.check_circle,
//                 color: Colors.green,
//                 size: 60,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 22,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               msg,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14, color: Colors.black54),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.pop(context); // Close dialog
//                   Navigator.pop(context); // Back to previous page
//                 },
//                 child: const Text(
//                   "OK",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.error_outline,
//                 color: Colors.red,
//                 size: 60,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Error",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 22,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14, color: Colors.black54),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.redAccent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   "OK",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "Formulario Proactive",
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.redAccent,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Deskrisaun Proactive",
//               style: TextStyle(fontSize: 14, color: Colors.black87),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _deskripsiController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: const BorderSide(color: Colors.grey),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 25),
//             const Text(
//               "Foto Attachment Proactive",
//               style: TextStyle(fontSize: 14, color: Colors.black87),
//             ),
//             const SizedBox(height: 12),

//             // KAISA FOTO (InkWell deteta klik)
//             InkWell(
//               onTap: _pickImage, // Loke funsaun kamera
//               child: Container(
//                 width: 180,
//                 height: 250,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: ClipRRect(
//                   // Clip atu imajen tuir kantu kaisa nian
//                   borderRadius: BorderRadius.circular(12),
//                   child: _imageFile != null
//                       // SE IHA FOTO: Hatudu foto ne'ebé hasai ona
//                       ? Image.file(
//                           _imageFile!,
//                           fit: BoxFit.cover, // Halo foto fit iha kaisa boot
//                         )
//                       // SE SEIDAUK IHA FOTO: Hatudu íkone "+" hanesan uluk
//                       : const Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.image, size: 80, color: Colors.grey),
//                             SizedBox(height: 10),
//                             Text(
//                               "Aumenta Foun\nFoto Attachment\nProactive",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 50),
//             // Butaun SIMPAN
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF8B0000), Color(0xFFFF0000)],
//                   ),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: ElevatedButton(
//                   onPressed: _isLoading
//                       ? null
//                       : () async {
//                           // Check se dadus kompletu
//                           if (_deskripsiController.text.isEmpty ||
//                               _imageFile == null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                   "Favor hatama deskrisaun no foto",
//                                 ),
//                                 backgroundColor: Colors.orange,
//                               ),
//                             );
//                             return;
//                           }

//                           _showLoadingDialog();
//                           final result = await _sendProactive();

//                           if (mounted) {
//                             Navigator.pop(context); // Close loading dialog
//                             if (result != null &&
//                                 (result.toLowerCase().contains("suksesu") ||
//                                     result.toLowerCase().contains("success"))) {
//                               _showSuccessDialog("Susesu", result);
//                             } else {
//                               _showErrorDialog(result ?? "Erru deskonhesidu");
//                             }
//                           }
//                         },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.transparent,
//                     shadowColor: Colors.transparent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                   ),
//                   child: const Text(
//                     "Submete Proactive",

//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
