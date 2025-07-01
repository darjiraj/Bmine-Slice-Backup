// To parse this JSON data, do
//
//     final eventDetailsResponseModel = eventDetailsResponseModelFromJson(jsonString);

import 'dart:convert';

EventDetailsResponseModel eventDetailsResponseModelFromJson(String str) =>
    EventDetailsResponseModel.fromJson(json.decode(str));

String eventDetailsResponseModelToJson(EventDetailsResponseModel data) =>
    json.encode(data.toJson());

class EventDetailsResponseModel {
  bool? success;
  Data? data;

  EventDetailsResponseModel({
    this.success,
    this.data,
  });

  factory EventDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      EventDetailsResponseModel(
        success: json["success"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data!.toJson(),
      };
}

class Data {
  int? id;
  String? eventName;
  DateTime? startTime;
  DateTime? deadline;
  String? ageGroup;
  String? city;
  String? eventType;
  int? maxParticipant;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;
  String? remaining;
  List<Participants>? participants;

  Data({
    this.id,
    this.eventName,
    this.startTime,
    this.deadline,
    this.ageGroup,
    this.city,
    this.eventType,
    this.maxParticipant,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.remaining,
    this.participants,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        eventName: json["event_name"],
        startTime: json["start_time"] != null
            ? DateTime.parse(json["start_time"])
            : json["start_time"],
        deadline: json["deadline"] != null
            ? DateTime.parse(json["deadline"])
            : json["deadline"],
        ageGroup: json["age_group"],
        city: json["city"],
        eventType: json["event_type"],
        maxParticipant: json["max_participant"],
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : json["created_at"],
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : json["updated_at"],
        deletedAt: json["deleted_at"],
        remaining: json["remaining"],
        participants: json["participants"] == null
            ? []
            : List<Participants>.from(
                json["participants"].map((x) => Participants.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "event_name": eventName,
        "start_time": startTime?.toIso8601String(),
        "deadline": deadline?.toIso8601String(),
        "age_group": ageGroup,
        "city": city,
        "event_type": eventType,
        "max_participant": maxParticipant,
        "created_at": createdAt == null ? "" : createdAt!.toIso8601String(),
        "updated_at": updatedAt == null ? "" : updatedAt!.toIso8601String(),
        "deleted_at": deletedAt,
        "remaining": remaining,
        "participants":
            List<dynamic>.from(participants!.map((x) => x.toJson())),
      };
}

class Participants {
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
  Posts? post;

  Participants({
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

  factory Participants.fromJson(Map<String, dynamic> json) => Participants(
        id: json["id"],
        eventId: json["event_id"],
        userId: json["user_id"],
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : json["created_at"],
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : json["updated_at"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        dob: json["dob"] != null ? DateTime.parse(json["dob"]) : json["dob"],
        profileImage: json["profile_image"],
        gender: json["gender"],
        post: json["post"] == null ? Posts() : Posts.fromJson(json["post"]),
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
        "post": post == null ? Posts() : post!.toJson(),
      };
}

class Posts {
  int? id;
  int? userId;
  String? images;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;

  Posts({
    this.id,
    this.userId,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Posts.fromJson(Map<String, dynamic> json) => Posts(
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
        "images": images ?? "",
        "created_at": createdAt == null ? "" : createdAt!.toIso8601String(),
        "updated_at": updatedAt == null ? "" : updatedAt!.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
