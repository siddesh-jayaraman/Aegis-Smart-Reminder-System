import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // 3 rows (Morning, Afternoon, Night) x 7 columns (Sunday to Saturday)
  List<List<bool>> schedule = List.generate(3, (_) => List.filled(7, false));
  List<List<String>> medicineNames = List.generate(3, (_) => List.filled(7, ''));
  
  final List<String> timeSlots = ['Morning', 'Afternoon', 'Night'];
  final List<String> daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSchedule = prefs.getStringList('med_schedule');
    final savedMedicineNames = prefs.getStringList('med_medicine_names');
    
    if (savedSchedule != null) {
      // Convert saved strings back to 2D boolean list
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 7; col++) {
          final index = row * 7 + col;
          if (index < savedSchedule.length) {
            schedule[row][col] = savedSchedule[index] == 'true';
          }
        }
      }
    }
    
    if (savedMedicineNames != null) {
      // Convert saved strings back to 2D string list
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 7; col++) {
          final index = row * 7 + col;
          if (index < savedMedicineNames.length) {
            medicineNames[row][col] = savedMedicineNames[index];
          }
        }
      }
    }
    
    setState(() {}); // Update UI after loading
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Flatten the 2D boolean list into a list of strings
    List<String> flattenedSchedule = [];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 7; col++) {
        flattenedSchedule.add(schedule[row][col].toString());
      }
    }
    
    // Flatten the 2D string list into a list of strings
    List<String> flattenedMedicineNames = [];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 7; col++) {
        flattenedMedicineNames.add(medicineNames[row][col]);
      }
    }
    
    // Save to SharedPreferences
    await prefs.setStringList('med_schedule', flattenedSchedule);
    await prefs.setStringList('med_medicine_names', flattenedMedicineNames);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule saved!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleSchedule(int row, int col) {
    setState(() {
      schedule[row][col] = !schedule[row][col];
    });
  }

  void _editMedicineName(int row, int col) {
    final TextEditingController controller = TextEditingController(text: medicineNames[row][col]);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text(
            'Edit Medicine Name',
            style: TextStyle(
              fontFamily: 'CalSans',
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Medicine Name',
              labelStyle: TextStyle(color: AppTheme.textColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.buttonPrimary),
              ),
            ),
            style: TextStyle(color: AppTheme.textColor),
            maxLength: 15,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.buttonPrimary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  medicineNames[row][col] = controller.text.trim();
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCell(int row, int col) {
    final bool isSelected = schedule[row][col];
    final String medicineName = medicineNames[row][col];
    
    return GestureDetector(
      onTap: () => _toggleSchedule(row, col),
      onLongPress: () => _editMedicineName(row, col),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.buttonPrimary : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? AppTheme.buttonPrimary : AppTheme.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              if (medicineName.isNotEmpty)
                Text(
                  medicineName,
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (!isSelected && medicineName.isEmpty)
                Icon(
                  Icons.add,
                  color: AppTheme.iconColor,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isTimeSlot = false}) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'CalSans',
            fontSize: isTimeSlot ? 15 : 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.iconColor,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Schedule',
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set your medicine reminder times',
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Schedule Grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  padding: const EdgeInsets.all(20),
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
                      // Days of week header
                      Row(
                        children: [
                          // Empty corner cell
                          const SizedBox(width: 60),
                          ...daysOfWeek.map((day) => Expanded(
                            child: _buildHeaderCell(day),
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Schedule grid rows
                      ...List.generate(3, (row) => Column(
                        children: [
                          Row(
                            children: [
                              // Time slot label
                              SizedBox(
                                width: 90,
                                child: _buildHeaderCell(
                                  timeSlots[row],
                                  isTimeSlot: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Schedule cells
                              ...List.generate(7, (col) => Expanded(
                                child: _buildScheduleCell(row, col),
                              )),
                            ],
                          ),
                          if (row < 2) const SizedBox(height: 12),
                        ],
                      )),

                      const SizedBox(height: 32),

                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.isDarkMode ? const Color(0xFF1565C0).withOpacity(0.2) : const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF1565C0),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap to toggle, long press to edit medicine name. Selected slots will be highlighted.',
                                style: TextStyle(
                                  fontFamily: 'CalSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: Text(
                      'Save Schedule',
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 