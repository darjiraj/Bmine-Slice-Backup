// To parse this JSON data, do
//
//     final meetingCallIdResponseModel = meetingCallIdResponseModelFromJson(jsonString);

import 'dart:convert';

MeetingCallIdResponseModel meetingCallIdResponseModelFromJson(String str) =>
    MeetingCallIdResponseModel.fromJson(json.decode(str));

String meetingCallIdResponseModelToJson(MeetingCallIdResponseModel data) =>
    json.encode(data.toJson());

class MeetingCallIdResponseModel {
  bool? success;
  RequestMeeting? requestMeeting;

  MeetingCallIdResponseModel({
    this.success,
    this.requestMeeting,
  });

  factory MeetingCallIdResponseModel.fromJson(Map<String, dynamic> json) =>
      MeetingCallIdResponseModel(
        success: json["success"],
        requestMeeting: json["request_meeting"] == null
            ? null
            : RequestMeeting.fromJson(json["request_meeting"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "request_meeting": requestMeeting!.toJson(),
      };
}

class RequestMeeting {
  int? id;
  int? idFrom;
  int? idTo;
  String? callId;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? scheduleAt;

  RequestMeeting({
    this.id,
    this.idFrom,
    this.idTo,
    this.callId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.scheduleAt,
  });

  factory RequestMeeting.fromJson(Map<String, dynamic> json) => RequestMeeting(
        id: json["id"],
        idFrom: json["id_from"],
        idTo: json["id_to"],
        callId: json["call_id"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        scheduleAt: DateTime.parse(json["schedule_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "id_from": idFrom,
        "id_to": idTo,
        "call_id": callId,
        "status": status,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "schedule_at": scheduleAt!.toIso8601String(),
      };
}
