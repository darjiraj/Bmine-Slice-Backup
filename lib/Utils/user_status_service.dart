import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UserStatusService with WidgetsBindingObserver {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;

  UserStatusService._internal();

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("users");
  Timer? _inactivityTimer;
  String? _userId;

  void init(String userId) {
    _userId = userId;
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline();
    _startInactivityTimer();
  }

  void _setUserOnline() {
    if (_userId == null) return;
    _databaseRef.child(_userId!).update({
      'status': 'online',
    });

    _databaseRef.child(_userId!).onDisconnect().update({
      'status': 'offline',
    });
  }

  void _setUserOffline() {
    if (_userId == null) return;
    _databaseRef.child(_userId!).update({
      'status': 'offline',
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _setUserOnline();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserOnline();
      _startInactivityTimer();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setUserOffline();
      _inactivityTimer?.cancel();
    }
  }

  void userActive() {
    _startInactivityTimer();
    _setUserOnline();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
  }
}
