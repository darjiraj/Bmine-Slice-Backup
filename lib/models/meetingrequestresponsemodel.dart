// To parse this JSON data, do
//
//     final meetingRequestResponseModel = meetingRequestResponseModelFromJson(jsonString);

import 'dart:convert';

MeetingRequestResponseModel meetingRequestResponseModelFromJson(String str) =>
    MeetingRequestResponseModel.fromJson(json.decode(str));

String meetingRequestResponseModelToJson(MeetingRequestResponseModel data) =>
    json.encode(data.toJson());

class MeetingRequestResponseModel {
  bool? success;
  List<Meeting>? requestMeeting;
  List<Meeting>? scheduleMeeting;
  List<Meeting>? liveEventMeeting;

  MeetingRequestResponseModel({
    this.success,
    this.requestMeeting,
    this.scheduleMeeting,
    this.liveEventMeeting,
  });

  factory MeetingRequestResponseModel.fromJson(Map<String, dynamic> json) =>
      MeetingRequestResponseModel(
        success: json["success"],
        requestMeeting: json["request_meeting"] == null
            ? []
            : List<Meeting>.from(
                json["request_meeting"].map((x) => Meeting.fromJson(x))),
        scheduleMeeting: json["schedule_meeting"] == null
            ? []
            : List<Meeting>.from(
                json["schedule_meeting"].map((x) => Meeting.fromJson(x))),
        liveEventMeeting: json["live_event_meeting"] == null
            ? []
            : List<Meeting>.from(json["live_event_meeting"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "request_meeting":
            List<dynamic>.from(requestMeeting!.map((x) => x.toJson())),
        "schedule_meeting":
            List<dynamic>.from(scheduleMeeting!.map((x) => x.toJson())),
        "live_event_meeting":
            List<dynamic>.from(liveEventMeeting!.map((x) => x)),
      };
}

class Meeting {
  int? id;
  int? idFrom;
  int? idTo;
  int? userId;
  String? callId;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? scheduleAt;
  String? firstName;
  String? lastName;
  DateTime? dob;
  String? images;

  Meeting({
    this.id,
    this.idFrom,
    this.idTo,
    this.userId,
    this.callId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.scheduleAt,
    this.firstName,
    this.lastName,
    this.dob,
    this.images,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
        id: json["id"],
        idFrom: json["id_from"],
        idTo: json["id_to"],
        userId: json["user_id"],
        callId: json["call_id"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        scheduleAt: json["schedule_at"] != null
            ? DateTime.parse(json["schedule_at"])
            : json["schedule_at"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        dob: json["dob"] != null ? DateTime.parse(json["dob"]) : json["dob"],
        images: json["images"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "id_from": idFrom,
        "id_to": idTo,
        "user_id": userId,
        "call_id": callId,
        "status": status,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "schedule_at": scheduleAt == null ? "" : scheduleAt!.toIso8601String(),
        "first_name": firstName,
        "last_name": lastName,
        "dob": dob!.toIso8601String(),
        "images": images,
      };
}
