import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../device/model/device_model.dart';
import 'dart:convert';

// Prescription Model
class Prescription {
  final String id;
  final String medicineName;
  final List<String> selectedDays;
  final String time;
  final int doseQuantity;
  final String additionalNotes;
  final String timeSlot; // Morning, Afternoon, Night
  final String uid;
  final String deviceId;

  Prescription({
    required this.id,
    required this.medicineName,
    required this.selectedDays,
    required this.time,
    required this.doseQuantity,
    required this.additionalNotes,
    required this.timeSlot,
    required this.uid,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'selectedDays': selectedDays,
      'time': time,
      'doseQuantity': doseQuantity,
      'additionalNotes': additionalNotes,
      'timeSlot': timeSlot,
      'uid': uid,
      'deviceId': deviceId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      medicineName: json['medicineName'],
      selectedDays: List<String>.from(json['selectedDays']),
      time: json['time'],
      doseQuantity: json['doseQuantity'],
      additionalNotes: json['additionalNotes'],
      timeSlot: json['timeSlot'],
      uid: json['uid'],
      deviceId: json['deviceId'],
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  final DeviceModel? device;
  const ScheduleScreen({super.key, this.device});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Prescription> prescriptions = [];
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  int _selectedTabIndex = 0;
  final List<String> timeSlots = ['Morning', 'Afternoon', 'Night'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    if (widget.device == null) return;

    try {
      print('Loading prescriptions for device: ${widget.device!.id}');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('deviceId', isEqualTo: widget.device!.id)
          .get();

      setState(() {
        prescriptions = querySnapshot.docs
            .map((doc) => Prescription.fromJson(doc.data()))
            .toList();
      });
      print('Loaded ${prescriptions.length} prescriptions');
      for (var prescription in prescriptions) {
        print(
          'Prescription: ${prescription.medicineName} - ${prescription.timeSlot} - ${prescription.selectedDays}',
        );
      }
    } catch (e) {
      print('Error loading prescriptions: $e');
    }
  }

  Future<void> _savePrescription(Prescription prescription) async {
    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(prescription.id)
          .set(prescription.toJson());
    } catch (e) {
      print('Error saving prescription: $e');
    }
  }

  Future<void> _deletePrescriptionFromFirebase(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting prescription: $e');
    }
  }

  List<Prescription> _getPrescriptionsForDate(DateTime date) {
    final dayName = _getDayName(date.weekday);
    return prescriptions.where((prescription) {
      return prescription.selectedDays.contains(dayName);
    }).toList();
  }

