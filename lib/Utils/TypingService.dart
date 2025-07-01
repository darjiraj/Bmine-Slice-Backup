import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class TypingService {
  final String roomId;

  final String userId;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Timer? _typingTimer;

  TypingService({required this.roomId, required this.userId});

  void setTyping(bool isTyping) {
    
    _db.child('typingStatus/$roomId/$userId').set(isTyping);
  }

  void onTextChanged(String text) {
    print("onTextChanged");
    setTyping(true);

    _typingTimer?.cancel();

    _typingTimer = Timer(const Duration(seconds: 2), () {
      setTyping(false);
    });
  }

  void setupDisconnect() {
    _db.child('typingStatus/$roomId/$userId').onDisconnect().set(false);
  }

  void dispose() {
    _typingTimer?.cancel();

    setTyping(false);
  }
}
