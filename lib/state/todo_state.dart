import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo_item.dart';
import '../models/circle_model.dart';

class TodoState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TodoItem> _items = [];
  List<Circle> _circles = [];
  Circle? _activeCircle;
  StreamSubscription? _todoSubscription;
  StreamSubscription? _circleSubscription;
  User? _currentUser;

  TodoState() {
    _initialize();
  }

  List<TodoItem> get todoItems => _items.where((item) => !item.isCompleted).toList();
  List<TodoItem> get doneItems => _items.where((item) => item.isCompleted).toList();
  List<Circle> get circles => _circles;
  Circle? get activeCircle => _activeCircle;
  User? get user => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  void _initialize() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      _todoSubscription?.cancel();
      _circleSubscription?.cancel();

      if (user != null) {
        // 1. Listen to Circles where user is a member
        _circleSubscription = _firestore
            .collection('circles')
            .where('members', arrayContains: user.uid)
            .snapshots()
            .listen((snapshot) {
          _circles = snapshot.docs.map((doc) => Circle.fromMap(doc.id, doc.data())).toList();
          notifyListeners();
        });

        // 2. Initial Todo Fetch (Private)
        switchCircle(null);
      } else {
        _items = [];
        _circles = [];
        _activeCircle = null;
        notifyListeners();
      }
    });
  }

  void switchCircle(Circle? circle) {
    _activeCircle = circle;
    _todoSubscription?.cancel();

    Query query = _firestore.collection('todos');

    if (circle == null) {
      // Private tasks: filter by userId only (no composite index needed)
      query = query.where('userId', isEqualTo: _currentUser?.uid);
    } else {
      // Circle tasks
      query = query.where('circleId', isEqualTo: circle.id);
    }

    _todoSubscription = query.snapshots().listen((snapshot) {
      _items = snapshot.docs
          .map((doc) => TodoItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((item) => circle == null ? item.circleId == null : true)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Client-side sort
      notifyListeners();
    });
  }

  Future<void> createCircle(String name) async {
    if (_currentUser == null) return;
    
    final inviteCode = _generateInviteCode();
    await _firestore.collection('circles').add({
      'name': name,
      'inviteCode': inviteCode,
      'adminId': _currentUser!.uid,
      'members': [_currentUser!.uid],
    });
  }

  Future<void> joinCircle(String inviteCode) async {
    if (_currentUser == null) return;

    final snapshot = await _firestore
        .collection('circles')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      await _firestore.collection('circles').doc(docId).update({
        'members': FieldValue.arrayUnion([_currentUser!.uid]),
      });
    } else {
      throw Exception('Circle not found with that code');
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ01234564789';
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
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
      circleId: _activeCircle?.id,
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
    Query query = _firestore.collection('todos').where('isCompleted', isEqualTo: true);

    if (_activeCircle == null) {
      query = query.where('userId', isEqualTo: _currentUser!.uid).where('circleId', isNull: true);
    } else {
      query = query.where('circleId', isEqualTo: _activeCircle!.id);
    }

    final doneSnapshots = await query.get();
        
    for (var doc in doneSnapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _todoSubscription?.cancel();
    _circleSubscription?.cancel();
    super.dispose();
  }
}
