// To parse this JSON data, do
//
//     final blockedUserResponseModel = blockedUserResponseModelFromJson(jsonString);

import 'dart:convert';

BlockedUsersResponseModel blockedUsersResponseModelFromJson(String str) =>
    BlockedUsersResponseModel.fromJson(json.decode(str));

String blockedsUserResponseModelToJson(BlockedUsersResponseModel data) =>
    json.encode(data.toJson());

class BlockedUsersResponseModel {
  bool success;
  List<BlockedUsersDatum> data;

  BlockedUsersResponseModel({
    required this.success,
    required this.data,
  });

  factory BlockedUsersResponseModel.fromJson(Map<String, dynamic> json) =>
      BlockedUsersResponseModel(
        success: json["success"],
        data: List<BlockedUsersDatum>.from(
            json["data"].map((x) => BlockedUsersDatum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class BlockedUsersDatum {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  dynamic username;
  String? phoneNumber;
  DateTime? dob;
  String? bio;
  String? language;
  dynamic profileImage;
  String? work;
  String? education;
  String? gender;
  dynamic location;
  String? latitude;
  String? longitude;
  String? hometown;
  String? height;
  String? exercise;
  String? educationLevel;
  String? smoking;
  String? drinking;
  String? ethnicity;
  String? horoscope;
  String? haveKid;
  String? relationship;
  String? lookingFor;
  String? intrested;
  String? status;
  dynamic verifyVideo;
  int? isVerify;
  String? socialId;
  String? socialType;
  String? userType;
  String? firebaseId;
  String? fcmToken;
  int? freeSwipe;
  int? paidSwipe;
  int? suspend;
  DateTime? lastGiftSent;
  DateTime? createdAt;
  DateTime? lastUsedAt;
  DateTime? lastSwipe;
  DateTime? lastVirtualMeeting;
  DateTime? updatedAt;
  dynamic deletedAt;

  BlockedUsersDatum({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.username,
    this.phoneNumber,
    this.dob,
    this.bio,
    this.language,
    this.profileImage,
    this.work,
    this.education,
    this.gender,
    this.location,
    this.latitude,
    this.longitude,
    this.hometown,
    this.height,
    this.exercise,
    this.educationLevel,
    this.smoking,
    this.drinking,
    this.ethnicity,
    this.horoscope,
    this.haveKid,
    this.relationship,
    this.lookingFor,
    this.intrested,
    this.status,
    this.verifyVideo,
    this.isVerify,
    this.socialId,
    this.socialType,
    this.userType,
    this.firebaseId,
    this.fcmToken,
    this.freeSwipe,
    this.paidSwipe,
    this.suspend,
    this.lastGiftSent,
    this.createdAt,
    this.lastUsedAt,
    this.lastSwipe,
    this.lastVirtualMeeting,
    this.updatedAt,
    this.deletedAt,
  });

  factory BlockedUsersDatum.fromJson(Map<String, dynamic> json) =>
      BlockedUsersDatum(
        id: json["id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        password: json["password"],
        username: json["username"],
        phoneNumber: json["phone_number"],
        dob: json["dob"] == null ? null : DateTime.parse(json["dob"]),
        bio: json["bio"],
        language: json["language"],
        profileImage: json["profile_image"],
        work: json["work"],
        education: json["education"],
        gender: json["gender"],
        location: json["location"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        hometown: json["hometown"],
        height: json["height"],
        exercise: json["exercise"],
        educationLevel: json["education_level"],
        smoking: json["smoking"],
        drinking: json["drinking"],
        ethnicity: json["ethnicity"],
        horoscope: json["horoscope"],
        haveKid: json["have_kid"],
        relationship: json["relationship"],
        lookingFor: json["looking_for"],
        intrested: json["intrested"],
        status: json["status"],
        verifyVideo: json["verify_video"],
        isVerify: json["is_verify"],
        socialId: json["social_id"],
        socialType: json["social_type"],
        userType: json["user_type"],
        firebaseId: json["firebase_id"],
        fcmToken: json["fcm_token"],
        freeSwipe: json["free_swipe"],
        paidSwipe: json["paid_swipe"],
        suspend: json["suspend"],
        lastGiftSent: json["last_gift_sent"] == null
            ? null
            : DateTime.parse(json["last_gift_sent"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        lastUsedAt: json["last_used_at"] == null
            ? null
            : DateTime.parse(json["last_used_at"]),
        lastSwipe: json["last_swipe"] == null
            ? null
            : DateTime.parse(json["last_swipe"]),
        lastVirtualMeeting: json["last_virtual_meeting"] == null
            ? null
            : DateTime.parse(json["last_virtual_meeting"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "username": username,
        "phone_number": phoneNumber,
        "dob": dob?.toIso8601String(),
        "bio": bio,
        "language": language,
        "profile_image": profileImage,
        "work": work,
        "education": education,
        "gender": gender,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "hometown": hometown,
        "height": height,
        "exercise": exercise,
        "education_level": educationLevel,
        "smoking": smoking,
        "drinking": drinking,
        "ethnicity": ethnicity,
        "horoscope": horoscope,
        "have_kid": haveKid,
        "relationship": relationship,
        "looking_for": lookingFor,
        "intrested": intrested,
        "status": status,
        "verify_video": verifyVideo,
        "is_verify": isVerify,
        "social_id": socialId,
        "social_type": socialType,
        "user_type": userType,
        "firebase_id": firebaseId,
        "fcm_token": fcmToken,
        "free_swipe": freeSwipe,
        "paid_swipe": paidSwipe,
        "suspend": suspend,
        "last_gift_sent": lastGiftSent?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
        "last_used_at": lastUsedAt?.toIso8601String(),
        "last_swipe": lastSwipe?.toIso8601String(),
        "last_virtual_meeting": lastVirtualMeeting?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
