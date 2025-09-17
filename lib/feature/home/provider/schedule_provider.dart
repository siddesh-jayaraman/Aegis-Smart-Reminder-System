import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class Prescription {
  final String id;
  final String medicineName;
  final List<String> selectedDays;
  final String time;
  final int doseQuantity;
  final String additionalNotes;
  final String timeSlot;
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

class MedicineTaken {
  final String id;
  final String prescriptionId;
  final String deviceId;
  final String uid;
  final String day;
  final String timeSlot;
  final DateTime takenAt;

  MedicineTaken({
    required this.id,
    required this.prescriptionId,
    required this.deviceId,
    required this.uid,
    required this.day,
    required this.timeSlot,
    required this.takenAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prescriptionId': prescriptionId,
      'deviceId': deviceId,
      'uid': uid,
      'day': day,
      'timeSlot': timeSlot,
      'takenAt': takenAt,
    };
  }

  factory MedicineTaken.fromJson(Map<String, dynamic> json) {
    return MedicineTaken(
      id: json['id'],
      prescriptionId: json['prescriptionId'],
      deviceId: json['deviceId'],
      uid: json['uid'],
      day: json['day'],
      timeSlot: json['timeSlot'],
      takenAt: (json['takenAt'] as Timestamp).toDate(),
    );
  }
}

class ScheduleProvider extends ChangeNotifier {
  List<Prescription> _prescriptions = [];
  List<MedicineTaken> _medicineTaken = [];
  bool _isLoading = false;
  String? _currentDeviceId;
  StreamSubscription? _hardwareSyncSubscription;

  List<Prescription> get prescriptions => _prescriptions;
  List<MedicineTaken> get medicineTaken => _medicineTaken;
  bool get isLoading => _isLoading;

  String getCurrentTimeSlot() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 12) {
      return 'Morning';
    } else if (hour < 16) {
      return 'Afternoon';
    } else {
      return 'Night';
    }
  }

  String getCurrentDay() {
    final now = DateTime.now();
    switch (now.weekday) {
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

  List<String> getDaysOfWeek() {
    final currentDay = getCurrentDay();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // Put current day first, then remaining days
    return [currentDay, ...days.where((day) => day != currentDay)];
  }

  Future<void> loadPrescriptions(String deviceId) async {
    if (deviceId.isEmpty) return;

    _currentDeviceId = deviceId;
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('deviceId', isEqualTo: deviceId)
          .get();

      _prescriptions = querySnapshot.docs
          .map((doc) => Prescription.fromJson(doc.data()))
          .toList();

      await _loadMedicineTaken(deviceId);
      _startHardwareSync(deviceId);
    } catch (e) {
      print('Error loading prescriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startHardwareSync(String deviceId) {
    _hardwareSyncSubscription?.cancel();

    // Listen for hardware-triggered medicine taken updates
    _hardwareSyncSubscription = FirebaseFirestore.instance
        .collection('medicine_taken')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('deviceId', isEqualTo: deviceId)
        .snapshots()
        .listen((snapshot) {
          _medicineTaken = snapshot.docs
              .map((doc) => MedicineTaken.fromJson(doc.data()))
              .toList();
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _hardwareSyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMedicineTaken(String deviceId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('medicine_taken')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('deviceId', isEqualTo: deviceId)
          .where('takenAt', isGreaterThanOrEqualTo: startOfDay)
          .where('takenAt', isLessThanOrEqualTo: endOfDay)
          .get();

      _medicineTaken = querySnapshot.docs
          .map((doc) => MedicineTaken.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error loading medicine taken: $e');
    }
  }

  Future<void> addPrescription(Prescription prescription) async {
    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(prescription.id)
          .set(prescription.toJson());

      _prescriptions.add(prescription);
      notifyListeners();
    } catch (e) {
      print('Error adding prescription: $e');
    }
  }

  Future<void> deletePrescription(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(id)
          .delete();

      _prescriptions.removeWhere((prescription) => prescription.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting prescription: $e');
    }
  }

  List<Prescription> getPrescriptionsForDayAndTimeSlot(
    String day,
    String timeSlot,
  ) {
    return _prescriptions.where((prescription) {
      return prescription.selectedDays.contains(day) &&
          prescription.timeSlot == timeSlot;
    }).toList();
  }

  Future<void> markMedicineTaken(String prescriptionId, String deviceId) async {
    final currentDay = getCurrentDay();
    final currentTimeSlot = getCurrentTimeSlot();

    // Check if already taken today
    final alreadyTaken = _medicineTaken.any(
      (taken) =>
          taken.prescriptionId == prescriptionId &&
          taken.day == currentDay &&
          taken.timeSlot == currentTimeSlot,
    );

    if (alreadyTaken) return;

    try {
      final medicineTaken = MedicineTaken(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prescriptionId: prescriptionId,
        deviceId: deviceId,
        uid: FirebaseAuth.instance.currentUser!.uid,
        day: currentDay,
        timeSlot: currentTimeSlot,
        takenAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('medicine_taken')
          .doc(medicineTaken.id)
          .set(medicineTaken.toJson());

      _medicineTaken.add(medicineTaken);
      notifyListeners();
    } catch (e) {
      print('Error marking medicine taken: $e');
    }
  }

  // Mark all medicines for a specific day and time slot (for hardware button press)
  Future<void> markAllMedicinesForTimeSlot(
    String day,
    String timeSlot,
    String deviceId,
  ) async {
    final medicines = getPrescriptionsForDayAndTimeSlot(day, timeSlot);

    for (final medicine in medicines) {
      // Check if already taken
      final alreadyTaken = _medicineTaken.any(
        (taken) =>
            taken.prescriptionId == medicine.id &&
            taken.day == day &&
            taken.timeSlot == timeSlot,
      );

      if (!alreadyTaken) {
        try {
          final medicineTaken = MedicineTaken(
            id: '${DateTime.now().millisecondsSinceEpoch}_${medicine.id}',
            prescriptionId: medicine.id,
            deviceId: deviceId,
            uid: FirebaseAuth.instance.currentUser!.uid,
            day: day,
            timeSlot: timeSlot,
            takenAt: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection('medicine_taken')
              .doc(medicineTaken.id)
              .set(medicineTaken.toJson());
        } catch (e) {
          print('Error marking medicine taken: $e');
        }
      }
    }

    // Reload medicine taken data
    await _loadMedicineTaken(deviceId);
  }

  // Get medicines for specific day and time slot
  List<Prescription> getMedicinesForDayAndTimeSlot(
    String day,
    String timeSlot,
  ) {
    return getPrescriptionsForDayAndTimeSlot(day, timeSlot);
  }

  bool isMedicineTaken(String prescriptionId, String day, String timeSlot) {
    return _medicineTaken.any(
      (taken) =>
          taken.prescriptionId == prescriptionId &&
          taken.day == day &&
          taken.timeSlot == timeSlot,
    );
  }

  // Simulate hardware button press (for testing)
  Future<void> simulateHardwareButtonPress(String timeSlot) async {
    if (_currentDeviceId == null) return;

    final currentDay = getCurrentDay();
    await markAllMedicinesForTimeSlot(currentDay, timeSlot, _currentDeviceId!);
  }

  // Get sync status
  bool get isHardwareSynced => _hardwareSyncSubscription != null;
}
