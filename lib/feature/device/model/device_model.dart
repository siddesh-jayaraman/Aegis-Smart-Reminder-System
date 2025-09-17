import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  final String id;
  final String name;
  final String uid;
  final Timestamp createdAt;
  DeviceModel({
    required this.id,
    required this.name,
    required this.uid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name, 'uid': uid, 'createdAt': createdAt};
  }

  factory DeviceModel.fromMap(String id, Map<String, dynamic> map) {
    return DeviceModel(
      id: id,
      name: map['name'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'],
    );
  }
}
