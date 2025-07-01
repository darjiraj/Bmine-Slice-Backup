// To parse this JSON data, do
//
//     final notificationResponseModel = notificationResponseModelFromJson(jsonString);

import 'dart:convert';

NotificationResponseModel notificationResponseModelFromJson(String str) =>
    NotificationResponseModel.fromJson(json.decode(str));

String notificationResponseModelToJson(NotificationResponseModel data) =>
    json.encode(data.toJson());

class NotificationResponseModel {
  bool? success;
  List<NotificationDatum>? data;

  NotificationResponseModel({
    this.success,
    this.data,
  });

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) =>
      NotificationResponseModel(
        success: json["success"],
        data: json["data"] == null
            ? []
            : List<NotificationDatum>.from(
                json["data"].map((x) => NotificationDatum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class NotificationDatum {
  int? id;
  int? fromId;
  int? toId;
  String? message;
  String? type;
  int? isRead;
  int? isPush;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? firstname;
  String? lastname;
  String? firebase_id;
  int? userId;
  String? profileImg;

  NotificationDatum({
    this.id,
    this.fromId,
    this.toId,
    this.message,
    this.type,
    this.isRead,
    this.isPush,
    this.createdAt,
    this.updatedAt,
    this.firstname,
    this.lastname,
    this.firebase_id,
    this.userId,
    this.profileImg,
  });

  factory NotificationDatum.fromJson(Map<String, dynamic> json) =>
      NotificationDatum(
        id: json["id"],
        fromId: json["from_id"],
        toId: json["to_id"],
        message: json["message"],
        type: json["type"],
        isRead: json["is_read"],
        isPush: json["is_push"],
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : json["created_at"],
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : json["updated_at"],
        firstname: json["first_name"],
        lastname: json["last_name"],
        firebase_id: json["firebase_id"],
        userId: json["user_id"],
        profileImg: json["profile_img"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "from_id": fromId,
        "to_id": toId,
        "message": message,
        "type": type,
        "is_read": isRead,
        "is_push": isPush,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "first_name": firstname,
        "last_name": lastname,
        "firebase_id": firebase_id,
        "user_id": userId,
        "profile_img": profileImg,
      };
}
