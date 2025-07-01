import 'dart:convert';

PendingCallResponseModel pendingCallResponseModelFromJson(String str) =>
    PendingCallResponseModel.fromJson(json.decode(str));

String pendingCallResponseModelToJson(PendingCallResponseModel data) =>
    json.encode(data.toJson());

class PendingCallResponseModel {
  bool? success;
  List<CallDatum>? pendingCalls;
  CallDatum? activeCall;

  PendingCallResponseModel({
    this.success,
    this.pendingCalls,
    this.activeCall,
  });

  factory PendingCallResponseModel.fromJson(Map<String, dynamic> json) =>
      PendingCallResponseModel(
        success: json["success"],
        pendingCalls: json["pending_calls"] == null
            ? []
            : List<CallDatum>.from(
                json["pending_calls"].map((x) => CallDatum.fromJson(x))),
        activeCall: json["active_call"] == null
            ? null
            : CallDatum.fromJson(json["active_call"]),
        // activeCall: json["active_call"] == null
        //     ? CallDatum()
        //     : List<CallDatum>.from(
        //         json["active_call"].map((x) => CallDatum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "pending_calls":
            List<dynamic>.from(pendingCalls!.map((x) => x.toJson())),
        "active_call": activeCall == null ? CallDatum() : activeCall!.toJson(),
        // "active_call": List<dynamic>.from(activeCall!.map((x) => x.toJson())),
      };
}

class CallDatum {
  int? id;
  int? eventId;
  int? fromId;
  int? toId;
  String? callId;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? round;
  String? startTime;
  String? endTime;
  String? firstName;
  String? lastName;
  DateTime? dob;
  String? images;

  CallDatum({
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
    this.firstName,
    this.lastName,
    this.dob,
    this.images,
  });

  factory CallDatum.fromJson(Map<String, dynamic> json) => CallDatum(
        id: json["id"],
        eventId: json["event_id"],
        fromId: json["from_id"],
        toId: json["to_id"],
        callId: json["call_id"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        round: json["round"],
        startTime: json["start_time"],
        endTime: json["end_time"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        dob: json["dob"] != null ? DateTime.parse(json["dob"]) : json["dob"],
        images: json["images"],
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
        "first_name": firstName,
        "last_name": lastName,
        "dob": dob!.toIso8601String(),
        "images": images,
      };
}