  List<Prescription> _getPrescriptionsForDateAndTimeSlot(
    DateTime date,
    String timeSlot,
  ) {
    final dayName = _getDayName(date.weekday);
    final filteredPrescriptions = prescriptions.where((prescription) {
      return prescription.selectedDays.contains(dayName) &&
          prescription.timeSlot == timeSlot;
    }).toList();

    print(
      'Filtering for $dayName, $timeSlot: Found ${filteredPrescriptions.length} prescriptions',
    );
    for (var prescription in filteredPrescriptions) {
      print('  - ${prescription.medicineName} at ${prescription.time}');
    }

    return filteredPrescriptions;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  void _showAddPrescriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddPrescriptionDialog(deviceId: widget.device?.id ?? '');
      },
    ).then((newPrescription) {
      if (newPrescription != null) {
        setState(() {
          prescriptions.add(newPrescription);
        });
        _savePrescription(newPrescription);
      }
    });
  }

  void _deletePrescription(String id) {
    setState(() {
      prescriptions.removeWhere((prescription) => prescription.id == id);
    });
    _deletePrescriptionFromFirebase(id);
  }

  void _onDaySelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _focusedDate = focusedDate;
    });
  }

  void _onPageChanged(DateTime focusedDate) {
    setState(() {
      _focusedDate = focusedDate;
    });
  }

  Widget _buildCalendar() {
    return Container(
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
      child: TableCalendar<Prescription>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDate,
        calendarFormat: CalendarFormat.week,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDate, day);
        },
        onDaySelected: _onDaySelected,
        onPageChanged: _onPageChanged,
        eventLoader: (date) => _getPrescriptionsForDate(date),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            fontFamily: 'CalSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
          defaultTextStyle: TextStyle(
            fontFamily: 'CalSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
          selectedTextStyle: const TextStyle(
            fontFamily: 'CalSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          todayTextStyle: TextStyle(
            fontFamily: 'CalSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.buttonPrimary,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTheme.buttonPrimary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.buttonPrimary, width: 2),
          ),
          markerDecoration: BoxDecoration(
            color: AppTheme.buttonPrimary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontFamily: 'CalSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppTheme.iconColor,
            size: 24,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppTheme.iconColor,
            size: 24,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontFamily: 'CalSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.iconColor,
          ),
          weekendStyle: TextStyle(
            fontFamily: 'CalSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateDetails() {
    if (_selectedDate == null) return const SizedBox.shrink();

    final dayName = _getDayName(_selectedDate!.weekday);
    final dateString =
        '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}';

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppTheme.buttonPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$dayName, $dateString',
                style: TextStyle(
                  fontFamily: 'CalSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tabs for time slots
          Container(
            decoration: BoxDecoration(
              color: AppTheme.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: timeSlots.asMap().entries.map((entry) {
                final index = entry.key;
                final timeSlot = entry.value;
                final isSelected = _selectedTabIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.buttonPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        timeSlot,
                        style: TextStyle(
                          fontFamily: 'CalSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Tab content
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final selectedTimeSlot = timeSlots[_selectedTabIndex];
    final prescriptionsForSlot = _getPrescriptionsForDateAndTimeSlot(
      _selectedDate!,
      selectedTimeSlot,
    );

    if (prescriptionsForSlot.isEmpty) {
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
              Icons.medication_outlined,
              color: AppTheme.iconColor.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'No medicine added for $selectedTimeSlot',
              style: TextStyle(
                fontFamily: 'CalSans',
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: prescriptionsForSlot
          .map(
            (prescription) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.buttonPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.buttonPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.medicineName,
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${prescription.time} - ${prescription.doseQuantity} dose${prescription.doseQuantity > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            fontSize: 14,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                        if (prescription.additionalNotes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            prescription.additionalNotes,
                            style: TextStyle(
                              fontFamily: 'CalSans',
                              fontSize: 12,
                              color: AppTheme.textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deletePrescription(prescription.id),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _getMonthName(int month) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
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
                            widget.device != null
                                ? '${widget.device!.name} Schedule'
                                : 'Medicine Schedule',
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
                            'Calendar view of your prescriptions',
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

              // Calendar
              Expanded(child: _buildCalendar()),

              // Selected date details
              if (_selectedDate != null) ...[
                const SizedBox(height: 16),
                _buildSelectedDateDetails(),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPrescriptionDialog,
        backgroundColor: AppTheme.buttonPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Prescription',
          style: TextStyle(fontFamily: 'CalSans', fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AddPrescriptionDialog extends StatefulWidget {
  final String deviceId;
  const AddPrescriptionDialog({super.key, required this.deviceId});

  @override
  State<AddPrescriptionDialog> createState() => _AddPrescriptionDialogState();
}

class _AddPrescriptionDialogState extends State<AddPrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedTimeSlot = 'Morning';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final List<String> _selectedDays = [];

  final List<String> timeSlots = ['Morning', 'Afternoon', 'Night'];
  final List<String> daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void dispose() {
    _medicineNameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _savePrescription() {
    if (_formKey.currentState!.validate() && _selectedDays.isNotEmpty) {
      final prescription = Prescription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineName: _medicineNameController.text.trim(),
        selectedDays: _selectedDays,
        time: _selectedTime.format(context),
        doseQuantity: int.parse(_doseController.text.trim()),
        additionalNotes: _notesController.text.trim(),
        timeSlot: _selectedTimeSlot,
        uid: FirebaseAuth.instance.currentUser!.uid,
        deviceId: widget.deviceId,
      );

      Navigator.of(context).pop(prescription);
    } else if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: AppTheme.buttonPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add New Prescription',
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Medicine Name
                TextFormField(
                  controller: _medicineNameController,
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
                    prefixIcon: Icon(
                      Icons.medication,
                      color: AppTheme.iconColor,
                    ),
                  ),
                  style: TextStyle(color: AppTheme.textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter medicine name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Time Slot
                Text(
                  'Time Slot',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: timeSlots
                      .map(
                        (slot) => Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTimeSlot = slot),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTimeSlot == slot
                                    ? AppTheme.buttonPrimary
                                    : AppTheme.isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedTimeSlot == slot
                                      ? AppTheme.buttonPrimary
                                      : AppTheme.isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: TextStyle(
                                  fontFamily: 'CalSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTimeSlot == slot
                                      ? Colors.white
                                      : AppTheme.textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 16),

                // Days Selection
                Text(
                  'Select Days',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: daysOfWeek
                      .map(
                        (day) => GestureDetector(
                          onTap: () => _toggleDay(day),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedDays.contains(day)
                                  ? AppTheme.buttonPrimary
                                  : AppTheme.isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedDays.contains(day)
                                    ? AppTheme.buttonPrimary
                                    : AppTheme.isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              day.substring(0, 3),
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedDays.contains(day)
                                    ? Colors.white
                                    : AppTheme.textColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 16),

                // Time and Dose Row
                Row(
                  children: [
                    // Time
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppTheme.iconColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  fontFamily: 'CalSans',
                                  fontSize: 16,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Dose Quantity
                    Expanded(
                      child: TextFormField(
                        controller: _doseController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Dose Quantity',
                          labelStyle: TextStyle(color: AppTheme.textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.buttonPrimary,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.numbers,
                            color: AppTheme.iconColor,
                          ),
                        ),
                        style: TextStyle(color: AppTheme.textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Additional Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    labelStyle: TextStyle(color: AppTheme.textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.buttonPrimary),
                    ),
                    prefixIcon: Icon(Icons.note, color: AppTheme.iconColor),
                  ),
                  style: TextStyle(color: AppTheme.textColor),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.buttonPrimary),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.buttonPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _savePrescription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.buttonPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'CalSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
