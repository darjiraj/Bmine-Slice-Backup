// To parse this JSON data, do
//
//     final loginResponseModel = loginResponseModelFromJson(jsonString);

import 'dart:convert';

LoginResponseModel loginResponseModelFromJson(String str) =>
    LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) =>
    json.encode(data.toJson());

class LoginResponseModel {
  bool? success;
  Data? data;
  String? message;

  LoginResponseModel({
    this.success,
    this.data,
    this.message,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        success: json["success"],
        data: json["response"] == null ? null : Data.fromJson(json["response"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "response": data!.toJson(),
        "message": message,
      };
}

class Data {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? username;
  String? gender;
  DateTime? dob;
  String? profileImage;
  String? socialId;
  String? socialType;
  String? firebaseId;
  String? fcmToken;
  DateTime? createdAt;
  dynamic updatedAt;
  dynamic deletedAt;

  Data({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.username,
    this.gender,
    this.dob,
    this.profileImage,
    this.socialId,
    this.socialType,
    this.firebaseId,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        password: json["password"],
        username: json["username"],
        gender: json["gender"],
        dob: json["dob"] == null ? json["dob"] : DateTime.parse(json["dob"]),
        profileImage: json["profile_image"],
        socialId: json["social_id"],
        socialType: json["social_type"],
        firebaseId: json["firebase_id"],
        fcmToken: json["fcm_token"],
        createdAt: json["created_at"] == null
            ? json["created_at"]
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"],
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "username": username,
        "gender": gender,
        "dob": dob == null ? "" : dob!.toIso8601String(),
        "profile_image": profileImage,
        "social_id": socialId,
        "social_type": socialType,
        "firebase_id": firebaseId,
        "fcm_token": fcmToken,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt,
        "deleted_at": deletedAt,
      };
}
