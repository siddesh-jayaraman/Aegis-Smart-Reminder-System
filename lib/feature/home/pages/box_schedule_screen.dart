import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../device/model/device_model.dart';
import '../provider/schedule_provider.dart';

class BoxScheduleScreen extends StatefulWidget {
  final DeviceModel? device;
  const BoxScheduleScreen({super.key, this.device});

  @override
  State<BoxScheduleScreen> createState() => _BoxScheduleScreenState();
}

class _BoxScheduleScreenState extends State<BoxScheduleScreen> {
  final List<String> timeSlots = ['Morning', 'Afternoon', 'Night'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.device != null) {
        context.read<ScheduleProvider>().loadPrescriptions(widget.device!.id);
      }
    });
  }

  void _showAddMedicineDialog(String day, String timeSlot) {
    showDialog(
      context: context,
      builder: (context) => AddMedicineDialog(
        deviceId: widget.device?.id ?? '',
        preSelectedDay: day,
        preSelectedTimeSlot: timeSlot,
      ),
    );
  }

  Widget _buildDayCard(String day, bool isToday) {
    final provider = context.watch<ScheduleProvider>();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isToday ? 12 : 6),
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.buttonPrimary.withOpacity(0.15),
                  AppTheme.buttonPrimary.withOpacity(0.05),
                ],
              )
            : null,
        color: isToday ? null : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppTheme.buttonPrimary, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppTheme.buttonPrimary.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isToday ? 12 : 8,
            offset: Offset(0, isToday ? 6 : 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.buttonPrimary
                  : AppTheme.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                if (isToday) ...[
                  Icon(Icons.today, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  day,
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: isToday ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : AppTheme.textColor,
                  ),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Time Slots
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: timeSlots.map((timeSlot) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildTimeSlot(day, timeSlot, provider),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(
    String day,
    String timeSlot,
    ScheduleProvider provider,
  ) {
    final medicines = provider.getPrescriptionsForDayAndTimeSlot(day, timeSlot);
    final hasCurrentTimeSlot =
        provider.getCurrentDay() == day &&
        provider.getCurrentTimeSlot() == timeSlot;

    Color getTimeSlotColor() {
      switch (timeSlot) {
        case 'Morning':
          return const Color(0xFFFF8A65); // Warm orange
        case 'Afternoon':
          return const Color(0xFFFFB74D); // Warm amber
        case 'Night':
          return const Color(0xFF7986CB); // Soft indigo
        default:
          return AppTheme.buttonPrimary;
      }
    }

    IconData getTimeSlotIcon() {
      switch (timeSlot) {
        case 'Morning':
          return Icons.wb_sunny;
        case 'Afternoon':
          return Icons.wb_sunny_outlined;
        case 'Night':
          return Icons.nightlight_round;
        default:
          return Icons.access_time;
      }
    }

    String getTimeSlotLabel() {
      switch (timeSlot) {
        case 'Morning':
          return 'Morn';
        case 'Afternoon':
          return 'After';
        case 'Night':
          return 'Night';
        default:
          return timeSlot;
      }
    }

    return Column(
      children: [
        // Main time slot card
        GestureDetector(
          onTap: () => _showTimeSlotDetails(day, timeSlot, medicines),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: hasCurrentTimeSlot
                    ? [getTimeSlotColor(), getTimeSlotColor().withOpacity(0.8)]
                    : [
                        getTimeSlotColor().withOpacity(0.1),
                        getTimeSlotColor().withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: hasCurrentTimeSlot
                  ? Border.all(color: getTimeSlotColor(), width: 2)
                  : Border.all(color: getTimeSlotColor().withOpacity(0.2)),
              boxShadow: hasCurrentTimeSlot
                  ? [
                      BoxShadow(
                        color: getTimeSlotColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  getTimeSlotIcon(),
                  color: hasCurrentTimeSlot ? Colors.white : getTimeSlotColor(),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  getTimeSlotLabel(),
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasCurrentTimeSlot
                        ? Colors.white
                        : getTimeSlotColor(),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: hasCurrentTimeSlot
                        ? Colors.white.withOpacity(0.2)
                        : getTimeSlotColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${medicines.length}',
                    style: TextStyle(
                      fontFamily: 'CalSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasCurrentTimeSlot
                          ? Colors.white
                          : getTimeSlotColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Add button
        GestureDetector(
          onTap: () => _showAddMedicineDialog(day, timeSlot),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: getTimeSlotColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: getTimeSlotColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(Icons.add, color: getTimeSlotColor(), size: 16),
          ),
        ),

        // Mark taken button (only for current time slot)
        if (hasCurrentTimeSlot && medicines.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildMarkTakenButton(day, timeSlot, medicines, provider),
        ],
      ],
    );
  }

  Widget _buildMarkTakenButton(
    String day,
    String timeSlot,
    List<Prescription> medicines,
    ScheduleProvider provider,
  ) {
    final allTaken = medicines.every(
      (medicine) => provider.isMedicineTaken(medicine.id, day, timeSlot),
    );

    return GestureDetector(
      onTap: allTaken
          ? null
          : () => _markAllMedicinesTaken(medicines, provider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: allTaken
                ? [Colors.green.shade400, Colors.green.shade600]
                : [
                    AppTheme.buttonPrimary,
                    AppTheme.buttonPrimary.withOpacity(0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: (allTaken ? Colors.green : AppTheme.buttonPrimary)
                  .withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allTaken ? Icons.check_circle : Icons.medication_liquid,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              allTaken ? 'Taken' : 'Mark',
              style: const TextStyle(
                fontFamily: 'CalSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllMedicinesTaken(
    List<Prescription> medicines,
    ScheduleProvider provider,
  ) async {
    final currentDay = provider.getCurrentDay();
    final currentTimeSlot = provider.getCurrentTimeSlot();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await provider.markAllMedicinesForTimeSlot(
        currentDay,
        currentTimeSlot,
        widget.device!.id,
      );

      // Show success message
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked ${medicines.length} medicine${medicines.length > 1 ? 's' : ''} as taken',
              style: const TextStyle(fontFamily: 'CalSans'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error marking medicines: $e',
              style: const TextStyle(fontFamily: 'CalSans'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showTimeSlotDetails(
    String day,
    String timeSlot,
    List<Prescription> medicines,
  ) {
    final provider = context.read<ScheduleProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$day - $timeSlot',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                const Spacer(),
                // Hardware test button (only for current day/time)
                if (day == provider.getCurrentDay() &&
                    timeSlot == provider.getCurrentTimeSlot() &&
                    medicines.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () async {
                        await provider.simulateHardwareButtonPress(timeSlot);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Hardware button pressed for $timeSlot',
                              style: const TextStyle(fontFamily: 'CalSans'),
                            ),
                            backgroundColor: Colors.blue,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth, color: Colors.blue, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Test',
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => _showAddMedicineDialog(day, timeSlot),
                  icon: Icon(Icons.add, color: AppTheme.buttonPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (medicines.isEmpty)
              Text(
                'No medicines for this time slot',
                style: TextStyle(
                  fontFamily: 'CalSans',
                  fontSize: 14,
                  color: AppTheme.textColor.withOpacity(0.7),
                ),
              )
            else
              ...medicines.map((medicine) => _buildMedicineItem(medicine)),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineItem(Prescription medicine) {
    final provider = context.watch<ScheduleProvider>();
    final isTaken = provider.isMedicineTaken(
      medicine.id,
      provider.getCurrentDay(),
      provider.getCurrentTimeSlot(),
    );

    // Check if taken recently (within last 5 minutes) for hardware sync indicator
    final takenRecently = provider.medicineTaken.any(
      (taken) =>
          taken.prescriptionId == medicine.id &&
          taken.day == provider.getCurrentDay() &&
          taken.timeSlot == provider.getCurrentTimeSlot() &&
          DateTime.now().difference(taken.takenAt).inMinutes < 5,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTaken
            ? Colors.green.withOpacity(0.1)
            : AppTheme.buttonPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTaken
              ? Colors.green.withOpacity(0.3)
              : AppTheme.buttonPrimary.withOpacity(0.3),
        ),
        boxShadow: takenRecently
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Icon(
                isTaken ? Icons.check_circle : Icons.medication,
                color: isTaken ? Colors.green : AppTheme.buttonPrimary,
                size: 20,
              ),
              if (takenRecently)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      medicine.medicineName,
                      style: TextStyle(
                        fontFamily: 'CalSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    if (takenRecently) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bluetooth_connected,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Hardware',
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${medicine.time} - ${medicine.doseQuantity} dose${medicine.doseQuantity > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 12,
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              provider.deletePrescription(medicine.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final daysOfWeek = provider.getDaysOfWeek();
    final currentDay = provider.getCurrentDay();

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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.device?.name ?? 'Medicine Schedule',
                                style: const TextStyle(
                                  fontFamily: 'CalSans',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Weekly medicine schedule',
                                style: TextStyle(
                                  fontFamily: 'CalSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status indicators
                    Row(
                      children: [
                        // Current time indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current: ${provider.getCurrentTimeSlot()}',
                                style: const TextStyle(
                                  fontFamily: 'CalSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Hardware sync indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: provider.isHardwareSynced
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: provider.isHardwareSynced
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.orange.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.isHardwareSynced
                                    ? Icons.bluetooth_connected
                                    : Icons.bluetooth_disabled,
                                color: provider.isHardwareSynced
                                    ? Colors.green.shade300
                                    : Colors.orange.shade300,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.isHardwareSynced
                                    ? 'Hardware Sync'
                                    : 'No Sync',
                                style: TextStyle(
                                  fontFamily: 'CalSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: provider.isHardwareSynced
                                      ? Colors.green.shade300
                                      : Colors.orange.shade300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Days List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: daysOfWeek.length,
                        itemBuilder: (context, index) {
                          final day = daysOfWeek[index];
                          final isToday = day == currentDay;
                          return _buildDayCard(day, isToday);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddMedicineDialog(currentDay, provider.getCurrentTimeSlot()),
        backgroundColor: AppTheme.buttonPrimary,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Add Medicine',
          style: TextStyle(fontFamily: 'CalSans', fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AddMedicineDialog extends StatefulWidget {
  final String deviceId;
  final String preSelectedDay;
  final String preSelectedTimeSlot;

  const AddMedicineDialog({
    super.key,
    required this.deviceId,
    required this.preSelectedDay,
    required this.preSelectedTimeSlot,
  });

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedTimeSlot;
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
  void initState() {
    super.initState();
    _selectedTimeSlot = widget.preSelectedTimeSlot;
    _selectedDays.add(widget.preSelectedDay);

    switch (widget.preSelectedTimeSlot) {
      case 'Morning':
        _selectedTime = const TimeOfDay(hour: 8, minute: 0);
        break;
      case 'Afternoon':
        _selectedTime = const TimeOfDay(hour: 14, minute: 0);
        break;
      case 'Night':
        _selectedTime = const TimeOfDay(hour: 20, minute: 0);
        break;
    }
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveMedicine() {
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

      context.read<ScheduleProvider>().addPrescription(prescription);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Medicine for ${widget.preSelectedDay}',
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _medicineNameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _doseController,
                        decoration: InputDecoration(
                          labelText: 'Dose',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null)
                            setState(() => _selectedTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedTime.format(context),
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.buttonPrimary),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveMedicine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.buttonPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
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
