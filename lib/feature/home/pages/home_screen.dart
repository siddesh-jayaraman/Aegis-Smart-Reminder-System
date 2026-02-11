import 'package:aegis_smart_medicine_reminder_system/feature/device/model/device_model.dart';
import 'package:aegis_smart_medicine_reminder_system/feature/home/pages/box_schedule_screen.dart';
import 'package:aegis_smart_medicine_reminder_system/feature/settings/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'schedule_screen.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showSettingsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScheduleScreen()),
    );
  }

  void _navigateToDeviceSchedule(DeviceModel device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoxScheduleScreen(device: device),
      ),
    );
  }

  Future<String> _getNextDoseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSchedule = prefs.getStringList('med_schedule');
    final savedMedicineNames = prefs.getStringList('med_medicine_names');

    if (savedSchedule == null) return '';

    final now = DateTime.now();
    final today = now.weekday - 1; // Convert to 0-based index (Sunday = 0)
    final currentTime = TimeOfDay.fromDateTime(now);

    // Check today's remaining doses
    for (int row = 0; row < 3; row++) {
      final index = row * 7 + today;
      if (index < savedSchedule.length && savedSchedule[index] == 'true') {
        final timeSlot = ['Morning', 'Afternoon', 'Night'][row];
        TimeOfDay slotTime;

        switch (timeSlot) {
          case 'Morning':
            slotTime = const TimeOfDay(hour: 8, minute: 0);
            break;
          case 'Afternoon':
            slotTime = const TimeOfDay(hour: 14, minute: 0);
            break;
          case 'Night':
            slotTime = const TimeOfDay(hour: 20, minute: 0);
            break;
          default:
            slotTime = const TimeOfDay(hour: 8, minute: 0);
        }

        // Check if this time slot is in the future
        if (slotTime.hour > currentTime.hour ||
            (slotTime.hour == currentTime.hour &&
                slotTime.minute > currentTime.minute)) {
          final medicineName =
              savedMedicineNames != null && index < savedMedicineNames.length
              ? savedMedicineNames[index]
              : 'Medicine';
          return 'Next: $medicineName today at ${slotTime.format(context)} ($timeSlot)';
        }
      }
    }

    // Check tomorrow's first dose
    final tomorrow = (today + 1) % 7;
    for (int row = 0; row < 3; row++) {
      final index = row * 7 + tomorrow;
      if (index < savedSchedule.length && savedSchedule[index] == 'true') {
        final timeSlot = ['Morning', 'Afternoon', 'Night'][row];
        final medicineName =
            savedMedicineNames != null && index < savedMedicineNames.length
            ? savedMedicineNames[index]
            : 'Medicine';
        return 'Next: $medicineName tomorrow at 8:00 AM (Morning)';
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppTheme.isDarkMode;

    return Scaffold(
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header Section
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 50,
                    color: AppTheme.iconColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aegis',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Medicine Reminder',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.subtitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Devices Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.devices,
                            color: AppTheme.buttonPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your Devices',
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('devices')
                            .where(
                              "uid",
                              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                            )
                            .get(),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (asyncSnapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Error loading devices',
                                    style: TextStyle(
                                      fontFamily: 'CalSans',
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!asyncSnapshot.hasData ||
                              asyncSnapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.devices_other,
                                    color: AppTheme.iconColor.withOpacity(0.5),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No devices found. Add a device to get started.',
                                      style: TextStyle(
                                        fontFamily: 'CalSans',
                                        fontSize: 14,
                                        color: AppTheme.textColor.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: asyncSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var data = asyncSnapshot.data!.docs[index];
                              var device = DeviceModel.fromMap(
                                data.id,
                                data.data(),
                              );
                              return GestureDetector(
                                onTap: () => _navigateToDeviceSchedule(device),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.buttonPrimary.withOpacity(
                                      0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.buttonPrimary.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.buttonPrimary
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.medication,
                                          color: AppTheme.buttonPrimary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              device.name,
                                              style: TextStyle(
                                                fontFamily: 'CalSans',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tap to view schedule',
                                              style: TextStyle(
                                                fontFamily: 'CalSans',
                                                fontSize: 12,
                                                color: AppTheme.textColor
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppTheme.iconColor,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Main Content Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontFamily: 'CalSans',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What would you like to do today?',
                        style: TextStyle(
                          fontFamily: 'CalSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Next Dose Preview
                      FutureBuilder<String>(
                        future: _getNextDoseInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: AppTheme.buttonPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.buttonPrimary.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: AppTheme.buttonPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      snapshot.data!,
                                      style: TextStyle(
                                        fontFamily: 'CalSans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.buttonPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Main Buttons
                      _buildMainButton(
                        title: 'View Weekly Schedule',
                        icon: Icons.calendar_today,
                        onPressed: _navigateToSchedule,
                        backgroundColor: AppTheme.buttonSecondary,
                        textColor: AppTheme.buttonTextColor,
                        iconColor: AppTheme.iconColor,
                      ),
                      _buildMainButton(
                        title: 'Settings',
                        icon: Icons.settings,
                        onPressed: _showSettingsDialog,
                        backgroundColor: AppTheme.buttonSecondary,
                        textColor: AppTheme.buttonTextColor,
                        iconColor: AppTheme.iconColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: textColor ?? const Color(0xFF1565C0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: iconColor ?? const Color(0xFF1565C0)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'CalSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? const Color(0xFF1565C0),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: iconColor ?? const Color(0xFF1565C0),
            ),
          ],
        ),
      ),
    );
  }
}
