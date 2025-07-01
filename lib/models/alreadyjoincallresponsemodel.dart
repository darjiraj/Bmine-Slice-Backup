// To parse this JSON data, do
//
//     final alreadyJoinEventCallResponseModel = alreadyJoinEventCallResponseModelFromJson(jsonString);

import 'dart:convert';

AlreadyJoinEventCallResponseModel alreadyJoinEventCallResponseModelFromJson(
        String str) =>
    AlreadyJoinEventCallResponseModel.fromJson(json.decode(str));

String alreadyJoinEventCallResponseModelToJson(
        AlreadyJoinEventCallResponseModel data) =>
    json.encode(data.toJson());

class AlreadyJoinEventCallResponseModel {
  bool? success;
  String? message;
  Round? round;

  AlreadyJoinEventCallResponseModel({
    this.success,
    this.message,
    this.round,
  });

  factory AlreadyJoinEventCallResponseModel.fromJson(
          Map<String, dynamic> json) =>
      AlreadyJoinEventCallResponseModel(
        success: json["success"],
        message: json["message"],
        round: json["round"] == null ? null : Round.fromJson(json["round"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "round": round != null ? round!.toJson() : null,
      };
}

class Round {
  bool? exists;
  ReqData? reqData;

  Round({
    this.exists,
    this.reqData,
  });

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        exists: json["exists"],
        reqData:
            json["reqData"] == null ? null : ReqData.fromJson(json["reqData"]),
      );

  Map<String, dynamic> toJson() => {
        "exists": exists,
        "reqData": reqData!.toJson(),
      };
}

class ReqData {
  int? id;
  int? eventId;
  int? fromId;
  int? toId;
  String? callId;
  String? status;
  int? round;
  String? startTime;
  String? endTime;
  DateTime? createdAt;
  DateTime? updatedAt;

  ReqData({
    this.id,
    this.eventId,
    this.fromId,
    this.toId,
    this.callId,
    this.status,
    this.round,
    this.startTime,
    this.endTime,
    this.createdAt,
    this.updatedAt,
  });

  factory ReqData.fromJson(Map<String, dynamic> json) => ReqData(
        id: json["id"],
        eventId: json["event_id"],
        fromId: json["from_id"],
        toId: json["to_id"],
        callId: json["call_id"],
        status: json["status"],
        round: json["round"],
        startTime: json["start_time"],
        endTime: json["end_time"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "event_id": eventId,
        "from_id": fromId,
        "to_id": toId,
        "call_id": callId,
        "status": status,
        "round": round,
        "start_time": startTime,
        "end_time": endTime,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
      };
}
