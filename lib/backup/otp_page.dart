// // otp_page.dart
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'home_page.dart';

// class OTPPage extends StatefulWidget {
//   final String username;
//   const OTPPage({required this.username});

//   @override
//   // ignore: library_private_types_in_public_api
//   _OTPPageState createState() => _OTPPageState();
// }

// class _OTPPageState extends State<OTPPage> {
//   final TextEditingController otpCtrl = TextEditingController();
//   bool _isVerifying = false;

//   Future<void> verifyOTP() async {
//     setState(() {
//       _isVerifying = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse("http://172.20.222.97:3000/api/v1/auth/verify-otp"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"email": widget.username, "otp": otpCtrl.text}),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['status'] == "success") {
//         Navigator.pushAndRemoveUntil(
//           // ignore: use_build_context_synchronously

//           context,
//           MaterialPageRoute(builder: (context) => MainDashboardPage()),
//           (route) => false,
//         );
//       } else {
//         // ignore: use_build_context_synchronously
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(data['message'] ?? "OTP Sala"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       setState(() {
//         _isVerifying = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 221, 219, 215),
//       appBar: AppBar(
//         title: Text("Verifika OTP", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Center(
//         child: Padding(
//           padding: EdgeInsets.only(top: 200, left: 50, right: 50),
//           child: Column(
//             children: [
//               Text(
//                 "Hatama OTP ba user: ${widget.username}",
//                 style: TextStyle(fontSize: 20),
//               ),
//               TextField(
//                 controller: otpCtrl,
//                 keyboardType: TextInputType.number,
//                 textAlign: TextAlign.center,
//                 decoration: InputDecoration(
//                   hintText: "000000",
//                   hintStyle: TextStyle(fontSize: 20),
//                 ),
//               ),
//               SizedBox(height: 20),

//               _isVerifying
//                   ? CircularProgressIndicator(color: Colors.green)
//                   : ElevatedButton(
//                       onPressed: verifyOTP,
//                       child: Text("Verifika OTP"),
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
