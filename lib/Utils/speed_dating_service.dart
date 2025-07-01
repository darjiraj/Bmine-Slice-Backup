import 'package:bmine_slice/models/eventdetailsresponsemodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SpeedDatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createCall(String eventId) async {
    final callDoc = await _firestore.collection('events').add({
      'createdAt': FieldValue.serverTimestamp(),
    });
    return callDoc.id;
  }

  Future<void> addIceCandidate(String callId, RTCIceCandidate candidate) async {
    try {
      await _firestore
          .collection('events')
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

  Future<DocumentSnapshot> getCallDocument(String callId) async {
    return await _firestore.collection('events').doc(callId).get();
  }

  Stream<DocumentSnapshot> getCallStream(String callId) {
    print(
        "_firestore.collection('events').doc(callId).snapshots() === ${_firestore.collection('events').doc(callId).snapshots()}");
    return _firestore.collection('events').doc(callId).snapshots();
  }

  Stream<QuerySnapshot> getIceCandidates(String callId) {
    return _firestore
        .collection('events')
        .doc(callId)
        .collection('candidates')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> createOffer(String callId, RTCSessionDescription offer) async {
    try {
      await _firestore.collection('events').doc(callId).set({
        'offer': offer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating offer: $e');
    }
  }

  Future<void> createAnswer(String callId, RTCSessionDescription answer) async {
    try {
      await _firestore.collection('events').doc(callId).set({
        'answer': answer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating answer: $e');
    }
  }

  Future<List<Map<String, dynamic>>> generateUniqueRoundRobinSchedule(
      List<Participants> participants,
      String eventId,
      String eventType,
      DateTime eventStartTime) async {
    List<Map<String, dynamic>> matches = [];
    int n = participants.length;

    try {
      if (participants.isEmpty) {
        print("Participants list is empty");
        return [];
      }

      if (n % 2 != 0) {
        participants.add(Participants(userId: null, gender: null));
        n++;
      }

      DateTime currentStartTime = eventStartTime;
      int currentRound = 1;

      for (int round = 0; round < n - 1; round++) {
        List<int> usedParticipants = [];
        bool matchCreatedInRound = false;

        for (int i = 0; i < n / 2; i++) {
          final first = participants[i];
          final second = participants[n - 1 - i];

          if (first.userId == null || second.userId == null) {
            print(
                "Skipping pair due to null userId: ${first.userId}, ${second.userId}");
            continue;
          }
          if (usedParticipants.contains(first.userId) ||
              usedParticipants.contains(second.userId)) {
            print(
                "Skipping pair due to already used participants: ${first.userId}, ${second.userId}");
            continue;
          }

          // Check event type and apply specific pairing logic
          if (eventType == "Trans Men & Woman" ||
              eventType == "Straight Men & Woman") {
            if (first.gender == second.gender) {
              print("Skipping pair due to same gender in $eventType event.");
              continue;
            }
          } else if (eventType == "Gay & Lesbian") {
            if (first.gender != second.gender) {
              print(
                  "Skipping pair due to different gender in $eventType event.");
              continue;
            }
          }

          String callId = "";
          try {
            callId = await createCall(eventId);
          } catch (e) {
            print("Failed to create call ID: $e");
          }
          if (callId.isEmpty) {
            print("Skipping match because call ID is empty");
            continue;
          }

          DateTime matchEndTime = currentStartTime.add(Duration(minutes: 5));

          matches.add({
            'event_id': eventId,
            'from_id': first.userId!,
            'to_id': second.userId!,
            'call_id': callId,
            'status': 'pending',
            'round': currentRound,
            'start_time': currentStartTime.toIso8601String(),
            'end_time': matchEndTime.toIso8601String(),
          });

          print("Match created: ${matches.last}");

          matchCreatedInRound = true;
          usedParticipants.add(first.userId!);
          usedParticipants.add(second.userId!);
        }

        if (matchCreatedInRound) {
          currentRound++;
          currentStartTime = currentStartTime.add(Duration(minutes: 5));
        }

        // Rotate participants for the next round
        final last = participants.removeAt(n - 1);
        participants.insert(1, last);
      }

      print("Final matches: $matches");
      return matches;
    } catch (e) {
      print("Error in generateUniqueRoundRobinSchedule: $e");
      return [];
    }
  }

  Future<String> getServerTime() async {
    final docRef =
        FirebaseFirestore.instance.collection('serverTime').doc('timeDoc');
    await docRef.set(
        {'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    final snapshot = await docRef.get();
    Timestamp serverTimestamp = snapshot['timestamp'] as Timestamp;
    return serverTimestamp.toDate().toIso8601String();
  }

  Future<void> endCall(String callId) async {
    try {
      await _firestore.collection('events').doc(callId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
      final iceCandidatesCollection = _firestore
          .collection('events')
          .doc(callId)
          .collection('iceCandidates');
      final iceCandidatesSnapshot = await iceCandidatesCollection.get();
      for (var doc in iceCandidatesSnapshot.docs) {
        await doc.reference.delete();
      }

      print("Call with ID $callId ended successfully.");
    } catch (e) {
      print("Error ending call: $e");
      throw Exception("Failed to end call.");
    }
  }
}
