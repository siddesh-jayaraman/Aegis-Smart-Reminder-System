import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _deviceIdController = TextEditingController();

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate()) {
      final name = _deviceNameController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device "$name" added successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await FirebaseFirestore.instance
          .collection('devices')
          .doc(_deviceIdController.text.trim())
          .update({
            "deviceName": _deviceNameController.text.trim(),
            "uid": FirebaseAuth.instance.currentUser!.uid,
          });
      _deviceNameController.clear();
      _deviceIdController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D9BE6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AutoStock',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Register New Device',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _deviceNameController,
                    decoration: InputDecoration(
                      labelText: 'Device Name',
                      prefixIcon: const Icon(Icons.devices),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter device name'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _deviceIdController,
                    decoration: InputDecoration(
                      labelText: 'Device ID',
                      prefixIcon: const Icon(Icons.qr_code_2),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter device ID'
                        : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveDevice,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Save Device',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D9BE6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
