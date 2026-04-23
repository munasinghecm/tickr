import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo_item.dart';

class TodoState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TodoItem> _items = [];
  StreamSubscription? _subscription;
  User? _currentUser;

  TodoState() {
    _initialize();
  }

  List<TodoItem> get todoItems => _items.where((item) => !item.isCompleted).toList();
  List<TodoItem> get doneItems => _items.where((item) => item.isCompleted).toList();
  User? get user => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  void _initialize() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      _subscription?.cancel();

      if (user != null) {
        // Listen to todos in Firestore for the logged-in user only (Private Tasks)
        _subscription = _firestore
            .collection('todos')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
          _items = snapshot.docs.map((doc) {
            return TodoItem.fromMap(doc.id, doc.data());
          }).toList();
          notifyListeners();
        });
      } else {
        _items = [];
        notifyListeners();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void addItem(String text) {
    if (text.trim().isEmpty) return;
    
    final newItem = TodoItem(
      id: '', // Firestore will generate the ID
      text: text,
      userId: _currentUser?.uid,
      createdAt: DateTime.now(),
    );

    _firestore.collection('todos').add(newItem.toMap());
  }

  void completeItem(String id) {
    _firestore.collection('todos').doc(id).update({'isCompleted': true});
  }

  void deleteItem(String id) {
    _firestore.collection('todos').doc(id).delete();
  }

  void clearDone() async {
    if (_currentUser == null) return;
    
    final batch = _firestore.batch();
    final doneSnapshots = await _firestore
        .collection('todos')
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('isCompleted', isEqualTo: true)
        .get();
        
    for (var doc in doneSnapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
