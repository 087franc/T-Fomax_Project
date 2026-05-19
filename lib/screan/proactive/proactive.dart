import 'package:flutter/material.dart';
import 'proactive_form.dart';
import 'proactive_list.dart';

class TambahProactivePage extends StatefulWidget {
  const TambahProactivePage({super.key});

  @override
  State<TambahProactivePage> createState() => _TambahProactivePageState();
}

class _TambahProactivePageState extends State<TambahProactivePage> {
  bool _showForm = false; // Toggle view
  Map<String, dynamic>? _editData;

  void _switchToForm({Map<String, dynamic>? data}) {
    setState(() {
      _showForm = true;
      _editData = data;
    });
  }

  void _switchToList() {
    setState(() {
      _showForm = false;
      _editData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Proactive", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSwitcher(),
          Expanded(
            child: _showForm
                ? ProactiveForm(
                    editData: _editData,
                    onSaved: _switchToList,
                  )
                : ProactiveList(
                    onEdit: (data) => _switchToForm(data: data),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _switchToList,
              child: Container(
                decoration: BoxDecoration(
                  gradient: !_showForm
                      ? const LinearGradient(
                          colors: [Color(0xFF8B0000), Color(0xFFFF0000)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Lista Proativu",
                  style: TextStyle(
                    color: !_showForm ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchToForm(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _showForm
                      ? const LinearGradient(
                          colors: [Color(0xFF8B0000), Color(0xFFFF0000)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Formuláriu",
                  style: TextStyle(
                    color: _showForm ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
