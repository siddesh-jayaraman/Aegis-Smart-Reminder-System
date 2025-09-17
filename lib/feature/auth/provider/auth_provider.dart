import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool _loading = false;
  bool get loading => _loading;

  changeloading() {
    _loading = !_loading;
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    changeloading();
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print(e);
    } finally {
      changeloading();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> signUp(String name, String email, String password) async {
    changeloading();
    notifyListeners();
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set({'name': name, 'email': email, 'createdAt': Timestamp.now()});
      }
    } catch (e) {
      print(e);
    } finally {
      changeloading();
      notifyListeners();
    }
  }
}
