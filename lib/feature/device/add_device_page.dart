import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aegis_smart_medicine_reminder_system/core/theme/app_theme.dart';

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
      appBar: AppBar(
        title: const Text('Add Device'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.buttonPrimary.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register New Device',
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _deviceNameController,
                      decoration: InputDecoration(
                        labelText: 'Device Name',
                        prefixIcon: const Icon(Icons.devices),
                        filled: true,
                        fillColor: AppTheme.isDarkMode
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter device name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deviceIdController,
                      decoration: InputDecoration(
                        labelText: 'Device ID',
                        prefixIcon: const Icon(Icons.qr_code_2),
                        filled: true,
                        fillColor: AppTheme.isDarkMode
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter device ID'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saveDevice,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Device',
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.buttonPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
