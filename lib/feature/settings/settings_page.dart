import 'package:aegis_smart_medicine_reminder_system/core/theme/app_theme.dart';
import 'package:aegis_smart_medicine_reminder_system/feature/device/bluetooth_connections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _volume;
  late bool _isDarkMode;
  bool _phoneNotifications = true;
  bool _sleepMode = false;
  late bool _caregiverMode;
  late String _caregiverEmail;
  late String _caregiverCode;
  TimeOfDay? _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _afternoonTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay? _nightTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _volume = AppTheme.volume;
    _isDarkMode = AppTheme.isDarkMode;
    _caregiverMode = AppTheme.caregiverMode;
    _caregiverEmail = AppTheme.caregiverEmail;
    _caregiverCode = AppTheme.caregiverCode;
  }

  Future<void> _pickTime(ValueChanged<TimeOfDay> onPicked, TimeOfDay initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalize your experience',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'Profile',
                  child: _ProfileCard(user: user),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Appearance & Sound',
                  child: Column(
                    children: [
                      _settingRow(
                        icon: Icons.volume_up,
                        label: 'Volume',
                        trailing: Text(
                          '${(_volume * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Slider(
                        value: _volume,
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                          });
                          AppTheme.setVolume(value);
                        },
                        activeColor: AppTheme.buttonPrimary,
                      ),
                      const SizedBox(height: 8),
                      _settingRow(
                        icon: _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        label: 'Dark Mode',
                        trailing: Switch(
                          value: _isDarkMode,
                          onChanged: (value) {
                            setState(() {
                              _isDarkMode = value;
                            });
                            AppTheme.setDarkMode(value);
                          },
                          activeColor: AppTheme.buttonPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Alerts & Quiet Hours',
                  child: Column(
                    children: [
                      _settingRow(
                        icon: Icons.notifications,
                        label: 'Phone Notifications',
                        trailing: Switch(
                          value: _phoneNotifications,
                          onChanged: (value) {
                            setState(() {
                              _phoneNotifications = value;
                            });
                          },
                          activeColor: AppTheme.buttonPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _settingRow(
                        icon: Icons.bedtime,
                        label: 'Sleep Mode (10pm–6am)',
                        trailing: Switch(
                          value: _sleepMode,
                          onChanged: (value) {
                            setState(() {
                              _sleepMode = value;
                            });
                          },
                          activeColor: AppTheme.buttonPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Caregiver Mode',
                  child: Column(
                    children: [
                      _settingRow(
                        icon: Icons.people,
                        label: 'Enable Caregiver Mode',
                        trailing: Switch(
                          value: _caregiverMode,
                          onChanged: (value) {
                            setState(() {
                              _caregiverMode = value;
                            });
                            AppTheme.setCaregiverMode(value);
                          },
                          activeColor: AppTheme.buttonPrimary,
                        ),
                      ),
                      if (_caregiverMode) ...[
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Caregiver Email',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.buttonPrimary,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: AppTheme.textColor,
                          ),
                          onChanged: (value) {
                            _caregiverEmail = value;
                            AppTheme.setCaregiverEmail(value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Caregiver Code',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.buttonPrimary,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: AppTheme.textColor,
                          ),
                          onChanged: (value) {
                            _caregiverCode = value;
                            AppTheme.setCaregiverCode(value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Reminder Times',
                  child: Column(
                    children: [
                      _timeButton(
                        label: 'Morning',
                        time: _morningTime,
                        onTap: () {
                          _pickTime((picked) {
                            setState(() {
                              _morningTime = picked;
                            });
                          }, _morningTime ?? const TimeOfDay(hour: 8, minute: 0));
                        },
                      ),
                      const SizedBox(height: 10),
                      _timeButton(
                        label: 'Afternoon',
                        time: _afternoonTime,
                        onTap: () {
                          _pickTime((picked) {
                            setState(() {
                              _afternoonTime = picked;
                            });
                          }, _afternoonTime ?? const TimeOfDay(hour: 14, minute: 0));
                        },
                      ),
                      const SizedBox(height: 10),
                      _timeButton(
                        label: 'Night',
                        time: _nightTime,
                        onTap: () {
                          _pickTime((picked) {
                            setState(() {
                              _nightTime = picked;
                            });
                          }, _nightTime ?? const TimeOfDay(hour: 20, minute: 0));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Connectivity',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BluetoothConnectionPage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.buttonPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bluetooth,
                              color: AppTheme.buttonPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bluetooth Connection',
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.iconColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
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
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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

  Widget _settingRow({
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.buttonPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.buttonPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'CalSans',
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _timeButton({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.buttonPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.buttonPrimary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppTheme.buttonPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'CalSans',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            Text(
              time?.format(context) ?? '--:--',
              style: TextStyle(
                fontFamily: 'CalSans',
                fontWeight: FontWeight.w700,
                color: AppTheme.buttonPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Text(
        'No user signed in.',
        style: TextStyle(
          fontFamily: 'CalSans',
          color: AppTheme.textColor.withOpacity(0.7),
        ),
      );
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: docRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.buttonPrimary.withOpacity(0.12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.buttonPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.buttonPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final data = snapshot.data?.data();
        final name =
            (data?['name'] as String?)?.trim().isNotEmpty == true
                ? (data?['name'] as String).trim()
                : (user?.displayName?.trim().isNotEmpty == true
                    ? user!.displayName!.trim()
                    : 'User');
        final email =
            (data?['email'] as String?)?.trim().isNotEmpty == true
                ? (data?['email'] as String).trim()
                : (user?.email ?? 'No email');
        final createdAtRaw = data?['createdAt'];
        final createdAt = createdAtRaw is Timestamp
            ? createdAtRaw.toDate()
            : null;
        final createdAtLabel = createdAt != null
            ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
            : 'Not available';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.buttonPrimary.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontFamily: 'CalSans',
                      fontWeight: FontWeight.w700,
                      color: AppTheme.buttonPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'CalSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontFamily: 'CalSans',
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.iconColor.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Created: $createdAtLabel',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
