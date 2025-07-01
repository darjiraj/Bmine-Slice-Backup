// To parse this JSON data, do
//
//     final liveEventResponseModel = liveEventResponseModelFromJson(jsonString);

import 'dart:convert';

LiveEventResponseModel liveEventResponseModelFromJson(String str) =>
    LiveEventResponseModel.fromJson(json.decode(str));

String liveEventResponseModelToJson(LiveEventResponseModel data) =>
    json.encode(data.toJson());

class LiveEventResponseModel {
  bool? success;
  List<LiveEventDatum>? data;

  LiveEventResponseModel({
    this.success,
    this.data,
  });

  factory LiveEventResponseModel.fromJson(Map<String, dynamic> json) =>
      LiveEventResponseModel(
        success: json["success"],
        data: json["data"] == null
            ? []
            : List<LiveEventDatum>.from(
                json["data"].map((x) => LiveEventDatum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class LiveEventDatum {
  int? id;
  String? eventName;
  DateTime? startTime;
  DateTime? endTime;
  DateTime? deadline;
  String? ageGroup;
  String? eventType;
  String? city;
  int? maxParticipant;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;
  int? maleCount;
  int? femaleCount;
  String? remaining;
  List<Participant>? participants;

  LiveEventDatum({
    this.id,
    this.eventName,
    this.startTime,
    this.endTime,
    this.deadline,
    this.ageGroup,
    this.eventType,
    this.city,
    this.maxParticipant,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.maleCount,
    this.femaleCount,
    this.remaining,
    this.participants,
  });

  factory LiveEventDatum.fromJson(Map<String, dynamic> json) => LiveEventDatum(
        id: json["id"] ?? 0,
        eventName: json["event_name"] ?? "",
        startTime: json["start_time"] != null
            ? DateTime.parse(json["start_time"])
            : json["start_time"],
        endTime: json["end_time"] != null
            ? DateTime.parse(json["end_time"])
            : json["end_time"],
        deadline: json["deadline"] != null
            ? DateTime.parse(json["deadline"])
            : json["deadline"],
        ageGroup: json["age_group"] ?? "",
        eventType: json["event_type"] ?? "",
        city: json["city"] ?? "",
        maxParticipant: json["max_participant"] ?? 0,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : json["created_at"],
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : json["updated_at"],
        deletedAt: json["deleted_at"],
        maleCount: json["male_count"] ?? 0,
        femaleCount: json["female_count"] ?? 0,
        remaining: json["remaining"] ?? "",
        participants: List<Participant>.from(
            json["participants"].map((x) => Participant.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "event_name": eventName,
        "start_time": startTime!.toIso8601String(),
        "end_time": endTime!.toIso8601String(),
        "deadline": deadline!.toIso8601String(),
        "age_group": ageGroup,
        "event_type": eventType,
        "city": city,
        "max_participant": maxParticipant,
        "created_at": createdAt == null ? "" : createdAt!.toIso8601String(),
        "updated_at": updatedAt == null ? "" : updatedAt!.toIso8601String(),
        "deleted_at": deletedAt,
        "male_count": maleCount,
        "female_count": femaleCount,
        "remaining": remaining,
        "participants":
            List<dynamic>.from(participants!.map((x) => x.toJson())),
      };
}

class Participant {
  int? id;
  int? eventId;
  int? userId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? firstName;
  String? lastName;
  DateTime? dob;
  String? profileImage;
  String? gender;
  Post? post;

  Participant({
    this.id,
    this.eventId,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.firstName,
    this.lastName,
    this.dob,
    this.profileImage,
    this.gender,
    this.post,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json["id"] ?? 0,
        eventId: json["event_id"] ?? 0,
        userId: json["user_id"] ?? 0,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : json["created_at"],
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : json["updated_at"],
        firstName: json["first_name"] ?? "",
        lastName: json["last_name"] ?? "",
        dob: json["dob"] != null ? DateTime.parse(json["dob"]) : json["dob"],
        profileImage: json["profile_image"] ?? "",
        gender: json["gender"] ?? "",
        post: json["post"] == null ? Post() : Post.fromJson(json["post"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "event_id": eventId,
        "user_id": userId,
        "created_at": createdAt == null ? "" : createdAt!.toIso8601String(),
        "updated_at": updatedAt == null ? "" : updatedAt!.toIso8601String(),
        "first_name": firstName,
        "last_name": lastName,
        "dob": dob == null ? "" : dob!.toIso8601String(),
        "profile_image": profileImage,
        "gender": gender,
        "post": post,
      };
}

class Post {
  int? id;
  int? userId;
  String? images;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;

  Post({
    this.id,
    this.userId,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json["id"],
        userId: json["user_id"],
        images: json["images"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "images": images,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
