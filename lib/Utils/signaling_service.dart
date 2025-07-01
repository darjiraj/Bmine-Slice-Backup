import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createCall() async {
    final callDoc = await _firestore.collection('calls').add({
      'createdAt': FieldValue.serverTimestamp(),
    });
    return callDoc.id;
  }

  Future<void> deleteCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).delete();
      print('Call with ID $callId deleted successfully');
    } catch (e) {
      print('Error deleting call: $e');
    }
  }

  Future<void> createOffer(String callId, RTCSessionDescription offer) async {
    try {
      await _firestore.collection('calls').doc(callId).set({
        'offer': offer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating offer: $e');
    }
  }

  Future<DocumentSnapshot> getCallDocument(String callId) async {
    return await _firestore.collection('calls').doc(callId).get();
  }

  Future<void> createAnswer(String callId, RTCSessionDescription answer) async {
    try {
      await _firestore.collection('calls').doc(callId).set({
        'answer': answer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating answer: $e');
    }
  }

  Future<void> addIceCandidate(String callId, RTCIceCandidate candidate) async {
    try {
      await _firestore
          .collection('calls')
          .doc(callId)
          .collection('candidates')
          .add({
        'candidate': candidate.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  Stream<DocumentSnapshot> getCallStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots();
  }

  Stream<QuerySnapshot> getIceCandidates(String callId) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .collection('candidates')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> endCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).delete();
      await _firestore
          .collection('calls')
          .doc(callId)
          .collection('candidates')
          .get()
          .then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } catch (e) {
      print('Error ending call: $e');
    }
  }
  Future<String> getServerTime(String callId) async {
    final serverTimeRef =
        FirebaseFirestore.instance.collection('serverTime').doc('timeDoc');

    // Set server timestamp in the global serverTime document
    await serverTimeRef.set(
        {'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    // Fetch the server timestamp
    final snapshot = await serverTimeRef.get();
    Timestamp serverTimestamp = snapshot['timestamp'] as Timestamp;
    String serverTimeString = serverTimestamp.toDate().toIso8601String();

    // Store the same timestamp in the specific call document
    final callRef = FirebaseFirestore.instance.collection('calls').doc(callId);
    await callRef.set({'serverTime': serverTimestamp}, SetOptions(merge: true));

    return serverTimeString;
  }

}
