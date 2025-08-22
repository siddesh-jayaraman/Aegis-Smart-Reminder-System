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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        double tempVolume = AppTheme.volume;
        bool tempDarkMode = AppTheme.isDarkMode;
        bool tempPhoneNotifications = true; // Default to enabled
        bool tempSleepMode = false; // Default to disabled
        bool tempCaregiverMode = AppTheme.caregiverMode;
        String tempCaregiverEmail = AppTheme.caregiverEmail;
        String tempCaregiverCode = AppTheme.caregiverCode;
        TimeOfDay? morningTime = const TimeOfDay(hour: 8, minute: 0);
        TimeOfDay? afternoonTime = const TimeOfDay(hour: 14, minute: 0);
        TimeOfDay? nightTime = const TimeOfDay(hour: 20, minute: 0);
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: tempDarkMode ? const Color(0xFF23272F) : null,
              title: const Text('Settings'),
              titleTextStyle: TextStyle(
                fontFamily: 'CalSans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tempDarkMode ? Colors.white : Colors.black,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volume Slider
                    Row(
                      children: [
                        Icon(Icons.volume_up, color: tempDarkMode ? Colors.white : Colors.black),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: tempVolume,
                            onChanged: (value) {
                              setStateDialog(() {
                                tempVolume = value;
                              });
                              setState(() {
                                AppTheme.setVolume(value);
                              });
                            },
                            activeColor: const Color(0xFF1565C0),
                          ),
                        ),
                        Text(
                          '${(tempVolume * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            color: tempDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Dark Mode Toggle
                    Row(
                      children: [
                        Icon(Icons.dark_mode, color: tempDarkMode ? Colors.white : Colors.black),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              color: tempDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: tempDarkMode,
                          onChanged: (value) {
                            setStateDialog(() {
                              tempDarkMode = value;
                            });
                            setState(() {
                              AppTheme.setDarkMode(value);
                            });
                          },
                          activeColor: const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Notifications Toggle
                    Row(
                      children: [
                        Icon(Icons.notifications, color: tempDarkMode ? Colors.white : Colors.black),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Enable Phone Notifications',
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              color: tempDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: tempPhoneNotifications,
                          onChanged: (value) {
                            setStateDialog(() {
                              tempPhoneNotifications = value;
                            });
                          },
                          activeColor: const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                                          // Sleep Mode Toggle
                      Row(
                        children: [
                          Icon(Icons.bedtime, color: tempDarkMode ? Colors.white : Colors.black),
                          const SizedBox(width: 16),
                          Expanded(
                                                      child: Text(
                            'Sleep Mode (No Alerts 10pm–6am)',
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              color: tempDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ),
                          Switch(
                            value: tempSleepMode,
                            onChanged: (value) {
                              setStateDialog(() {
                                tempSleepMode = value;
                              });
                            },
                            activeColor: const Color(0xFF1565C0),
                          ),
                        ],
                      ),


                      // Caregiver Mode Toggle
                      Row(
                        children: [
                          Icon(Icons.people, color: tempDarkMode ? Colors.white : Colors.black),
                          const SizedBox(width: 16),
                          Expanded(
                                                      child: Text(
                            'Caregiver Mode',
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              color: tempDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ),
                          Switch(
                            value: tempCaregiverMode,
                            onChanged: (value) {
                              setStateDialog(() {
                                tempCaregiverMode = value;
                              });
                              setState(() {
                                AppTheme.setCaregiverMode(value);
                              });
                            },
                            activeColor: const Color(0xFF1565C0),
                          ),
                        ],
                      ),
                      if (tempCaregiverMode) ...[
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Caregiver Email',
                            labelStyle: TextStyle(color: tempDarkMode ? Colors.white70 : Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1565C0)),
                            ),
                          ),
                          style: TextStyle(color: tempDarkMode ? Colors.white : Colors.black),
                          onChanged: (value) {
                            tempCaregiverEmail = value;
                            setState(() {
                              AppTheme.setCaregiverEmail(value);
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Caregiver Code',
                            labelStyle: TextStyle(color: tempDarkMode ? Colors.white70 : Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1565C0)),
                            ),
                          ),
                          style: TextStyle(color: tempDarkMode ? Colors.white : Colors.black),
                          onChanged: (value) {
                            tempCaregiverCode = value;
                            setState(() {
                              AppTheme.setCaregiverCode(value);
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                    
                    // Time Picker Buttons
                    Text(
                      'Reminder Times',
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        color: tempDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: morningTime ?? const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  morningTime = picked;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Morning\n${morningTime?.format(context) ?? "8:00 AM"}',
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: afternoonTime ?? const TimeOfDay(hour: 14, minute: 0),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  afternoonTime = picked;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Afternoon\n${afternoonTime?.format(context) ?? "2:00 PM"}',
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: nightTime ?? const TimeOfDay(hour: 20, minute: 0),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  nightTime = picked;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Night\n${nightTime?.format(context) ?? "8:00 PM"}',
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                  style: TextButton.styleFrom(
                    foregroundColor: tempDarkMode ? Colors.white : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduleScreen(),
      ),
    );
  }

  void _syncDevice() {
    // TODO: Implement actual device sync
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device synced successfully!'),
        backgroundColor: Colors.green,
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
            (slotTime.hour == currentTime.hour && slotTime.minute > currentTime.minute)) {
          final medicineName = savedMedicineNames != null && index < savedMedicineNames.length 
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
        final medicineName = savedMedicineNames != null && index < savedMedicineNames.length 
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
                          color: isDark ? Colors.white60 : const Color(0xFF666666),
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
                                  color: AppTheme.buttonPrimary.withOpacity(0.3),
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
                        title: 'Sync with Device',
                        icon: Icons.sync,
                        onPressed: _syncDevice,
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
            Icon(
              icon,
              size: 28,
              color: iconColor ?? const Color(0xFF1565C0),
            ),
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
            Icon(Icons.arrow_forward_ios, size: 16, color: iconColor ?? const Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }
} 