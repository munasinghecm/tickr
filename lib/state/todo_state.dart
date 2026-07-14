import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/todo_item.dart';
import '../models/circle_model.dart';
import '../services/encryption_service.dart';

class TodoState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TodoItem> _items = [];
  List<Circle> _circles = [];
  Circle? _activeCircle;
  StreamSubscription? _todoSubscription;
  StreamSubscription? _circleSubscription;
  User? _currentUser;

  Uint8List? _encryptionKey;
  bool _needsPassphrase = false;

  TodoState() {
    _initialize();
  }

  List<TodoItem> get todoItems =>
      _items.where((item) => !item.isCompleted).toList();
  List<TodoItem> get doneItems =>
      _items.where((item) => item.isCompleted).toList();
  List<Circle> get circles => _circles;
  Circle? get activeCircle => _activeCircle;
  User? get user => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  
  bool get needsPassphrase => _needsPassphrase;
  Uint8List? get encryptionKey => _encryptionKey;

  void _initialize() {
    _auth.authStateChanges().listen((user) async {
      _currentUser = user;
      _todoSubscription?.cancel();
      _circleSubscription?.cancel();
      _encryptionKey = null;
      _needsPassphrase = false;

      if (user != null) {
        // Check for existing encryption key in secure storage
        final savedKey = await EncryptionService.getKey(user.uid);
        if (savedKey != null) {
          _encryptionKey = savedKey;
          _needsPassphrase = false;
        } else {
          _needsPassphrase = true;
        }

        // 1. Listen to Circles where user is a member
        _circleSubscription = _firestore
            .collection('circles')
            .where('members', arrayContains: user.uid)
            .snapshots()
            .listen((snapshot) {
              _circles = snapshot.docs
                  .map((doc) => Circle.fromMap(doc.id, doc.data()))
                  .toList();
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

  Future<void> initializeKeyWithPassphrase(String passphrase) async {
    if (_currentUser == null) return;
    
    // Derive key using passphrase and the user's unique UID as salt
    final key = EncryptionService.deriveKey(passphrase, _currentUser!.uid);
    await EncryptionService.saveKey(_currentUser!.uid, key);
    
    _encryptionKey = key;
    _needsPassphrase = false;
    notifyListeners();
    
    // Refresh subscription to decrypt items
    switchCircle(_activeCircle);
  }

  void switchCircle(Circle? circle) {
    _activeCircle = circle;
    _todoSubscription?.cancel();

    Query query = _firestore.collection('todos');

    if (circle == null) {
      query = query.where('userId', isEqualTo: _currentUser?.uid);
    } else {
      query = query.where('circleId', isEqualTo: circle.id);
    }

    _todoSubscription = query.snapshots().listen((snapshot) {
      _items =
          snapshot.docs
              .map(
                (doc) => TodoItem.fromMapDecrypted(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                  _encryptionKey,
                ),
              )
              .where((item) => circle == null ? item.circleId == null : true)
              .toList()
            ..sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            );
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
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '572991678414-s7h0am0nn8tadkqiaq71aiav33j0ehh3.apps.googleusercontent.com'
          : null,
      scopes: ['email', 'profile'],
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    }
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (_currentUser != null) {
      await EncryptionService.clearKey(_currentUser!.uid);
    }
    await _auth.signOut();
  }

  void addItem(String text) {
    if (text.trim().isEmpty) return;

    final newItem = TodoItem(
      id: '',
      text: text,
      userId: _currentUser?.uid,
      circleId: _activeCircle?.id,
      createdAt: DateTime.now(),
    );

    _firestore.collection('todos').add(newItem.toMapEncrypted(_encryptionKey));
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
    Query query = _firestore
        .collection('todos')
        .where('isCompleted', isEqualTo: true);

    if (_activeCircle == null) {
      query = query
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('circleId', isNull: true);
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
