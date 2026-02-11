import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:aegis_smart_medicine_reminder_system/core/theme/app_theme.dart';

enum BluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

enum WiFiSetupState { idle, sending, success, failed }

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({super.key});

  @override
  State<BluetoothConnectionPage> createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  // Controllers
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  WiFiSetupState _wifiSetupState = WiFiSetupState.idle;
  bool _passwordVisible = false;
  String _statusMessage = '';
  String _imuData = "No Data";

  // Bluetooth variables
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _readCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  // Constants
  static const String targetDeviceName = "ESP32_WIFI_SETUP";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String writeCharacteristicUuid =
      "d61b2e19-2346-4a9e-9fb4-d87432c2d89b";

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _disconnectDevice();
    super.dispose();
  }

  // Bluetooth initialization and management
  Future<void> _initializeBluetooth() async {
    try {
      log('Initializing Bluetooth...');
      await _setupBluetooth();
    } catch (e) {
      _updateConnectionState(
        BluetoothConnectionState.error,
        'Failed to initialize Bluetooth: $e',
      );
    }
  }

  Future<void> _setupBluetooth() async {
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        log('Bluetooth adapter is on');
      } else {
        _updateConnectionState(
          BluetoothConnectionState.error,
          'Bluetooth is not enabled',
        );
      }
    });
  }

  Future<void> _startScanning() async {
    if (_connectionState == BluetoothConnectionState.scanning ||
        _connectionState == BluetoothConnectionState.connected) {
      return;
    }

    _updateConnectionState(
      BluetoothConnectionState.scanning,
      'Scanning for devices...',
    );

    try {
      FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          log('Found device: ${result.device.advName}');
          if (result.device.advName == targetDeviceName) {
            await FlutterBluePlus.stopScan();
            await _connectToDevice(result.device);
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Handle scan timeout
      Future.delayed(const Duration(seconds: 10), () {
        if (_connectionState == BluetoothConnectionState.scanning) {
          _updateConnectionState(
            BluetoothConnectionState.disconnected,
            'Device "$targetDeviceName" not found',
          );
        }
      });
    } catch (e) {
      _updateConnectionState(BluetoothConnectionState.error, 'Scan failed: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _updateConnectionState(
        BluetoothConnectionState.connecting,
        'Connecting to device...',
      );

      setState(() {
        _connectedDevice = device;
      });

      await device.connect(license: License.free);
      await _discoverServices(device);

      _updateConnectionState(
        BluetoothConnectionState.connected,
        'Connected successfully',
      );
    } catch (e) {
      _updateConnectionState(
        BluetoothConnectionState.error,
        'Connection failed: $e',
      );
      _connectedDevice = null;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      for (final service in services) {
        if (service.uuid.toString() == serviceUuid) {
          await _setupCharacteristics(service);
          break;
        }
      }
    } catch (e) {
      throw Exception('Service discovery failed: $e');
    }
  }

  Future<void> _setupCharacteristics(BluetoothService service) async {
    for (final characteristic in service.characteristics) {
      // Setup read characteristic (for IMU data)
      if (characteristic.properties.notify || characteristic.properties.read) {
        _readCharacteristic = characteristic;
        await characteristic.setNotifyValue(true);

        characteristic.lastValueStream.listen((value) {
          _handleIncomingData(value, characteristic.uuid.toString());
        });

        log('Setup read characteristic: ${characteristic.uuid}');
      }

      // Setup write characteristic (for WiFi credentials)
      if (characteristic.uuid.toString() == writeCharacteristicUuid &&
          characteristic.properties.write) {
        _writeCharacteristic = characteristic;
        log('Setup write characteristic: ${characteristic.uuid}');
      }
    }

    if (_writeCharacteristic == null) {
      throw Exception('Write characteristic not found');
    }
  }

  String deviceId = "";
  void _handleIncomingData(List<int> value, String characteristicId) {
    final data = String.fromCharCodes(value);
    setState(() {
      if (data.startsWith("ESP")) deviceId = data;
      _imuData = "Data from $characteristicId: $data";
    });
    log('Received data: $data');
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        log('Error disconnecting: $e');
      }
    }
    // if (mounted) {
    //   setState(() {
    //     _connectedDevice = null;
    //     _readCharacteristic = null;
    //     _writeCharacteristic = null;
    //     _connectionState = BluetoothConnectionState.disconnected;
    //     _statusMessage = '';
    //   });
    // }
  }

  // WiFi credentials management
  Future<void> _sendWiFiCredentials() async {
    if (_writeCharacteristic == null) {
      _updateWiFiSetupState(
        WiFiSetupState.failed,
        'No write characteristic available',
      );
      return;
    }

    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      _showErrorDialog('Please enter a valid SSID');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Please enter a valid password');
      return;
    }

    _updateWiFiSetupState(
      WiFiSetupState.sending,
      'Sending WiFi credentials...',
    );

    try {
      final credentials = '$ssid,$password';
      await _writeCharacteristic!.write(credentials.codeUnits);

      _updateWiFiSetupState(
        WiFiSetupState.success,
        'WiFi credentials sent successfully!',
      );

      // Clear form after successful send
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _clearForm();
        }
      });
    } catch (e) {
      _updateWiFiSetupState(
        WiFiSetupState.failed,
        'Failed to send credentials: $e',
      );
    }
  }

  void _clearForm() {
    setState(() {
      _ssidController.clear();
      _passwordController.clear();
      _wifiSetupState = WiFiSetupState.idle;
    });
  }

  // State management helpers
  void _updateConnectionState(BluetoothConnectionState state, String message) {
    setState(() {
      _connectionState = state;
      _statusMessage = message;
    });
  }

  void _updateWiFiSetupState(WiFiSetupState state, String message) {
    setState(() {
      _wifiSetupState = state;
      _statusMessage = message;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // UI Helper methods
  Color _getStatusColor() {
    switch (_connectionState) {
      case BluetoothConnectionState.connected:
        return Colors.green;
      case BluetoothConnectionState.error:
        return Colors.red;
      case BluetoothConnectionState.scanning:
      case BluetoothConnectionState.connecting:
        return Colors.orange;
      case BluetoothConnectionState.disconnected:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_connectionState) {
      case BluetoothConnectionState.connected:
        return Icons.bluetooth_connected;
      case BluetoothConnectionState.error:
        return Icons.bluetooth_disabled;
      case BluetoothConnectionState.scanning:
      case BluetoothConnectionState.connecting:
        return Icons.bluetooth_searching;
      case BluetoothConnectionState.disconnected:
        return Icons.bluetooth_disabled;
    }
  }

  String _getConnectionButtonText() {
    switch (_connectionState) {
      case BluetoothConnectionState.scanning:
        return 'Scanning...';
      case BluetoothConnectionState.connecting:
        return 'Connecting...';
      case BluetoothConnectionState.connected:
        return 'Disconnect';
      case BluetoothConnectionState.disconnected:
      case BluetoothConnectionState.error:
        return 'Connect to ESP32';
    }
  }

  bool _isFormEnabled() {
    return _connectionState == BluetoothConnectionState.connected &&
        _wifiSetupState != WiFiSetupState.sending;
  }

  bool _isSendButtonEnabled() {
    return _connectionState == BluetoothConnectionState.connected &&
        _wifiSetupState != WiFiSetupState.sending &&
        _ssidController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Setup'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connect your device and send WiFi credentials',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 18),
                _buildConnectionSection(),
                const SizedBox(height: 20),
                _buildWiFiCredentialsSection(),
                const SizedBox(height: 20),
                _buildDataSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    final statusColor = _getStatusColor();

    return _sectionCard(
      title: 'Bluetooth Connection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(), color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connectionState.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'CalSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (_statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            fontSize: 12,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _connectionState == BluetoothConnectionState.scanning ||
                          _connectionState ==
                              BluetoothConnectionState.connecting
                      ? null
                      : () {
                          if (_connectionState ==
                              BluetoothConnectionState.connected) {
                            _disconnectDevice();
                          } else {
                            _startScanning();
                          }
                        },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _connectionState == BluetoothConnectionState.connected
                        ? Colors.red.shade600
                        : AppTheme.buttonPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child:
                  (_connectionState == BluetoothConnectionState.scanning ||
                          _connectionState ==
                              BluetoothConnectionState.connecting)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getConnectionButtonText(),
                              style: const TextStyle(
                                fontFamily: 'CalSans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _getConnectionButtonText(),
                          style: const TextStyle(
                            fontFamily: 'CalSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWiFiCredentialsSection() {
    return _sectionCard(
      title: 'WiFi Credentials',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ssidController,
            enabled: _isFormEnabled(),
            decoration: InputDecoration(
              labelText: 'Network Name (SSID)',
              hintText: 'Enter WiFi network name',
              prefixIcon: const Icon(Icons.wifi),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor:
                  _isFormEnabled() ? null : Colors.grey.shade200.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            enabled: _isFormEnabled(),
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter WiFi password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: _isFormEnabled()
                    ? () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      }
                    : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor:
                  _isFormEnabled() ? null : Colors.grey.shade200.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSendButtonEnabled() ? _sendWiFiCredentials : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _wifiSetupState == WiFiSetupState.sending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Sending...'),
                      ],
                    )
                  : const Text(
                      'Send WiFi Credentials',
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          if (_wifiSetupState == WiFiSetupState.success) ...[
            const SizedBox(height: 12),
            _statusBanner(
              message: _statusMessage,
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ] else if (_wifiSetupState == WiFiSetupState.failed) ...[
            const SizedBox(height: 12),
            _statusBanner(
              message: _statusMessage,
              color: Colors.red,
              icon: Icons.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return _sectionCard(
      title: 'Device Data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.buttonPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.buttonPrimary.withOpacity(0.2),
              ),
            ),
            child: Text(
              deviceId.isEmpty ? 'No device ID received yet.' : deviceId,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () async {
              if (deviceId.isNotEmpty) {
                final res = await FirebaseFirestore.instance
                    .collection('devices')
                    .doc(deviceId)
                    .get();

                if (res.exists) {
                  await FirebaseFirestore.instance
                      .collection('devices')
                      .doc(deviceId)
                      .update({
                        "uid": FirebaseAuth.instance.currentUser!.uid,
                      });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No device fetched from the bluetooth'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No device fetched from the bluetooth'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add this device',
              style: TextStyle(
                fontFamily: 'CalSans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.buttonPrimary.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'CalSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statusBanner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'CalSans',
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
